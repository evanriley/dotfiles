from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MANIFEST = REPO / "profiles/sway/manifest.json"
INSTALLER = REPO / "scripts/link-dotfiles.py"


class ArchSwayProfileTest(unittest.TestCase):
    def test_complete_manifest_deploys_and_repeats_without_writing_sources(
        self,
    ) -> None:
        links = json.loads(MANIFEST.read_text())["links"]
        contents = {
            entry["source"]: (REPO / entry["source"]).read_bytes() for entry in links
        }
        with tempfile.TemporaryDirectory(prefix="arch profile ") as temporary:
            home = Path(temporary) / "home"
            command = [sys.executable, str(INSTALLER), "--target-home", str(home)]
            preview = subprocess.run(
                command, capture_output=True, text=True, check=False
            )
            self.assertEqual(preview.returncode, 0, preview.stderr)
            self.assertFalse(home.exists(), "dry run must not create the target home")
            apply = subprocess.run(
                command + ["--apply"], capture_output=True, text=True, check=False
            )
            self.assertEqual(apply.returncode, 0, apply.stderr)
            for entry in links:
                destination = home / entry["destination"]
                self.assertTrue(destination.is_symlink(), str(destination))
                self.assertEqual(
                    destination.resolve(), (REPO / entry["source"]).resolve()
                )
            repeat = subprocess.run(
                command + ["--apply"], capture_output=True, text=True, check=False
            )
            self.assertEqual(repeat.returncode, 0, repeat.stderr)
            self.assertIn(f"{len(links)} already correct", repeat.stdout)
        for source, before in contents.items():
            self.assertEqual((REPO / source).read_bytes(), before, source)

    def test_deployment_has_only_reviewed_profile_files_and_retains_exclusions(
        self,
    ) -> None:
        links = json.loads(MANIFEST.read_text())["links"]
        profile_home = REPO / "profiles/sway/home"
        deployed = {entry["source"] for entry in links}
        for path in profile_home.rglob("*"):
            if path.is_file() and "__pycache__" not in path.parts:
                self.assertIn(str(path.relative_to(REPO)), deployed)
        excluded = {
            "dinit.d",
            "niri",
            "doom",
            "emacs",
            "goimapnotify",
            "msmtp",
            "mpd",
            "rmpc",
            "__pycache__",
        }
        for entry in links:
            self.assertFalse(
                excluded.intersection(Path(entry["destination"]).parts), entry
            )
            self.assertNotIn("install-language-tools", entry["source"])
            self.assertNotIn(".gnupg/", entry["source"])
        for helper in ("start-sway", "desktopctl"):
            self.assertTrue(os.access(profile_home / ".local/bin" / helper, os.X_OK))


if __name__ == "__main__":
    unittest.main()
