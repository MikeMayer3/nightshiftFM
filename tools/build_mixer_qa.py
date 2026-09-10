#!/usr/bin/env python3
"""Build an isolated emulator package; the player package and saves are untouched."""
from pathlib import Path
import os, shutil, subprocess
root = Path(__file__).resolve().parents[1]
dest = root / 'builds/mixer-qa-src'
if dest.exists():
    shutil.rmtree(dest)
shutil.copytree(root, dest, ignore=shutil.ignore_patterns('.git', '.godot', 'builds', 'evidence', '__pycache__'))
for directory in ['scripts/qa', 'scenes/qa']:
    (dest / directory).mkdir(parents=True, exist_ok=True)
(dest / 'scripts/qa/mixer_qa.gd').write_text('''extends Node
func _ready() -> void:
	var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = "user://mixer_qa.json"
	add_child(boot)
	if boot.continue_button.visible:
		boot.continue_button.pressed.emit()
	else:
		boot.show_page(BootScreen.Page.CAMPAIGN)
		boot.campaign_panel.launch_button.pressed.emit()
		boot.picker.launch_button.pressed.emit()
	await get_tree().create_timer(2.5).timeout
	boot.combat.open_mixer()
''')
(dest / 'scenes/qa/mixer_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/qa/mixer_qa.gd" id="1"]
[node name="MixerQA" type="Node"]
script = ExtResource("1")
''')
p = dest / 'project.godot'
p.write_text(p.read_text().replace('run/main_scene="res://scenes/boot/boot.tscn"', 'run/main_scene="res://scenes/qa/mixer_qa.tscn"'))
p = dest / 'export_presets.cfg'
p.write_text(p.read_text().replace('org.nightshiftfm.spike', 'org.nightshiftfm.mixerqa').replace('package/name="Nightshift FM"', 'package/name="Nightshift FM Mixer QA"').replace('[preset.0]\n', '[preset.0]\ncustom_features="qa"\n'))
engine = os.environ['GODOT_BIN']
evidence = root / 'docs/evidence/M10-mixer'
apk = root / 'builds/android/nightshift-mixer-qa.apk'
for name, args in [('qa-import', ['--import']), ('qa-export', ['--export-debug', 'Android Debug', str(apk)])]:
    with (evidence / (name + '.txt')).open('w') as log:
        subprocess.run([engine, '--headless', '--path', str(dest), *args], stdout=log, stderr=subprocess.STDOUT, check=True)
print(apk)
