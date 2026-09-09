class_name AchievementProfile
extends RefCounted
## Only an idempotent victory commit updates this profile. Rewards are derived IDs.
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
	if history == null or not history.eligible or not history.completed or not EncounterContent.authored(s) or s.phase != CombatSession.Phase.VICTORY or s.wave != 10: return
	var maxed: int = 0
	var contributing: int = 0
	for owned: UpgradeTrack in s.draft.tracks:
		if not owned.definition.support: continue
		var family: String = String(owned.definition.id)
		include("supports", family)
		if owned.rank() == 8:
			maxed += 1
			for choice: StringName in owned.choices:
				if s.draft.card(choice).required_rank == 8: include(family, String(choice))
		var output: Dictionary = s.supports.report.totals[family]
		if float(output.damage) + float(output.healing) + float(output.intercepts) + float(output.slow_seconds) + float(output.push_distance) + float(output.interrupts) > 0: contributing += 1
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
	for id: String in values:
		var definition: AchievementDefinition = AchievementCatalog.ALL[StringName(id)]
		progress[id] = maxi(count(StringName(id)), mini(definition.threshold, int(values[id])))
	tracked = tracked.filter(func(id: StringName) -> bool: return not earned(id))

func to_data() -> Dictionary:
	return {"schema": 1, "progress": progress.duplicate(true), "collections": collections.duplicate(true), "tracked": Array(tracked), "title": String(title)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5 or data.get("schema") != 1: return false
	if not data.get("progress") is Dictionary or data.progress.size() > 48 or not data.get("collections") is Dictionary or data.collections.size() > 8: return false
	for id: Variant in data.progress:
		if not id is String or not AchievementCatalog.ALL.has(StringName(id)): return false
		var definition: AchievementDefinition = AchievementCatalog.ALL[StringName(id)]
		if not definition.available or not SaveChecks.number(data.progress[id], 0, definition.threshold, true): return false
	for key: Variant in data.collections:
		if not key is String or not SaveChecks.ids(data.collections[key], 8) or not SaveChecks.unique(data.collections[key]): return false
		var allowed: Array = []
		if key == "recipes": allowed = PatchboardContent.RECIPES.keys().map(func(id: StringName) -> String: return String(id))
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
	progress = data.progress.duplicate(true)
	collections = data.collections.duplicate(true)
	tracked.assign(data.tracked)
	title = StringName(data.title)
	return true
