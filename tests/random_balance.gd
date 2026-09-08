extends SceneTree
## Uniform offers, independent decision RNG; no rerolls or preferred weapon families.
const AIM = preload("res://tests/active_balance.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var results: Array[Dictionary] = []
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var first_seed: int = int(arguments[1]) if arguments.size() > 1 else 1
	var end_seed: int = int(arguments[2]) if arguments.size() > 2 else 31
	for seed_value: int in range(first_seed, end_seed):
		for mode: String in ["aimed", "paced", "idle"]:
			var value: CombatSession = CombatSession.new()
			value.start_active(seed_value, &"run.1")
			if "legacy" in arguments: value.active_combat.content_version = ActiveCombat.LEGACY_VERSION
			var policy: RandomNumberGenerator = RandomNumberGenerator.new()
			policy.seed = seed_value + 10000
			var decisions: Array[Dictionary] = []
			for step: int in 15000:
				if value.is_finished(): break
				if value.is_deciding():
					var index: int = policy.randi_range(0, value.draft.offers.size() - 1)
					var id: StringName = value.draft.offers[index]
					decisions.append({"id": String(id), "index": index, "offers": value.draft.offers.duplicate(), "wave": value.wave, "seconds": value.elapsed})
					if not value.choose_upgrade(id): quit(1); return
				else:
					if mode == "aimed" or (mode == "paced" and step % 5 == 0): AIM.aim(value)
					value.advance(0.1)
			var row: Dictionary = {"seed": seed_value, "mode": mode, "victory": value.phase == CombatSession.Phase.VICTORY, "wave": value.wave, "seconds": value.elapsed, "hull": value.hull, "damage_taken": value.damage_taken, "kills": value.kills, "bursts": value.active_combat.uses, "decisions": decisions}
			results.append(row)
			print(JSON.stringify(row.merged({"decisions": decisions.size()}, true)))
	var filename: String = "random-balance"
	if not OS.get_cmdline_user_args().is_empty(): filename = OS.get_cmdline_user_args()[0]
	FileAccess.open("res://docs/evidence/M4-turrets/" + filename + ".json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	quit(0)
