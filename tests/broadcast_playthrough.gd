extends SceneTree
## Legal choices and full simulation, with JSON checkpoint continuation at every draft.
var rows: Array[Dictionary] = []
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var mode: String = args[0] if args.size() > 0 else "campaign"
	var mission: int = int(args[1]) if args.size() > 1 else 4
	var limit: int = int(args[2]) if args.size() > 2 else 20
	var style: String = args[3] if args.size() > 3 else "arc_aerial"
	var contract: String = args[4] if args.size() > 4 else ""
	var main: String = args[5] if args.size() > 5 else "pulse"
	var difficulty: int = int(args[6]) if args.size() > 6 else 0
	var s: CombatSession = CombatSession.new()
	var context: Dictionary = {"mission": mission, "cleared": 12, "modules": [], "mode": mode, "difficulty": difficulty, "contract": contract}
	var valid: bool = s.start_campaign(42, &"run.1", {"main": main, "shield": "capacitor", "support": style}, context)
	var reason: String = ""
	var restores: int = 0
	for step: int in 140000:
		if not valid or s.is_finished(): break
		if s.achievement_run.cleared_waves >= limit and mode == "endless": s.finish_endless(); break
		if s.is_wiring():
			for pair: Array in [[0, &"live_wire"], [1, &"dead_zone"]]:
				if PatchboardState.eligible(s, pair[1]): s.patchboard.rewire(s, pair[0], pair[1])
			s.launch_wave()
		elif s.is_deciding():
			var copy: CombatSession = CombatSession.new()
			if not copy.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))):
				FileAccess.open("res://docs/evidence/M8-M10/" + "failed-checkpoint-%s-%d.json" % [mode, mission], FileAccess.WRITE).store_string(JSON.stringify(s.to_checkpoint(), "\t", true, true))
				valid = false; reason = "checkpoint at wave %d pick %d" % [s.wave, s.draft.normal_count]; break
			s = copy
			restores += 1
			var selected: StringName = s.draft.offers[0]
			var best: int = -100
			for id: StringName in s.draft.offers:
				var option: UpgradeDefinition = s.draft.card(id)
				var score: int = 100 if SignalDraft.is_new(id) else 40 if option.target_id == StringName(style) else 30 if option.target_id == &"main" else 15
				if id == DraftState.REPAIR: score = 100 if s.hull < s.maximum_hull() * .8 else 5
				if score > best: best = score; selected = id
			if not s.choose_upgrade(selected): valid = false; reason = "purchase " + String(selected); break
		else:
			if s.run.shield.current < s.run.shield.capacity * .5: s.activate_shield()
			s.advance(.5)
	var last: CombatSession = CombatSession.new()
	valid = valid and last.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true)))
	var row: Dictionary = {"mode": mode, "mission": mission, "contract": contract, "style": style, "main": main, "difficulty": difficulty, "valid": valid, "reason": reason, "victory": s.phase == CombatSession.Phase.VICTORY, "finished": s.is_finished(), "wave": s.wave, "cleared": s.achievement_run.cleared_waves, "seconds": s.elapsed, "hull": s.hull, "restores": restores, "choices": s.draft.normal_count, "alive": s.actors.size(), "cause": String(s.last_cause)}
	print(JSON.stringify(row))
	FileAccess.open("res://docs/evidence/M8-M10/" + "playthrough-%s-%d-%s-%s-%s-%d.json" % [mode, mission, style, contract, main, difficulty], FileAccess.WRITE).store_string(JSON.stringify(row, "\t"))
	quit(0 if valid and s.is_finished() else 1)
