extends SceneTree
const AIM: Script = preload("res://tests/active_balance.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var results: Array[Dictionary] = []
	var idle: bool = "--idle" in OS.get_cmdline_user_args()
	for main: String in ArsenalContent.MAINS:
		for support: StringName in ArsenalContent.FAMILIES:
			for seed_value: int in ([11] if idle else [1, 11, 42]):
				var s: CombatSession = CombatSession.new()
				var loadout: Dictionary = {"main": main, "shield": ArsenalContent.SHIELDS[seed_value % 3], "support": String(support)}
				s.start_arsenal(seed_value, &"run.1", loadout)
				var policy: RandomNumberGenerator = RandomNumberGenerator.new()
				policy.seed = seed_value + 10000
				for step: int in 2400:
					if s.is_finished(): break
					if s.is_deciding(): s.choose_upgrade(s.draft.offers[policy.randi_range(0, s.draft.offers.size() - 1)])
					else:
						if not idle:
							AIM.aim(s)
							if s.run.shield.current < s.run.shield.capacity * .3: s.activate_shield()
						s.advance(.5)
				var row: Dictionary = {"mode": "idle" if idle else "paced", "loadout": loadout, "seed": seed_value, "victory": s.phase == CombatSession.Phase.VICTORY, "wave": s.wave, "seconds": s.elapsed, "hull": s.hull, "damage_taken": s.damage_taken, "choices": s.draft.normal_count, "bursts": s.active_combat.uses, "pending_peak": s.arsenal.peak_pending, "report": s.arsenal.report.totals, "decisions": s.draft.accepted}
				results.append(row)
				print(JSON.stringify(row.merged({"report": {}, "decisions": []}, true)))
	FileAccess.open("res://docs/evidence/M5/balance-idle.json" if idle else "res://docs/evidence/M5/balance.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t", true, true))
	quit()
