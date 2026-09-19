#!/usr/bin/env python3
"""Safely link the configured dotfiles into a home directory."""

from __future__ import annotations

import argparse
import json
import os
import stat
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any

DEFAULT_MANIFEST = Path("profiles/sway/manifest.json")
BACKUP_PARENT = PurePosixPath(".local/state/sway/backups")


@dataclass(frozen=True)
class Link:
    source_relative: PurePosixPath
    destination_relative: PurePosixPath
    source: Path
    destination: Path


@dataclass
class Plan:
    links: list[Link]
    conflicts: list[Link]
    already_correct: int
    directories: set[Path]


class PreflightError(Exception):
    """The requested link operation is unsafe or invalid."""


def lexists(path: Path) -> bool:
    return os.path.lexists(path)


def is_within(path: Path, directory: Path) -> bool:
    try:
        path.relative_to(directory)
    except ValueError:
        return False
    return True


def parse_relative_path(value: Any, field: str) -> PurePosixPath:
    if not isinstance(value, str) or not value:
        raise PreflightError(f"{field} must be a non-empty string")
    if "\\" in value or "\0" in value:
        raise PreflightError(f"{field} is not a canonical POSIX path: {value!r}")
    raw_parts = value.split("/")
    path = PurePosixPath(value)
    if path.is_absolute() or any(part in {"", ".", ".."} for part in raw_parts):
        raise PreflightError(f"{field} must be a canonical relative path: {value!r}")
    if path.as_posix() != value:
        raise PreflightError(f"{field} must be a canonical relative path: {value!r}")
    return path


def load_manifest(manifest: Path, repo: Path, target_home: Path) -> list[Link]:
    try:
        raw = json.loads(manifest.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        raise PreflightError(f"cannot read manifest {manifest}: {error}") from error

    if not isinstance(raw, dict) or set(raw) != {"version", "links"}:
        raise PreflightError("manifest must contain exactly 'version' and 'links'")
    if type(raw["version"]) is not int or raw["version"] != 1:
        raise PreflightError(f"unsupported manifest version: {raw['version']!r}")
    if not isinstance(raw["links"], list):
        raise PreflightError("manifest 'links' must be a list")

    repo_resolved = repo.resolve(strict=True)
    links: list[Link] = []
    destinations: dict[PurePosixPath, int] = {}
    errors: list[str] = []
    for index, entry in enumerate(raw["links"], start=1):
        label = f"manifest link {index}"
        if not isinstance(entry, dict) or set(entry) != {"source", "destination"}:
            errors.append(f"{label} must contain exactly 'source' and 'destination'")
            continue
        try:
            source_relative = parse_relative_path(entry["source"], f"{label} source")
            destination_relative = parse_relative_path(
                entry["destination"], f"{label} destination"
            )
        except PreflightError as error:
            errors.append(str(error))
            continue

        if destination_relative in destinations:
            errors.append(
                f"duplicate destination in links {destinations[destination_relative]} "
                f"and {index}: {destination_relative}"
            )
            continue
        destinations[destination_relative] = index

        source = repo.joinpath(*source_relative.parts)
        try:
            source_resolved = source.resolve(strict=True)
        except (OSError, RuntimeError) as error:
            errors.append(
                f"{label} source is missing or cannot be resolved: {source}: {error}"
            )
            continue
        if not is_within(source_resolved, repo_resolved):
            errors.append(f"{label} source resolves outside the repository: {source}")
            continue
        if not source_resolved.is_file():
            errors.append(f"{label} source is not a file: {source}")
            continue

        links.append(
            Link(
                source_relative=source_relative,
                destination_relative=destination_relative,
                source=source,
                destination=target_home.joinpath(*destination_relative.parts),
            )
        )

    destination_paths = sorted(destinations, key=lambda item: len(item.parts))
    for index, first in enumerate(destination_paths):
        for second in destination_paths[index + 1 :]:
            if second.parts[: len(first.parts)] == first.parts:
                errors.append(f"nested destinations conflict: {first} and {second}")
    for destination in destination_paths:
        if BACKUP_PARENT.parts[: len(destination.parts)] == destination.parts:
            errors.append(
                f"destination conflicts with the reserved backup path: {destination}"
            )
        elif destination.parts[: len(BACKUP_PARENT.parts)] == BACKUP_PARENT.parts:
            errors.append(
                f"destination is inside the reserved backup path: {destination}"
            )

    if errors:
        raise PreflightError("\n".join(errors))
    return links


def equivalent(source: Path, destination: Path) -> bool:
    if not lexists(destination) or not destination.exists():
        return False
    try:
        return os.path.samefile(source, destination)
    except OSError:
        return False


def validate_target_home(target_home: Path, repo: Path) -> Path:
    if lexists(target_home):
        if target_home.is_symlink():
            raise PreflightError(f"target home must not be a symlink: {target_home}")
        if not target_home.is_dir():
            raise PreflightError(f"target home is not a directory: {target_home}")
    try:
        resolved = target_home.resolve(strict=False)
    except (OSError, RuntimeError) as error:
        raise PreflightError(
            f"cannot resolve target home {target_home}: {error}"
        ) from error
    if is_within(resolved, repo.resolve(strict=True)):
        raise PreflightError(
            f"target home resolves inside the dotfiles repository: {target_home}"
        )
    return resolved


def inspect_parents(
    target_home: Path,
    target_home_resolved: Path,
    destination: Path,
    repo_resolved: Path,
) -> set[Path]:
    missing: set[Path] = set()
    current = target_home
    parents = [target_home]
    for part in destination.parent.relative_to(target_home).parts:
        current /= part
        parents.append(current)

    for parent in parents:
        if not lexists(parent):
            missing.add(parent)
            continue
        if parent.is_symlink():
            raise PreflightError(f"destination parent must not be a symlink: {parent}")
        if not parent.is_dir():
            raise PreflightError(f"destination parent is not a directory: {parent}")
        try:
            resolved = parent.resolve(strict=True)
        except (OSError, RuntimeError) as error:
            raise PreflightError(
                f"cannot resolve destination parent {parent}: {error}"
            ) from error
        if not is_within(resolved, target_home_resolved):
            raise PreflightError(
                f"destination parent resolves outside the target home: {parent} -> {resolved}"
            )
        if is_within(resolved, repo_resolved):
            raise PreflightError(
                f"destination parent resolves inside the dotfiles repository: {parent} -> {resolved}"
            )
    return missing


def make_plan(
    links: list[Link], target_home: Path, repo: Path, backup_conflicts: bool
) -> Plan:
    home_resolved = validate_target_home(target_home, repo)
    repo_resolved = repo.resolve(strict=True)
    planned: list[Link] = []
    conflicts: list[Link] = []
    directories: set[Path] = set()
    already = 0
    errors: list[str] = []

    for link in links:
        try:
            directories.update(
                inspect_parents(
                    target_home, home_resolved, link.destination, repo_resolved
                )
            )
        except PreflightError as error:
            errors.append(str(error))
            continue

        if equivalent(link.source, link.destination):
            already += 1
            continue
        if lexists(link.destination):
            mode = os.lstat(link.destination).st_mode
            can_back_up = stat.S_ISREG(mode) or stat.S_ISLNK(mode)
            if backup_conflicts and can_back_up:
                conflicts.append(link)
                planned.append(link)
            elif backup_conflicts:
                errors.append(
                    f"conflicting destination is not a regular file or symlink: {link.destination}"
                )
            else:
                errors.append(f"destination already exists: {link.destination}")
            continue
        planned.append(link)

    if backup_conflicts and conflicts:
        backup_probe = target_home.joinpath(
            *BACKUP_PARENT.parts, "TIMESTAMP", "placeholder"
        )
        try:
            inspect_parents(target_home, home_resolved, backup_probe, repo_resolved)
        except PreflightError as error:
            errors.append(f"backup path is unsafe: {error}")

    if errors:
        raise PreflightError("\n".join(errors))
    return Plan(planned, conflicts, already, directories)


def backup_directory(target_home: Path) -> Path:
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S.%fZ")
    candidate = target_home.joinpath(*BACKUP_PARENT.parts, stamp)
    counter = 1
    while lexists(candidate):
        candidate = target_home.joinpath(*BACKUP_PARENT.parts, f"{stamp}-{counter}")
        counter += 1
    return candidate


def print_plan(plan: Plan, apply: bool, target_home: Path) -> None:
    conflict_destinations = {link.destination for link in plan.conflicts}
    backup_preview = target_home.joinpath(*BACKUP_PARENT.parts, "TIMESTAMP")
    for link in plan.conflicts:
        backed_up = backup_preview.joinpath(*link.destination_relative.parts)
        if apply:
            print(
                f"BACK UP: {link.destination} (rollback directory reported after apply)"
            )
        else:
            print(f"WOULD BACK UP: {link.destination} -> {backed_up}")
    for link in plan.links:
        action = "LINK" if apply else "WOULD LINK"
        suffix = " (after backup)" if link.destination in conflict_destinations else ""
        print(f"{action}: {link.destination} -> {link.source}{suffix}")


def apply_plan(plan: Plan, target_home: Path) -> tuple[bool, Path | None, str | None]:
    created_directories: list[Path] = []
    created_links: list[Path] = []
    moved: list[tuple[Path, Path]] = []
    backup_root = backup_directory(target_home) if plan.conflicts else None

    try:
        directories = set(plan.directories)
        if backup_root is not None:
            current = target_home
            for part in backup_root.relative_to(target_home).parts:
                current /= part
                directories.add(current)
            for link in plan.conflicts:
                current = backup_root
                for part in link.destination_relative.parent.parts:
                    current /= part
                    directories.add(current)

        for directory in sorted(directories, key=lambda item: len(item.parts)):
            if lexists(directory):
                if directory == backup_root:
                    raise OSError(
                        f"fresh backup directory became occupied: {directory}"
                    )
                if directory.is_symlink() or not directory.is_dir():
                    raise OSError(f"planned directory became unsafe: {directory}")
                continue
            directory.mkdir(mode=0o700)
            os.chmod(directory, 0o700)
            created_directories.append(directory)

        if backup_root is not None:
            os.chmod(backup_root, 0o700)
            for link in plan.conflicts:
                backed_up = backup_root.joinpath(*link.destination_relative.parts)
                link.destination.rename(backed_up)
                moved.append((link.destination, backed_up))

        for link in plan.links:
            if lexists(link.destination):
                raise OSError(
                    f"destination appeared after preflight: {link.destination}"
                )
            link.destination.symlink_to(link.source)
            created_links.append(link.destination)
    except OSError as error:
        rollback_errors: list[str] = []
        for destination in reversed(created_links):
            try:
                destination.unlink()
            except OSError as rollback_error:
                rollback_errors.append(
                    f"could not remove {destination}: {rollback_error}"
                )
        for destination, backed_up in reversed(moved):
            try:
                if lexists(destination):
                    raise OSError("destination is occupied")
                backed_up.rename(destination)
            except OSError as rollback_error:
                rollback_errors.append(
                    f"could not restore {destination} from {backed_up}: {rollback_error}"
                )
        for directory in sorted(
            created_directories, key=lambda item: len(item.parts), reverse=True
        ):
            try:
                directory.rmdir()
            except OSError:
                pass
        message = str(error)
        if rollback_errors:
            message += "; rollback incomplete: " + "; ".join(rollback_errors)
        return False, backup_root, message

    return True, backup_root, None


def run(
    repo: Path,
    manifest: Path,
    target_home: Path,
    apply: bool,
    backup_conflicts: bool,
) -> int:
    try:
        links = load_manifest(manifest, repo, target_home)
        plan = make_plan(links, target_home, repo, backup_conflicts)
    except PreflightError as error:
        for line in str(error).splitlines():
            print(f"CONFLICT: {line}", file=sys.stderr)
        print("Preflight failed; no changes made.", file=sys.stderr)
        return 1

    print_plan(plan, apply, target_home)
    if not apply:
        print(
            f"Dry run: {len(plan.links)} link(s) planned, "
            f"{len(plan.conflicts)} conflict(s) would be backed up, "
            f"{plan.already_correct} already correct."
        )
        return 0

    succeeded, backup_root, error = apply_plan(plan, target_home)
    if not succeeded:
        print(f"Apply failed: {error}", file=sys.stderr)
        return 2
    if backup_root is not None:
        print(f"Rollback files preserved at: {backup_root}")
    print(
        f"Applied: {len(plan.links)} link(s), {len(plan.conflicts)} conflict(s) backed up, "
        f"{plan.already_correct} already correct."
    )
    return 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--apply",
        action="store_true",
        help="create links after a successful full preflight (default: dry run)",
    )
    parser.add_argument(
        "--backup-conflicts",
        action="store_true",
        help="preserve conflicting regular files and symlinks before linking",
    )
    parser.add_argument(
        "--target-home",
        type=Path,
        default=Path.home(),
        help="home directory to populate (default: the current user's home)",
    )
    parser.add_argument(
        "--manifest",
        type=Path,
        help="manifest to use (default: profiles/sway/manifest.json in the repository)",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    repo = Path(__file__).resolve().parent.parent
    manifest = args.manifest or repo / DEFAULT_MANIFEST
    if not manifest.is_absolute():
        manifest = Path.cwd() / manifest
    target_home = Path(os.path.abspath(args.target_home.expanduser()))
    return run(repo, manifest, target_home, args.apply, args.backup_conflicts)


if __name__ == "__main__":
    raise SystemExit(main())
