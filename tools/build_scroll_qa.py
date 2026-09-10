#!/usr/bin/env python3
"""Export an isolated scrolling QA app with production UI and synthetic fixtures."""
from pathlib import Path
import argparse, os, shutil, subprocess
parser = argparse.ArgumentParser()
parser.add_argument('--baseline', action='store_true')
parser.add_argument('--evidence', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
dest = root / 'builds/scroll-qa-src'
if dest.exists(): shutil.rmtree(dest)
shutil.copytree(root, dest, ignore=shutil.ignore_patterns('.git','.godot','builds','evidence','__pycache__'))
(dest / 'scripts/qa').mkdir(parents=True, exist_ok=True)
(dest / 'scenes/qa').mkdir(parents=True, exist_ok=True)
shutil.copy(root / 'tests/scroll_phone_fixture.gd', dest / 'scripts/qa/scroll_phone_fixture.gd')
(dest / 'scenes/qa/scroll.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/qa/scroll_phone_fixture.gd" id="1"]\n[node name="ScrollQA" type="Node"]\nscript = ExtResource("1")\n')
p = dest / 'project.godot'
p.write_text(p.read_text().replace('run/main_scene="res://scenes/boot/boot.tscn"','run/main_scene="res://scenes/qa/scroll.tscn"'))
p = dest / 'export_presets.cfg'
s = p.read_text().replace('org.nightshiftfm.spike','org.nightshiftfm.scrollqa').replace('package/name="Nightshift FM"','package/name="Nightshift FM Scroll QA"')
if args.baseline: s = s.replace('[preset.0]\n','[preset.0]\ncustom_features="scroll_baseline"\n')
p.write_text(s)
evidence = args.evidence or root / 'docs/evidence/scrolling'; evidence.mkdir(parents=True,exist_ok=True)
apk = root / 'builds/android' / ('nightshift-scroll-baseline.apk' if args.baseline else 'nightshift-scroll-qa.apk')
for name, arguments in [('import',['--import']),('export',['--export-debug','Android Debug',str(apk)])]:
    path = evidence / (('baseline-' if args.baseline else '') + 'qa-' + name + '.txt')
    with path.open('w') as log:
        result = subprocess.run([os.environ['GODOT_BIN'],'--headless','--path',str(dest),*arguments],stdout=log,stderr=subprocess.STDOUT)
    output = path.read_text()
    if result.returncode or any(marker in output for marker in ['ERROR:','SCRIPT ERROR:','FAIL:']):
        raise SystemExit(f'FAIL: {path}')
print(apk)
