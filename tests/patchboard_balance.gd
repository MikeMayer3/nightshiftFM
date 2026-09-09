extends SceneTree
const AIM: Script = preload("res://tests/active_balance.gd")
const BUILDS: Array[Dictionary] = [
	{"name": "charge_control", "support": "arc_aerial", "recipes": [&"live_wire", &"ball_lightning"]},
	{"name": "group_repeats", "support": "bass_driver", "recipes": [&"pressure_drop", &"double_drop"]},
	{"name": "marked_replays", "support": "needle_swarm", "recipes": [&"b_side", &"needle_thread"]}]
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var rows: Array[Dictionary] = []
	var passed: bool = true
	for build: Dictionary in BUILDS:
		for main: String in ArsenalContent.MAINS:
			var s: CombatSession = CombatSession.new()
			s.start_patchboard(11, &"run.1", {"main": main, "shield": "feedback", "support": build.support})
			for step: int in 2600:
				if s.is_finished(): break
				if s.is_wiring():
					for index: int in 2:
						if PatchboardState.eligible(s, build.recipes[index]): s.patchboard.rewire(s, index, build.recipes[index])
					s.launch_wave()
				elif s.is_deciding():
					var desired: Array[StringName] = []
					for id: StringName in build.recipes:
						for endpoint: StringName in (PatchboardContent.RECIPES[id] as SynergyDefinition).endpoint_ids:
							if endpoint not in desired: desired.append(endpoint)
					# Use the same legitimate alternate-branch control available in the UI.
					if build.name == "marked_replays": s.swap_branch(&"m5.needle_swarm.b3")
					var selected: StringName = s.draft.offers[0]
					var best: int = -100
					for id: StringName in s.draft.offers:
						var card: UpgradeDefinition = s.draft.card(id)
						var score: int = 0
						if card.target_id in desired: score += 20
						if String(id).begins_with("recruit."): score += 100 if card.target_id in desired else -100
						if card.target_id == &"main": score += 10
						if id == &"m5.needle_swarm.b3": score += 150
						if build.name == "marked_replays" and card.target_id == &"needle_swarm" and s.draft.track(&"needle_swarm").rank() < 3: score += 50
						if score > best:
							best = score
							selected = id
					s.choose_upgrade(selected)
				else:
					AIM.aim(s)
					if s.run.shield.current < s.run.shield.capacity * .3: s.activate_shield()
					s.advance(.5)
			var saved: CombatSession = CombatSession.new()
			var valid: bool = saved.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true)))
			if not s.is_finished() or not valid: passed = false
			var row: Dictionary = {"build": build.name, "main": main, "victory": s.phase == CombatSession.Phase.VICTORY, "wave": s.wave, "seconds": s.elapsed, "hull": s.hull, "choices": s.draft.normal_count, "bursts": s.active_combat.uses, "snapshot_valid": valid, "connections": s.patchboard.to_data(), "decisions": s.draft.accepted}
			rows.append(row)
			print(JSON.stringify(row.merged({"connections": s.patchboard.discovered(), "decisions": []}, true)))
	var file: FileAccess = FileAccess.open("res://docs/evidence/M6/balance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "runs": rows}, "\t", true, true))
	file.close()
	print("RESULT: %d completed-build fixtures; passed=%s" % [rows.size(), passed])
	quit(0 if passed else 1)
