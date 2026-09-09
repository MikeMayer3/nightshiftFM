class_name AchievementProfile
extends RefCounted
## Only an idempotent victory commit updates this profile. Rewards are derived IDs.
var wave_commits: Dictionary = {}
var progress: Dictionary = {}
var collections: Dictionary = {}
var tracked: Array[StringName] = []
var title: StringName = &""

func count(id: StringName) -> int: return int(progress.get(String(id), 0))
func earned(id: StringName) -> bool:
	return AchievementCatalog.ALL.has(id) and count(id) >= AchievementCatalog.ALL[id].threshold

func reward_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in AchievementCatalog.ALL:
		if earned(id): result.append(AchievementCatalog.ALL[id].reward_id)
	return result

func track(id: StringName) -> bool:
	if id in tracked: tracked.erase(id); return true
	if not AchievementCatalog.ALL.has(id) or not AchievementCatalog.ALL[id].available or earned(id) or tracked.size() == 3: return false
	tracked.append(id)
	return true

func select_title(id: StringName) -> bool:
	if id != &"" and not earned(id): return false
	title = id
	return true

func include(key: String, value: String) -> void:
	if not collections.has(key): collections[key] = []
	if value not in collections[key]: collections[key].append(value)

func record_victory(s: CombatSession) -> void:
	var history: AchievementRun = s.achievement_run
	if history == null or not history.eligible or not history.completed or not (EncounterContent.authored(s) or BroadcastRules.expanded(s)) or (s.phase != CombatSession.Phase.VICTORY and not (s.signal_progress is BroadcastProgress and s.phase == CombatSession.Phase.DEFEAT and history.cleared_waves > 0)) or (s.wave != 10 and not s.signal_progress is BroadcastProgress): return
	var maxed: int = 0
	var contributing: int = 0
	for owned: UpgradeTrack in s.draft.tracks:
		if not owned.definition.support: continue
		var family: String = String(owned.definition.id)
		if s.campaign.mode == "campaign": include("supports", family)
		if owned.rank() == 8:
			maxed += 1
			for choice: StringName in owned.choices:
				if s.draft.card(choice).required_rank == 8: include(family, String(choice))
		var output: Dictionary = s.supports.report.totals[family]
		if float(output.damage) + float(output.healing) + float(output.intercepts) + float(output.slow_seconds) + float(output.push_distance) + float(output.interrupts) > 0: contributing += 1
	if s.campaign.mode == "campaign":
		for recipe: StringName in s.patchboard.discovered(): include("recipes", String(recipe))
	var stereo: bool = true
	for id: StringName in s.patchboard.slots:
		if id == &"" or float(s.patchboard.totals[String(id)].triggers) < 10: stereo = false
	var values: Dictionary = {
		"first_broadcast": 1, "patch_cable": int(not s.patchboard.discovered().is_empty()),
		"sound_engineer": collections.get("recipes", []).size(), "stereo": int(stereo),
		"minimalist": int(history.max_supports <= 2), "all_hands": int(s.draft.support_count() == 5 and contributing == 5),
		"soloist_duet": int(maxed >= 2), "variety_show": collections.get("supports", []).size(),
		"deep_focus": int(s.draft.track(&"main").rank() == 8 and s.draft.track(&"shield").rank() == 8),
		"no_scratches": int(history.hull_damage == 0), "unbroken": int(not history.broken),
		"second_wind": int(history.recovered), "close_call": int(s.hull > 0 and s.hull <= s.maximum_hull() * .1),
	}
	for family: String in ArsenalContent.FAMILIES:
		var amount: int = collections.get(family, []).size()
		values[family + "_first_capstone"] = mini(1, amount)
		values[family + "_three_capstones"] = amount
	if BroadcastRules.expanded(s):
		record_waves(s)
		if s.campaign.mode == "campaign":
			include("campaign", str(s.campaign.mission))
			if s.campaign.difficulty >= 1: include("hard", str(s.campaign.mission))
			var cleared: int = 0
			while str(cleared + 1) in collections.get("campaign", []): cleared += 1
			values["new_dials"] = CampaignContent.options(cleared, "main").size()
			values["backup_plans"] = CampaignContent.options(cleared, "shield").size()
			values["blueprint_collector"] = CampaignContent.options(cleared, "modules").size()
			values["signal_archive"] = collections.get("campaign", []).size()
			for region: int in 3:
				var amount: int = 0
				for mission: int in range(region * 4 + 1, region * 4 + 5): amount += int(str(mission) in collections.get("campaign", []))
				values[["local_legend", "deep_signal", "still_on_air"][region]] = amount
			values["full_schedule"] = collections.get("hard", []).size()
			values["overtime"] = int(s.campaign.difficulty == 2 and s.campaign.mission in [4, 8, 12])
			values["hold_the_line"] = int(history.best_activation >= 3)
		elif s.campaign.mode == "contract": values["contract_" + s.campaign.contract] = 1
	for id: String in values:
		var definition: AchievementDefinition = AchievementCatalog.ALL[StringName(id)]
		if StringName(s.campaign.mode) not in definition.eligible_modes or s.campaign.difficulty < definition.minimum_difficulty: continue
		progress[id] = maxi(count(StringName(id)), mini(definition.threshold, int(values[id])))
	tracked = tracked.filter(func(id: StringName) -> bool: return not earned(id))

func to_data() -> Dictionary:
	return {"schema": 2, "wave_commits": wave_commits.duplicate(true), "progress": progress.duplicate(true), "collections": collections.duplicate(true), "tracked": Array(tracked), "title": String(title)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != (6 if data.get("schema") == 2 else 5) or not SaveChecks.number(data.get("schema"), 1, 2, true): return false
	if not data.get("progress") is Dictionary or data.progress.size() > 48 or not data.get("collections") is Dictionary or data.collections.size() > 12: return false
	for id: Variant in data.progress:
		if not id is String or not AchievementCatalog.ALL.has(StringName(id)): return false
		var definition: AchievementDefinition = AchievementCatalog.ALL[StringName(id)]
		if not definition.available or not SaveChecks.number(data.progress[id], 0, definition.threshold, true): return false
	for key: Variant in data.collections:
		if not key is String or not SaveChecks.ids(data.collections[key], 12) or not SaveChecks.unique(data.collections[key]): return false
		var allowed: Array = []
		if key in ["campaign", "hard"]:
			for mission: int in range(1, 13): allowed.append(str(mission))
		elif key == "enemies": allowed = ["m2.swarmer", "m2.diver", "m2.carrier", "m8.plated", "m8.caster", "m8.jammer", "m8.mimic", "m8.mortar"]
		elif key == "bosses": allowed = ["m8.caller", "m8.core", "m8.silence"]
		elif key == "recipes": allowed = PatchboardContent.RECIPES.keys().map(func(id: StringName) -> String: return String(id))
		elif key == "supports": allowed = ArsenalContent.FAMILIES
		elif key in ArsenalContent.FAMILIES:
			for option: UpgradeDefinition in ArsenalContent.DEFINITIONS[key].options:
				if option.required_rank == 8: allowed.append(String(option.id))
		else: return false
		for id: String in data.collections[key]:
			if id not in allowed: return false
	if not SaveChecks.ids(data.get("tracked"), 3) or not SaveChecks.unique(data.tracked) or not data.get("title") is String: return false
	for id: String in data.tracked:
		if not AchievementCatalog.ALL.has(StringName(id)) or not AchievementCatalog.ALL[StringName(id)].available or int(data.progress.get(id, 0)) >= AchievementCatalog.ALL[StringName(id)].threshold: return false
	if data.title != "" and (not AchievementCatalog.ALL.has(StringName(data.title)) or int(data.progress.get(data.title, 0)) < AchievementCatalog.ALL[StringName(data.title)].threshold): return false
	if data.get("schema") == 2:
		if not data.get("wave_commits") is Dictionary or data.wave_commits.size() > 100000: return false
		for key: Variant in data.wave_commits:
			if not key is String or not key.begins_with("run.") or not key.trim_prefix("run.").is_valid_int(): return false
			var row: Variant = data.wave_commits[key]
			if not row is Array or row.size() != 2 or not SaveChecks.number(row[0], 0, 1000, true) or not SaveChecks.number(row[1], 0, 100000, true): return false
		wave_commits = data.wave_commits.duplicate(true)
	progress = data.progress.duplicate(true)
	collections = data.collections.duplicate(true)
	tracked.assign(data.tracked)
	title = StringName(data.title)
	return true

func record_waves(s: CombatSession) -> void:
	var h: AchievementRun = s.achievement_run
	if h == null or not h.expanded or not h.eligible or not BroadcastRules.expanded(s) or h.cleared_waves == 0: return
	var previous: Array = wave_commits.get(String(s.run_id), [0, 0])
	if h.cleared_waves < int(previous[0]): return
	var delta: int = maxi(0, h.reflected - int(previous[1]))
	wave_commits[String(s.run_id)] = [h.cleared_waves, maxi(h.reflected, int(previous[1]))]
	progress["bouncer"] = mini(100, count(&"bouncer") + delta)
	for id: String in h.seen: include("enemies", id)
	for id: String in h.bosses: include("bosses", id)
	progress["know_enemy"] = collections.get("enemies", []).size()
	progress["boss_notebook"] = collections.get("bosses", []).size()
	if s.campaign.mode == "endless":
		for id: StringName in [&"endless_20", &"endless_40", &"endless_60"]:
			progress[String(id)] = maxi(count(id), mini(AchievementCatalog.ALL[id].threshold, h.cleared_waves))
		if h.max_supports <= 3: progress["endless_three"] = maxi(count(&"endless_three"), mini(20, h.cleared_waves))
	tracked = tracked.filter(func(id: StringName) -> bool: return not earned(id))
