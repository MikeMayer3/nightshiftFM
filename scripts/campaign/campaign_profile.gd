class_name CampaignProfile
extends RefCounted
## Persistent options and cosmetic records; no mutable combat stats live here.
var cleared: int = 0
var records: Dictionary = {}
var mastery: Dictionary = {}
var presets: Array[Dictionary] = [{}, {}, {}]
var cosmetic: StringName = &"default"
var migrated_presets: bool = false
const MEDALS: Array[String] = ["clear", "no_breach", "intact_hull"]
const EQUIPMENT_ALIASES: Dictionary = {"m2.pulse": "pulse", "m2.capacitor": "capacitor"}

func can_play(mission: int) -> bool:
	return mission >= 1 and mission <= mini(12, cleared + 1)

func save_preset(index: int, loadout: Dictionary, modules: Array[StringName]) -> bool:
	if index not in range(3) or not CampaignContent.valid_selection(loadout, modules, cleared): return false
	presets[index] = {"loadout": loadout.duplicate(), "modules": Array(modules).duplicate()}
	return true

func cosmetic_available(id: StringName) -> bool:
	return id == &"default" or mastery.has(String(id)) and not mastery[String(id)].is_empty()

func record_victory(session: CombatSession) -> void:
	if session.campaign == null or session.campaign.mode != "campaign" or session.phase != CombatSession.Phase.VICTORY or not can_play(session.campaign.mission): return
	var mission: int = session.campaign.mission
	cleared = maxi(cleared, mission)
	var key: String = String(CampaignContent.MISSIONS[mission - 1].id)
	var row: Dictionary = records.get(key, {"medals": [], "best_hull": 0.0, "best_seconds": 10000000.0, "wins": 0})
	for medal: String in MEDALS:
		var earned: bool = medal == "clear" or medal == "no_breach" and session.breaches == 0 or medal == "intact_hull" and is_equal_approx(session.hull, session.maximum_hull())
		if earned and medal not in row.medals: row.medals.append(medal)
	row.best_hull = maxf(float(row.best_hull), session.hull / session.maximum_hull())
	row.best_seconds = minf(float(row.best_seconds), session.elapsed)
	row.wins += 1
	records[key] = row
	for owned: UpgradeTrack in session.draft.tracks:
		if not owned.definition.support or owned.rank() != 8: continue
		var id: String = String(owned.definition.id)
		if not mastery.has(id): mastery[id] = []
		for choice: StringName in owned.choices:
			if session.draft.card(choice).required_rank == 8 and String(choice) not in mastery[id]: mastery[id].append(String(choice))

func to_data() -> Dictionary:
	return {"schema": 1, "cleared": cleared, "records": records.duplicate(true), "mastery": mastery.duplicate(true), "presets": presets.duplicate(true), "cosmetic": String(cosmetic)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6 or data.get("schema") != 1: return false
	if not SaveChecks.number(data.get("cleared"), 0, 12, true): return false
	if not data.get("records") is Dictionary or data.records.size() != int(data.cleared): return false
	for index: int in int(data.cleared):
		var key: String = String(CampaignContent.MISSIONS[index].id)
		var row: Variant = data.records.get(key)
		if not row is Dictionary or row.size() != 4 or not SaveChecks.ids(row.get("medals"), 3) or not SaveChecks.unique(row.medals) or "clear" not in row.medals: return false
		for medal: String in row.medals:
			if medal not in MEDALS: return false
		if not SaveChecks.number(row.get("best_hull"), 0, 1) or not SaveChecks.number(row.get("best_seconds"), 0, 10000000) or not SaveChecks.number(row.get("wins"), 1, 100000, true): return false
	if not data.get("mastery") is Dictionary or data.mastery.size() > 6: return false
	for family: Variant in data.mastery:
		if family not in ArsenalContent.FAMILIES or not SaveChecks.ids(data.mastery[family], 3) or not SaveChecks.unique(data.mastery[family]) or data.mastery[family].is_empty(): return false
		var valid: Array[String] = []
		for card: UpgradeDefinition in ArsenalContent.DEFINITIONS[family].options:
			if card.required_rank == 8: valid.append(String(card.id))
		for capstone: String in data.mastery[family]:
			if capstone not in valid: return false
	if not data.get("presets") is Array or data.presets.size() != 3 or not data.get("cosmetic") is String: return false
	var normalized: Array[Dictionary] = []
	for item: Variant in data.presets:
		if not item is Dictionary: return false
		if item.is_empty(): normalized.append({}); continue
		if item.size() != 2 or not item.get("loadout") is Dictionary or item.loadout.size() != 3 or not SaveChecks.ids(item.get("modules"), 2) or not SaveChecks.unique(item.modules): return false
		var selected: Dictionary = ArsenalContent.DEFAULT.duplicate()
		for category: String in ["main", "shield", "support"]:
			if not item.loadout.get(category) is String: return false
			var id: String = EQUIPMENT_ALIASES.get(item.loadout[category], item.loadout[category])
			if id in CampaignContent.options(int(data.cleared), category): selected[category] = id
		var modules: Array = item.modules.filter(func(id: String) -> bool: return id in CampaignContent.options(int(data.cleared), "modules"))
		var preset: Dictionary = {"loadout": selected, "modules": modules}
		migrated_presets = migrated_presets or preset != item
		normalized.append(preset)
	cleared = int(data.cleared)
	records = data.records.duplicate(true)
	mastery = data.mastery.duplicate(true)
	presets = normalized
	cosmetic = StringName(data.cosmetic)
	if not cosmetic_available(cosmetic): return false
	return true
