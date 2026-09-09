#!/usr/bin/env python3
"""Build an isolated observer APK from current runtime sources; never modify them."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--patchboard', action='store_true', help='Build M6 full-run observer')
parser.add_argument('--campaign-ui', action='store_true', help='Build read-only campaign UI observer around regular boot')
parser.add_argument('--touch', action='store_true', help='Build the frozen native-touch regression fixture')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = args.output.resolve()
output.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='nightshift-emulator-qa-') as folder:
    project = Path(folder) / 'project'
    shutil.copytree(root, project, ignore=shutil.ignore_patterns('.git', '.godot', 'builds', 'docs', 'prompts'))
    qa = project / 'qa'
    qa.mkdir()
    shutil.copyfile(root / ('tests/campaign_ui_playtest.gd' if args.campaign_ui else 'tests/touch_playtest.gd' if args.touch else 'tests/patchboard_playtest.gd' if args.patchboard else 'tests/emulator_playtest.gd'), qa / 'observer.gd')
    (qa / 'main.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://qa/observer.gd" id="1"]\n[node name="EmulatorPlaytest" type="Node"]\nscript = ExtResource("1")\n')
    config = project / 'project.godot'
    config.write_text(config.read_text().replace('res://scenes/boot/boot.tscn', 'res://qa/main.tscn'))
    config = project / 'export_presets.cfg'
    config.write_text(config.read_text().replace('org.nightshiftfm.spike', 'org.nightshiftfm.campaignqa' if args.campaign_ui else 'org.nightshiftfm.touchqa' if args.touch else 'org.nightshiftfm.turretqa').replace('package/name="Nightshift FM"', 'package/name="Nightshift Touch QA"' if args.touch else 'package/name="Nightshift Turret QA"'))
    hashes = {}
    for directory in ['scripts', 'scenes', 'content', 'assets']:
        for path in sorted((root / directory).rglob('*')):
            if path.is_file():
                relative = path.relative_to(root)
                assert path.read_bytes() == (project / relative).read_bytes()
                hashes[str(relative)] = hashlib.sha256(path.read_bytes()).hexdigest()
    subprocess.run(['sh', str(project / 'tools/godot.sh'), 'import'], check=True)
    subprocess.run([os.environ['GODOT_BIN'], '--headless', '--path', str(project), '--export-debug', 'Android Debug', str(output)], check=True)
    output.with_suffix('.manifest.json').write_text(json.dumps({'apk_sha256': hashlib.sha256(output.read_bytes()).hexdigest(), 'runtime_sources': hashes, 'qa_observer_sha256': hashlib.sha256((qa / 'observer.gd').read_bytes()).hexdigest(), 'differences': ['QA entry scene and frozen seeded formation with telemetry' if args.touch else 'QA entry scene and read-only telemetry observer', 'Android package and app label']}, indent=2))
print(output)
