#!/usr/bin/env python3
"""Engine-independent file/wrapper checks. Does NOT parse or execute GDScript."""
import csv
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from android_probe_check import latest_event_after

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = ROOT / "tools/godot.sh"


class FoundationChecks(unittest.TestCase):
    def test_android_log_rotation(self):
        event = {"event": "os_resume", "pauses": 20, "resumes": 20}
        self.assertEqual(latest_event_after([event], "os_resume", 19), event)
        self.assertIsNone(latest_event_after([event], "os_resume", 20))
        self.assertIsNone(latest_event_after([event], "os_pause", 19))
        self.assertIsNone(latest_event_after([], "ready", 0))

    def test_export_excludes_local_work(self):
        presets = (ROOT / "export_presets.cfg").read_text()
        filters = re.findall(r'^exclude_filter="([^"]*)"', presets, re.MULTILINE)
        self.assertEqual(len(filters), 2)
        for value in filters:
            for directory in ["builds", "dist", "tests", "docs", "tools", "prompts"]:
                self.assertIn(directory + "/*", value.split(","), "Local work must not enter exported packages")

    def test_resource_paths_exist(self):
        generated = "assets/ui_strings.en.translation"
        for path in sorted(ROOT.rglob("*")):
            if path.suffix not in {".gd", ".tscn", ".tres", ".godot"}:
                continue
            if any(part in {".godot", "builds"} for part in path.relative_to(ROOT).parts):
                continue
            for reference in re.findall(r'res://([^"\s]+)', path.read_text()):
                if reference == generated:
                    self.assertTrue((ROOT / "assets/ui_strings.csv").is_file())
                    self.assertTrue((ROOT / reference).is_file(), "Keep the generated translation in source for a clean first import")
                elif reference.endswith("/"):
                    self.assertTrue((ROOT / reference).is_dir(), (path, reference))
                else:
                    self.assertTrue((ROOT / reference).is_file(), (path, reference))

    def test_ui_localization_keys(self):
        with (ROOT / "assets/ui_strings.csv").open(newline="") as stream:
            rows = list(csv.DictReader(stream))
        keys = [row["keys"] for row in rows]
        self.assertEqual(len(keys), len(set(keys)))
        self.assertTrue(all(row["en"] for row in rows))
        for scene_path in (ROOT / "scenes").rglob("*.tscn"):
            for key in re.findall(r'^text = "([^"]+)"', scene_path.read_text(), re.MULTILINE):
                self.assertIn(key, keys)

    def test_bounded_m4_content_and_no_release_credentials(self):
        self.assertEqual(len(list((ROOT / "content").rglob("*.tres"))), 575)
        self.assertEqual(len(list((ROOT / "content/upgrades").rglob("*.tres"))), 18)
        presets = (ROOT / "export_presets.cfg").read_text()
        self.assertIn('application/export_project_only=true', presets)
        self.assertIn('permissions/internet=false', presets)
        self.assertNotRegex(presets, r'keystore/.*=\s*"[^"\s]+"')

    def test_wrapper_requires_engine(self):
        env = os.environ.copy()
        env.pop("GODOT_BIN", None)
        result = subprocess.run(["sh", str(WRAPPER), "import"], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 127)
        self.assertIn("NOT RUN", result.stderr)

    def test_wrapper_missing_executable(self):
        env = dict(os.environ, GODOT_BIN="/nonexistent/m0-godot")
        result = subprocess.run(["sh", str(WRAPPER), "test"], env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 127)

    def test_wrapper_contract_with_stub(self):
        # Temporary stand-in tests shell forwarding only; it is never an engine substitute.
        with tempfile.TemporaryDirectory(prefix="m0 wrapper test ") as directory:
            stub = Path(directory) / "engine with spaces"
            log = Path(directory) / "args.json"
            stub.write_text("#!/usr/bin/env python3\n"
                            "import json, os, sys\n"
                            "if sys.argv[1:] == ['--version']:\n"
                            "    print(os.environ['M0_STUB_VERSION'])\n"
                            "    sys.exit(0)\n"
                            "with open(os.environ['M0_STUB_LOG'], 'w') as stream:\n"
                            "    json.dump(sys.argv[1:], stream)\n"
                            "sys.exit(int(os.environ.get('M0_STUB_EXIT', '0')))\n")
            stub.chmod(0o755)
            env = dict(os.environ, GODOT_BIN=str(stub), M0_STUB_LOG=str(log),
                       M0_STUB_VERSION="4.7.2.stable.official.fixture")
            commands = {
                "import": ["--headless", "--path", str(ROOT), "--import"],
                "test": ["--headless", "--path", str(ROOT), "--script", "res://tests/test_runner.gd", "--"],
                "smoke": ["--headless", "--path", str(ROOT), "--quit-after", "10"],
                "run": ["--path", str(ROOT)],
                "editor": ["--path", str(ROOT), "--editor"],
            }
            for mode, expected in commands.items():
                with self.subTest(mode=mode):
                    result = subprocess.run(["sh", str(WRAPPER), mode], cwd=directory, env=env, capture_output=True)
                    self.assertEqual(result.returncode, 0)
                    self.assertEqual(json.loads(log.read_text()), expected)
            env["M0_STUB_EXIT"] = "9"
            result = subprocess.run(["sh", str(WRAPPER), "test", "--intentional-failure"], env=env)
            self.assertEqual(result.returncode, 9)
            self.assertEqual(json.loads(log.read_text())[-2:], ["--", "--intentional-failure"])
            result = subprocess.run(["sh", str(WRAPPER), "import"], env=env)
            self.assertEqual(result.returncode, 9)
            for wrong in ["4.6.2.stable.official.fake", "4.7.2.stable.mono.official.fake", "4.7.2.rc1.official.fake"]:
                env["M0_STUB_VERSION"] = wrong
                result = subprocess.run(["sh", str(WRAPPER), "import"], env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 2)
                self.assertIn("engine mismatch", result.stderr)


if __name__ == "__main__":
    unittest.main(verbosity=2)
