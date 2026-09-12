extends SceneTree
## Automated campaign with an unlocked Turntable fixture and JSON resume at each choice.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var s: CombatSession = CombatSession.new()
	var valid: bool = s.start_campaign(42,&"run.1",{"main":"pulse","shield":"capacitor","support":"needle_swarm"},
		{"mission":4,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	var restores: int = 0
	var live_drone_restores: int = 0
	for step: int in 30000:
		if not valid or s.is_finished(): break
		if s.is_deciding():
			if not s.arsenal.needles.is_empty(): live_drone_restores += 1
			var next: CombatSession = CombatSession.new()
			valid = next.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(),"",true,true)))
			if not valid: break
			s = next; restores += 1
			var choice: StringName = s.draft.offers[0]
			for id: StringName in s.draft.offers:
				if s.draft.card(id).target_id == &"needle_swarm": choice = id; break
			valid = s.choose_upgrade(choice)
		else:
			if s.run.shield.current < s.run.shield.capacity * .5: s.activate_shield()
			s.advance(.2)
	var result: Dictionary = {"valid":valid,"finished":s.is_finished(),"victory":s.phase == CombatSession.Phase.VICTORY,
		"wave":s.wave,"restores":restores,"live_drone_restores":live_drone_restores,
		"drone_damage":s.arsenal.report.totals.needle_swarm.damage,"peak_pending":s.arsenal.peak_pending}
	var passed: bool = valid and s.is_finished() and restores > 0 and live_drone_restores > 0 and result.drone_damage > 0
	DirAccess.make_dir_recursive_absolute("res://docs/evidence/note-drones")
	FileAccess.open("res://docs/evidence/note-drones/playthrough.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("RESULT: note drone playthrough %s %s" % ["PASS" if passed else "FAIL",JSON.stringify(result)])
	quit(0 if passed else 1)
