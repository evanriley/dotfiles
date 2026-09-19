import importlib.machinery
import types
import unittest
from pathlib import Path
from unittest.mock import patch

path = Path(__file__).resolve().parents[1] / "profiles/sway/home/.local/bin/display-mode"
module = types.ModuleType("display_mode")
importlib.machinery.SourceFileLoader(module.__name__, str(path)).exec_module(module)


class DisplayModeTest(unittest.TestCase):
    def setUp(self):
        self.gaming = {"width": 3072, "height": 1728, "refresh": 239977}
        self.desktop = {"width": 6144, "height": 3456, "refresh": 164997}
        self.output = {"name": "DP-2", "model": "Odyssey G80HS", "active": True,
                       "power": True, "scale": 2,
                       "current_mode": {**self.desktop, "refresh": 35499},
                       "modes": [self.gaming, {**self.gaming, "refresh": 329990},
                                 {**self.desktop, "refresh": 35499}]}

    def test_gaming_mode_uses_advertised_refresh_and_scale(self):
        self.assertEqual(module.choose_mode(self.output), (self.gaming, 1))

    def test_productivity_mode_returns_to_scale_two(self):
        self.output["modes"] = [self.desktop]
        self.assertEqual(module.choose_mode(self.output), (self.desktop, 2))

    def test_unknown_disconnected_and_powered_off_outputs_are_untouched(self):
        for changes in ({"model": "Other"}, {"active": False}, {"power": False},
                        {"modes": [{**self.desktop, "refresh": 35499}]}):
            with self.subTest(changes=changes):
                self.assertIsNone(module.choose_mode({**self.output, **changes}))

    @patch.object(module.subprocess, "run")
    def test_matching_mode_is_noop_to_prevent_event_loop(self, run):
        self.output.update(current_mode=self.gaming, scale=1)
        module.apply_outputs([self.output])
        run.assert_not_called()

    @patch.object(module.subprocess, "run")
    def test_mode_and_scale_are_one_command(self, run):
        run.return_value.stdout = '[{"success": true}]'
        module.apply_outputs([self.output])
        self.assertEqual(run.call_args.args[0],
                         ["swaymsg", "-r", 'output "DP-2" mode 3072x1728@239.977Hz scale 1'])

    @patch.object(module.subprocess, "run")
    def test_failed_apply_is_reported(self, run):
        run.return_value.stdout = '[{"success": false, "error": "unavailable"}]'
        with self.assertRaises(RuntimeError):
            module.apply_outputs([self.output])

    @patch.object(module.subprocess, "run")
    def test_dry_run_never_changes_output(self, run):
        module.apply_outputs([self.output], dry_run=True)
        run.assert_not_called()
