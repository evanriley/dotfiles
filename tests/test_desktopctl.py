from __future__ import annotations

import base64
import json
import os
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "profiles/sway/home/.local/bin/desktopctl"
)


class ArchDesktopTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.home = self.root / "home with spaces"
        self.bin = self.root / "fake bin"
        self.home.mkdir()
        self.bin.mkdir()
        self.calls = self.root / "calls.jsonl"
        self.environment = os.environ.copy()
        self.environment.update(
            {
                "HOME": os.fspath(self.home),
                "PATH": os.fspath(self.bin),
                "CALLS": os.fspath(self.calls),
            }
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def executable(self, name: str, body: str = "") -> None:
        path = self.bin / name
        path.write_text(
            "#!/usr/bin/python3\n"
            "import base64\n"
            "import json\n"
            "import os\n"
            "from pathlib import Path\n"
            "import sys\n\n"
            "calls = Path(os.environ['CALLS'])\n"
            "with calls.open('a', encoding='utf-8') as stream:\n"
            "    stream.write(json.dumps({'command': Path(sys.argv[0]).name, "
            "'argv': sys.argv[1:]}) + '\\n')\n" + textwrap.dedent(body).strip() + "\n",
            encoding="utf-8",
        )
        path.chmod(0o755)

    def run_helper(self, *arguments: str) -> subprocess.CompletedProcess[bytes]:
        return subprocess.run(
            ["/usr/bin/python3", os.fspath(SCRIPT), *arguments],
            env=self.environment,
            capture_output=True,
            check=False,
        )

    def recorded(self) -> list[dict[str, object]]:
        if not self.calls.exists():
            return []
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_lock_uses_static_arguments_and_returns_status(self) -> None:
        self.executable("swaylock", "raise SystemExit(7)")

        result = self.run_helper("lock")

        self.assertEqual(result.returncode, 7)
        self.assertEqual(
            self.recorded(),
            [
                {
                    "command": "swaylock",
                    "argv": ["-f", "-C", "/dev/null", "-c", "090e13",
                             "-i", str(self.home / ".config/swaylock/lockscreen.png"),
                             "-s", "fill"],
                }
            ],
        )

    def test_idle_requires_marker_then_executes_expected_policy(self) -> None:
        self.executable("swayidle")
        absent = self.run_helper("idle")
        self.assertEqual(absent.returncode, 0)
        self.assertEqual(self.recorded(), [])

        marker = self.home / ".local/state/sway/lock-tested"
        marker.parent.mkdir(parents=True)
        marker.touch()
        present = self.run_helper("idle")

        self.assertEqual(present.returncode, 0, present.stderr)
        self.assertEqual(
            self.recorded()[0]["argv"],
            [
                "-w",
                "timeout",
                "300",
                f"swaylock -f -C /dev/null -c 090e13 -i '{self.home}/.config/swaylock/lockscreen.png' -s fill",
                "timeout",
                "600",
                "swaymsg output '*' power off",
                "resume",
                "swaymsg output '*' power on",
                "timeout",
                "1800",
                "systemctl suspend --no-block",
                "before-sleep",
                f"swaylock -f -C /dev/null -c 090e13 -i '{self.home}/.config/swaylock/lockscreen.png' -s fill",
            ],
        )

    def test_failed_lock_prevents_suspend(self) -> None:
        self.executable("fuzzel", "sys.stdout.buffer.write(b'Suspend\\n')")
        self.executable("swaylock", "raise SystemExit(9)")
        self.executable("systemctl")

        result = self.run_helper("power")

        self.assertEqual(result.returncode, 9)
        self.assertEqual(
            [call["command"] for call in self.recorded()], ["fuzzel", "swaylock"]
        )

    def test_poweroff_requires_confirmation_and_uses_exact_argv(self) -> None:
        responses = self.root / "responses"
        responses.write_text("Power Off\nYes\n", encoding="utf-8")
        self.environment["RESPONSES"] = os.fspath(responses)
        self.executable(
            "fuzzel",
            """
            path = Path(os.environ["RESPONSES"])
            lines = path.read_text(encoding="utf-8").splitlines()
            sys.stdout.write(lines[0] + "\\n")
            path.write_text("\\n".join(lines[1:]) + "\\n", encoding="utf-8")
            """,
        )
        self.executable("systemctl")

        result = self.run_helper("power")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            self.recorded()[-1], {"command": "systemctl", "argv": ["poweroff"]}
        )

    def test_clipboard_cancellation_does_not_call_wl_copy(self) -> None:
        self.executable("cliphist", "sys.stdout.buffer.write(b'1\\told value\\n')")
        self.executable("fuzzel", "raise SystemExit(1)")
        self.executable("wl-copy")

        result = self.run_helper("clipboard")

        self.assertEqual(result.returncode, 0)
        self.assertEqual(
            [call["command"] for call in self.recorded()], ["cliphist", "fuzzel"]
        )

    def test_clipboard_passes_decoded_bytes_unchanged(self) -> None:
        payload = b"binary\x00contents\n"
        self.environment["PAYLOAD"] = base64.b64encode(payload).decode()
        self.executable(
            "cliphist",
            """
            if sys.argv[1:] == ["list"]:
                sys.stdout.buffer.write(b"7\\tchosen value\\n")
            else:
                sys.stdin.buffer.read()
                sys.stdout.buffer.write(base64.b64decode(os.environ["PAYLOAD"]))
            """,
        )
        self.executable(
            "fuzzel",
            "sys.stdin.buffer.read(); sys.stdout.buffer.write(b'7\\tchosen value\\n')",
        )
        copied = self.root / "copied"
        self.environment["COPIED"] = os.fspath(copied)
        self.executable(
            "wl-copy", "Path(os.environ['COPIED']).write_bytes(sys.stdin.buffer.read())"
        )

        result = self.run_helper("clipboard")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(copied.read_bytes(), payload)

    def test_region_screenshot_cancellation_does_not_run_grim(self) -> None:
        self.executable("slurp", "raise SystemExit(1)")
        self.executable("grim")

        result = self.run_helper("screenshot", "region")

        self.assertEqual(result.returncode, 0)
        self.assertEqual([call["command"] for call in self.recorded()], ["slurp"])

    def test_output_screenshot_keeps_output_and_file_paths_as_arguments(self) -> None:
        self.executable(
            "swaymsg",
            "sys.stdout.write(json.dumps([{'name': 'Display With Spaces', 'focused': True}]))",
        )
        self.executable("grim", "Path(sys.argv[-1]).write_bytes(b'PNG data')")
        copied = self.root / "screenshot copied"
        self.environment["COPIED"] = os.fspath(copied)
        self.executable(
            "wl-copy", "Path(os.environ['COPIED']).write_bytes(sys.stdin.buffer.read())"
        )

        result = self.run_helper("screenshot", "output")

        self.assertEqual(result.returncode, 0, result.stderr)
        grim = next(call for call in self.recorded() if call["command"] == "grim")
        self.assertEqual(grim["argv"][:2], ["-o", "Display With Spaces"])
        self.assertEqual(len(grim["argv"]), 3)
        self.assertTrue(str(grim["argv"][2]).startswith(os.fspath(self.home)))
        self.assertEqual(copied.read_bytes(), b"PNG data")

    def test_window_screenshot_uses_focused_leaf_geometry(self) -> None:
        tree = {
            "nodes": [
                {
                    "focused": False,
                    "nodes": [
                        {
                            "focused": True,
                            "rect": {"x": 10, "y": 20, "width": 800, "height": 600},
                        }
                    ],
                }
            ]
        }
        self.environment["TREE"] = json.dumps(tree)
        self.executable("swaymsg", "sys.stdout.write(os.environ['TREE'])")
        self.executable("grim", "Path(sys.argv[-1]).write_bytes(b'PNG')")
        self.executable("wl-copy", "sys.stdin.buffer.read()")

        result = self.run_helper("screenshot", "window")

        self.assertEqual(result.returncode, 0, result.stderr)
        grim = next(call for call in self.recorded() if call["command"] == "grim")
        self.assertEqual(grim["argv"][:2], ["-g", "10,20 800x600"])

    def test_existing_scratch_btop_is_shown_without_spawning_foot(self) -> None:
        self.executable(
            "swaymsg",
            """
            if sys.argv[1:] == ["-t", "get_tree", "-r"]:
                sys.stdout.write(json.dumps({"nodes": [{"app_id": "scratch_btop"}]}))
            """,
        )
        self.executable("foot")

        result = self.run_helper("scratch-btop")

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.recorded()
        self.assertNotIn("foot", [call["command"] for call in calls])
        self.assertEqual(
            [call for call in calls if call["argv"] != ["-t", "get_tree", "-r"]][-1],
            {
                "command": "swaymsg",
                "argv": ['[app_id="^scratch_btop$"]', "scratchpad", "show"],
            },
        )

    def test_missing_scratch_btop_is_spawned_then_shown(self) -> None:
        counter = self.root / "tree-count"
        self.environment["TREE_COUNT"] = os.fspath(counter)
        self.executable(
            "swaymsg",
            """
            if sys.argv[1:] == ["-t", "get_tree", "-r"]:
                counter = Path(os.environ["TREE_COUNT"])
                count = int(counter.read_text()) if counter.exists() else 0
                counter.write_text(str(count + 1))
                app_id = "scratch_btop" if count >= 1 else None
                sys.stdout.write(json.dumps({"nodes": [{"app_id": app_id}]}))
            """,
        )
        self.executable("foot")

        result = self.run_helper("scratch-btop")

        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.recorded()
        foot = next(call for call in calls if call["command"] == "foot")
        self.assertEqual(foot["argv"], ["--app-id=scratch_btop", "btop"])
        self.assertEqual(
            [call for call in calls if call["argv"] != ["-t", "get_tree", "-r"]][-1],
            {
                "command": "swaymsg",
                "argv": ['[app_id="^scratch_btop$"]', "scratchpad", "show"],
            },
        )


    def test_first_visible_scratchpad_is_sized_after_show(self) -> None:
        self.executable(
            "swaymsg",
            """
            if sys.argv[1:] == ["-t", "get_tree", "-r"]:
                sys.stdout.write(json.dumps({"nodes": [{
                    "app_id": "scratch_btop", "visible": True,
                    "scratchpad_state": "fresh"
                }]}))
            """,
        )
        result = self.run_helper("scratch-btop")
        self.assertEqual(result.returncode, 0, result.stderr)
        actions = [call["argv"] for call in self.recorded()
                   if call["argv"] != ["-t", "get_tree", "-r"]]
        self.assertEqual(actions[0][1:], ["scratchpad", "show"])
        self.assertIn("resize set width 80 ppt height 80 ppt", actions[1][1])

    def test_hiding_scratchpad_does_not_resize_hidden_window(self) -> None:
        self.executable(
            "swaymsg",
            """
            if sys.argv[1:] == ["-t", "get_tree", "-r"]:
                sys.stdout.write(json.dumps({"nodes": [{
                    "app_id": "scratch_btop", "visible": False,
                    "scratchpad_state": "fresh"
                }]}))
            """,
        )
        result = self.run_helper("scratch-btop")
        self.assertEqual(result.returncode, 0, result.stderr)
        actions = [call["argv"] for call in self.recorded()
                   if call["argv"] != ["-t", "get_tree", "-r"]]
        self.assertEqual(actions, [['[app_id="^scratch_btop$"]', "scratchpad", "show"]])

    def test_resized_scratchpad_keeps_its_geometry_on_later_show(self) -> None:
        self.executable(
            "swaymsg",
            """
            if sys.argv[1:] == ["-t", "get_tree", "-r"]:
                sys.stdout.write(json.dumps({"nodes": [{
                    "app_id": "scratch_btop", "visible": True,
                    "marks": ["desktopctl_btop_sized"]
                }]}))
            """,
        )
        result = self.run_helper("scratch-btop")
        self.assertEqual(result.returncode, 0, result.stderr)
        actions = [call["argv"] for call in self.recorded()
                   if call["argv"] != ["-t", "get_tree", "-r"]]
        self.assertEqual(actions, [['[app_id="^scratch_btop$"]', "scratchpad", "show"]])

if __name__ == "__main__":
    unittest.main()
