#!/usr/bin/env python3
"""Reproducible isolated emulator export; never installs or edits the player package."""
from pathlib import Path
import shutil,subprocess,os
root=Path(__file__).resolve().parents[1]
dest=root/'builds/broadcast-qa-src'
if dest.exists():shutil.rmtree(dest)
shutil.copytree(root,dest,ignore=shutil.ignore_patterns('.git','.godot','builds','evidence','__pycache__'))
for folder in ['scenes/qa','scripts/qa']:(dest/folder).mkdir(parents=True,exist_ok=True)
(dest/'scripts/qa/broadcast_qa.gd').write_text('''extends Node
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
func _ready() -> void:
	var store: MissionStore = MissionStore.new("user://broadcast_qa.json")
	if store.load_save().is_empty():
		var profile: MissionProfile = MissionProfile.new()
		for mission: int in range(1, 13):
			var s: CombatSession = CombatSession.new()
			s.start_campaign(42, StringName("run.%d" % profile.next_run), ArsenalContent.DEFAULT, {"mission": mission, "cleared": mission - 1, "modules": [], "mode": "campaign", "difficulty": 0, "contract": ""})
			profile.next_run += 1
			s.wave = 10
			s._finish(true)
			profile.commit_reward(s.run_id, s)
		assert(store.save(profile, {}) == OK)
	Engine.time_scale = 3.0
	var boot: BootScreen = BOOT.instantiate()
	boot.save_path = store.path
	add_child(boot)
	var label: Label = Label.new()
	label.text = "QA · 3× simulation · unlocked fixture"
	label.add_theme_font_size_override("font_size", 16)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.modulate = Color("ffbd72")
	label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	label.position.y = -22
	boot.add_child(label)
''')
(dest/'scenes/qa/broadcast_qa.tscn').write_text('''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/qa/broadcast_qa.gd" id="1"]
[node name="BroadcastQA" type="Node"]
script = ExtResource("1")
''')
p=dest/'project.godot';text=p.read_text().replace('run/main_scene="res://scenes/boot/boot.tscn"','run/main_scene="res://scenes/qa/broadcast_qa.tscn"');p.write_text(text)
p=dest/'export_presets.cfg';text=p.read_text().replace('org.nightshiftfm.spike','org.nightshiftfm.broadcastqa').replace('package/name="Nightshift FM"','package/name="Nightshift FM Broadcast QA"').replace('[preset.0]\n','[preset.0]\ncustom_features="qa"\n');p.write_text(text)
engine=os.environ['GODOT_BIN'];evidence=root/'docs/evidence/M8-M10';evidence.mkdir(parents=True,exist_ok=True)
for name,args in [('qa-import',['--import']),('qa-export',['--export-debug','Android Debug',str(root/'builds/android/nightshift-broadcast-qa.apk')])]:
 with (evidence/(name+'.txt')).open('w') as stream:
  subprocess.run([engine,'--headless','--path',str(dest),*args],stdout=stream,stderr=subprocess.STDOUT,check=True)
print(root/'builds/android/nightshift-broadcast-qa.apk')
