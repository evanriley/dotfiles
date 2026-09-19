from __future__ import annotations

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SOURCE_SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "link-dotfiles.py"


class LinkArchSwayTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.repo = self.root / "dotfiles"
        (self.repo / "scripts").mkdir(parents=True)
        shutil.copy2(SOURCE_SCRIPT, self.repo / "scripts" / "link-dotfiles.py")
        self.manifest = self.repo / "profiles/sway/manifest.json"

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def source(self, relative: str, contents: str = "profile\n") -> Path:
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        return path

    def write_manifest(
        self, links: list[dict[str, object]], version: object = 1
    ) -> None:
        self.manifest.parent.mkdir(parents=True, exist_ok=True)
        self.manifest.write_text(
            json.dumps({"version": version, "links": links}), encoding="utf-8"
        )

    def entry(self, source: str, destination: str) -> dict[str, object]:
        return {"source": source, "destination": destination}

    def run_script(
        self, home: Path, *arguments: str
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                "python3",
                os.fspath(self.repo / "scripts/link-dotfiles.py"),
                "--target-home",
                os.fspath(home),
                *arguments,
            ],
            text=True,
            capture_output=True,
            check=False,
        )

    def test_dry_run_is_default_and_writes_nothing(self) -> None:
        relative = "profiles/sway/home/.config/sway/config"
        self.source(relative)
        self.write_manifest([self.entry(relative, ".config/sway/config")])
        home = self.root / "home"

        result = self.run_script(home)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("WOULD LINK", result.stdout)
        self.assertFalse(home.exists())

    def test_apply_links_explicit_files_and_is_idempotent(self) -> None:
        profile_relative = "profiles/sway/home/.config/sway/config"
        shared_relative = ".config/foot/foot.ini"
        profile = self.source(profile_relative)
        shared = self.source(shared_relative)
        self.write_manifest(
            [
                self.entry(profile_relative, ".config/sway/config"),
                self.entry(shared_relative, ".config/foot/foot.ini"),
            ]
        )
        home = self.root / "home"

        first = self.run_script(home, "--apply")
        second = self.run_script(home, "--apply")

        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertEqual((home / ".config/sway/config").resolve(), profile.resolve())
        self.assertEqual((home / ".config/foot/foot.ini").resolve(), shared.resolve())
        self.assertIn("0 link(s)", second.stdout)
        self.assertIn("2 already correct", second.stdout)

    def test_full_preflight_failure_leaves_no_partial_links(self) -> None:
        good = "profiles/sway/home/.config/alpha/config"
        self.source(good)
        self.write_manifest(
            [
                self.entry(good, ".config/alpha/config"),
                self.entry(
                    "profiles/sway/home/.config/missing", ".config/zeta/config"
                ),
            ]
        )
        home = self.root / "home"

        result = self.run_script(home, "--apply")

        self.assertEqual(result.returncode, 1)
        self.assertIn("source is missing", result.stderr)
        self.assertFalse(home.exists())

    def test_destination_conflict_aborts_other_planned_links(self) -> None:
        first = "profiles/sway/home/.config/alpha/config"
        second = "profiles/sway/home/.config/zeta/config"
        self.source(first)
        self.source(second)
        self.write_manifest(
            [
                self.entry(first, ".config/alpha/config"),
                self.entry(second, ".config/zeta/config"),
            ]
        )
        home = self.root / "home"
        conflict = home / ".config/zeta/config"
        conflict.parent.mkdir(parents=True)
        conflict.write_text("keep me\n", encoding="utf-8")

        result = self.run_script(home, "--apply")

        self.assertEqual(result.returncode, 1)
        self.assertEqual(conflict.read_text(encoding="utf-8"), "keep me\n")
        self.assertFalse((home / ".config/alpha").exists())

    def test_existing_and_broken_symlink_destinations_are_conflicts(self) -> None:
        relative = "profiles/sway/home/.config/sway/config"
        self.source(relative)
        self.write_manifest([self.entry(relative, ".config/sway/config")])
        for name, create in (
            ("file", lambda path: path.write_text("local\n", encoding="utf-8")),
            ("broken", lambda path: path.symlink_to("missing-target")),
        ):
            with self.subTest(name=name):
                home = self.root / f"home-{name}"
                destination = home / ".config/sway/config"
                destination.parent.mkdir(parents=True)
                create(destination)

                result = self.run_script(home, "--apply")

                self.assertEqual(result.returncode, 1)
                self.assertIn("destination already exists", result.stderr)
                if name == "file":
                    self.assertEqual(destination.read_text(encoding="utf-8"), "local\n")
                else:
                    self.assertEqual(os.readlink(destination), "missing-target")

    def test_opt_in_backup_preserves_regular_file_and_symlink(self) -> None:
        first_relative = "profiles/sway/home/.config/sway/config"
        second_relative = "profiles/sway/home/.config/waybar/config.jsonc"
        first_source = self.source(first_relative)
        second_source = self.source(second_relative)
        self.write_manifest(
            [
                self.entry(first_relative, ".config/sway/config"),
                self.entry(second_relative, ".config/waybar/config.jsonc"),
            ]
        )
        home = self.root / "home"
        first_destination = home / ".config/sway/config"
        second_destination = home / ".config/waybar/config.jsonc"
        first_destination.parent.mkdir(parents=True)
        second_destination.parent.mkdir(parents=True)
        first_destination.write_text("local sway\n", encoding="utf-8")
        second_destination.symlink_to("old-waybar-config")
        unrelated = home / ".config/keep-local.conf"
        unrelated.write_text("unrelated\n", encoding="utf-8")

        preview = self.run_script(home, "--backup-conflicts")
        self.assertEqual(preview.returncode, 0, preview.stderr)
        self.assertIn("WOULD BACK UP", preview.stdout)
        self.assertEqual(first_destination.read_text(encoding="utf-8"), "local sway\n")
        self.assertEqual(os.readlink(second_destination), "old-waybar-config")
        self.assertFalse((home / ".local/state/sway/backups").exists())

        applied = self.run_script(home, "--backup-conflicts", "--apply")

        self.assertEqual(applied.returncode, 0, applied.stderr)
        self.assertEqual(first_destination.resolve(), first_source.resolve())
        self.assertEqual(second_destination.resolve(), second_source.resolve())
        backups = list((home / ".local/state/sway/backups").iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual(
            (backups[0] / ".config/sway/config").read_text(encoding="utf-8"),
            "local sway\n",
        )
        saved_link = backups[0] / ".config/waybar/config.jsonc"
        self.assertTrue(saved_link.is_symlink())
        self.assertEqual(os.readlink(saved_link), "old-waybar-config")
        self.assertEqual(unrelated.read_text(encoding="utf-8"), "unrelated\n")
        self.assertEqual(backups[0].stat().st_mode & 0o777, 0o700)
        self.assertIn("Rollback files preserved at:", applied.stdout)

    def test_rejects_invalid_destination_paths_and_nesting(self) -> None:
        first = "profiles/sway/home/first"
        second = "profiles/sway/home/second"
        self.source(first)
        self.source(second)
        cases = (
            [self.entry(first, "/absolute")],
            [self.entry(first, ".config/../escape")],
            [
                self.entry(first, ".config/sway"),
                self.entry(second, ".config/sway/config"),
            ],
            [
                self.entry(first, ".config/sway/config"),
                self.entry(second, ".config/sway/config"),
            ],
        )
        for index, links in enumerate(cases):
            with self.subTest(index=index):
                self.write_manifest(links)
                home = self.root / f"invalid-home-{index}"
                result = self.run_script(home, "--apply")
                self.assertEqual(result.returncode, 1)
                self.assertFalse(home.exists())

    def test_rejects_missing_directory_and_escaped_sources(self) -> None:
        directory = "profiles/sway/home/directory"
        (self.repo / directory).mkdir(parents=True)
        outside = self.root / "outside"
        outside.write_text("private\n", encoding="utf-8")
        escaped = self.repo / "profiles/sway/home/escaped"
        escaped.symlink_to(outside)
        cases = (
            "profiles/sway/home/missing",
            directory,
            "profiles/sway/home/escaped",
            "../outside",
        )
        for index, source in enumerate(cases):
            with self.subTest(source=source):
                self.write_manifest([self.entry(source, ".config/app/config")])
                home = self.root / f"source-home-{index}"
                result = self.run_script(home, "--apply")
                self.assertEqual(result.returncode, 1)
                self.assertFalse(home.exists())

    def test_parent_symlink_is_rejected_even_when_it_points_inside_home(self) -> None:
        relative = "profiles/sway/home/.config/sway/config"
        self.source(relative)
        self.write_manifest([self.entry(relative, ".config/sway/config")])
        home = self.root / "home"
        redirected = home / "redirected-config"
        redirected.mkdir(parents=True)
        (home / ".config").symlink_to(redirected, target_is_directory=True)

        result = self.run_script(home, "--apply")

        self.assertEqual(result.returncode, 1)
        self.assertIn("parent must not be a symlink", result.stderr)
        self.assertEqual(list(redirected.iterdir()), [])

    def test_apply_failure_restores_backups_and_removes_partial_links(self) -> None:
        spec = importlib.util.spec_from_file_location(
            "arch_linker_rollback", SOURCE_SCRIPT
        )
        assert spec is not None and spec.loader is not None
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        self.addCleanup(sys.modules.pop, spec.name, None)
        spec.loader.exec_module(module)
        self.source("profile-a")
        self.source("profile-b")
        self.write_manifest(
            [
                self.entry("profile-a", ".config/alpha/config"),
                self.entry("profile-b", ".config/beta/config"),
            ]
        )
        home = self.root / "home"
        first = home / ".config/alpha/config"
        second = home / ".config/beta/config"
        first.parent.mkdir(parents=True)
        second.parent.mkdir(parents=True)
        first.write_text("original config\n")
        first.chmod(0o600)
        second.symlink_to("old-relative-target")
        links = module.load_manifest(self.manifest, self.repo, home)
        plan = module.make_plan(links, home, self.repo, backup_conflicts=True)
        real_symlink = Path.symlink_to

        def fail_second(destination: Path, target: Path) -> None:
            if destination == second:
                raise OSError("simulated link failure")
            real_symlink(destination, target)

        with mock.patch.object(Path, "symlink_to", fail_second):
            succeeded, _, error = module.apply_plan(plan, home)
        self.assertFalse(succeeded)
        self.assertIn("simulated link failure", error)
        self.assertFalse(first.is_symlink())
        self.assertEqual(first.read_text(), "original config\n")
        self.assertEqual(first.stat().st_mode & 0o777, 0o600)
        self.assertTrue(second.is_symlink())
        self.assertEqual(os.readlink(second), "old-relative-target")
        self.assertFalse((home / ".local").exists())

    def test_custom_manifest_is_supported(self) -> None:
        relative = "profiles/sway/home/.config/sway/config"
        source = self.source(relative)
        custom = self.root / "fixture-manifest.json"
        custom.write_text(
            json.dumps(
                {
                    "version": 1,
                    "links": [self.entry(relative, ".config/sway/config")],
                }
            ),
            encoding="utf-8",
        )
        home = self.root / "custom-home"

        result = self.run_script(home, "--manifest", os.fspath(custom), "--apply")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((home / ".config/sway/config").resolve(), source.resolve())


if __name__ == "__main__":
    unittest.main()
