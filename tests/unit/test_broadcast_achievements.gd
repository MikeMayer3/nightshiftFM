extends RefCounted
const LEGACY: Array[StringName] = [&"first_broadcast", &"patch_cable", &"sound_engineer", &"stereo", &"minimalist", &"all_hands", &"soloist_duet", &"variety_show", &"deep_focus", &"no_scratches", &"unbroken", &"second_wind", &"close_call"]
static func fixture(id: StringName, positive: bool) -> AchievementProfile:
	var p: AchievementProfile = AchievementProfile.new()
	var s: CombatSession = CombatSession.new()
	var context: Dictionary = {"mission": 1, "cleared": 12, "modules": [], "mode": "campaign", "difficulty": 0, "contract": ""}
	if String(id).begins_with("contract_"):
		if positive: context.mode = "contract"; context.contract = String(id).trim_prefix("contract_")
	elif String(id).begins_with("endless_"): context.mode = "endless"
	elif id == &"full_schedule": context.mission = 12; context.difficulty = 1 if positive else 0
	elif id == &"overtime": context.mission = 4; context.difficulty = 2 if positive else 1
	elif id in [&"local_legend", &"deep_signal", &"still_on_air"]: context.mission = [4, 8, 12][[&"local_legend", &"deep_signal", &"still_on_air"].find(id)] if positive else 1
	elif id == &"new_dials": context.mission = 6 if positive else 5
	elif id == &"backup_plans": context.mission = 8 if positive else 7
	elif id == &"signal_archive": context.mission = 12 if positive else 11
	s.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, context)
	var h: AchievementRun = s.achievement_run
	h.eligible = true # Isolated evaluator fixture; never written to the player's save.
	h.cleared_waves = 10
	s.wave = 10
	if id in [&"local_legend", &"deep_signal", &"still_on_air"]:
		var start: int = {&"local_legend": 1, &"deep_signal": 5, &"still_on_air": 9}[id]
		for mission: int in range(start, start + 3): p.include("campaign", str(mission))
	if id in [&"new_dials", &"backup_plans", &"signal_archive"]:
		for mission: int in range(1, context.mission): p.include("campaign", str(mission))
	if id == &"full_schedule":
		for mission: int in range(1, 12): p.include("hard", str(mission))
	if id == &"bouncer": h.reflected = 100 if positive else 99
	if id == &"hold_the_line": h.best_activation = 3 if positive else 2
	if id == &"blueprint_collector": h.eligible = positive
	if id == &"know_enemy":
		h.seen.assign(["m2.swarmer", "m2.diver", "m2.carrier", "m8.plated", "m8.caster", "m8.jammer", "m8.mimic"])
		if positive: h.seen.append("m8.mortar")
	if id == &"boss_notebook":
		h.bosses.assign(["m8.caller", "m8.core"])
		if positive: h.bosses.append("m8.silence")
	if String(id).begins_with("endless_"):
		h.cleared_waves = AchievementCatalog.ALL[id].threshold - (0 if positive else 1)
		s.wave = h.cleared_waves
		if id == &"endless_three": h.cleared_waves = 20; h.max_supports = 3 if positive else 4
	s._finish(true)
	p.record_waves(s)
	p.record_victory(s)
	return p
