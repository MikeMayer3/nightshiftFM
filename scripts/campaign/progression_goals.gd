class_name ProgressionGoals
extends RefCounted
## Read-only views of existing rewards. Rendering never awards or saves anything.
static func equipment(profile: CampaignProfile, loadout: Dictionary = {}) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for category: String in ["main", "shield", "support"]:
		for id: String in CampaignContent.options(12, category):
			var requirement: int = 0
			while id not in CampaignContent.options(requirement, category): requirement += 1
			var earned: bool = id in CampaignContent.options(profile.cleared, category)
			rows.append({"id": id, "kind": category, "name": TranslationServer.translate(ArsenalContent.DEFINITIONS[id].name_key),
				"requirement": TranslationServer.translate("P6_STARTER") if requirement == 0 else TranslationServer.translate("P6_CLEAR") % requirement,
				"count": mini(profile.cleared, requirement), "target": requirement,
				"state": "equipped" if earned and loadout.get(category) == id else "earned" if earned else "locked"})
	return rows

static func colors(profile: CampaignProfile) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for family: StringName in ArsenalContent.FAMILIES:
		var available: bool = profile.cosmetic_available(family)
		var requirement: String = TranslationServer.translate("P6_COLOR_REQUIREMENT") % TranslationServer.translate(ArsenalContent.DEFINITIONS[String(family)].name_key)
		if String(family) not in CampaignContent.options(profile.cleared, "support"):
			for row: Dictionary in equipment(profile):
				if row.id == String(family): requirement = row.requirement + " · " + requirement
		rows.append({"id": String(family), "kind": "color", "name": TranslationServer.translate("P6_COLOR") % TranslationServer.translate(ArsenalContent.DEFINITIONS[String(family)].name_key),
			"requirement": requirement, "count": 1 if available else 0, "target": 1,
			"state": "equipped" if profile.cosmetic == family else "earned" if available else "locked"})
	return rows

static func next(profile: MissionProfile) -> Dictionary:
	var nearest: Dictionary = {}
	for row: Dictionary in equipment(profile.campaign):
		if row.state == "locked" and (nearest.is_empty() or row.target < nearest.target): nearest = row
	if not nearest.is_empty(): return nearest
	for row: Dictionary in colors(profile.campaign):
		if row.state == "locked" and row.id in CampaignContent.options(profile.campaign.cleared, "support"): return row
	return {}

static func achievement(profile: AchievementProfile, id: StringName, eligible: bool) -> Dictionary:
	var definition: AchievementDefinition = AchievementCatalog.ALL[id]
	var earned: bool = profile.earned(id)
	var requirement: String = TranslationServer.translate(definition.description_key)
	# User-selected goals remain visible, but never promise progress in practice runs.
	if not definition.available: requirement += "\n" + TranslationServer.translate(definition.pending_key)
	elif not earned and not eligible: requirement += "\n" + TranslationServer.translate("P6_PRACTICE")
	return {"id": String(id), "kind": "title", "name": TranslationServer.translate("P6_TITLE") % TranslationServer.translate(definition.name_key),
		"requirement": requirement, "count": mini(profile.count(id), definition.threshold), "target": definition.threshold,
		"state": "equipped" if profile.title == id else "earned" if earned else "locked"}

static func earned_ids(profile: MissionProfile) -> Array[String]:
	var ids: Array[String] = []
	for row: Dictionary in equipment(profile.campaign) + colors(profile.campaign):
		if row.state != "locked": ids.append(row.kind + ":" + row.id)
	for id: StringName in AchievementCatalog.ALL:
		if profile.achievements.earned(id): ids.append("title:" + String(id))
	return ids

static func newly_earned(profile: MissionProfile, before: Array[String], loadout: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = equipment(profile.campaign, loadout) + colors(profile.campaign)
	for id: StringName in AchievementCatalog.ALL:
		if profile.achievements.earned(id): rows.append(achievement(profile.achievements, id, true))
	var result: Array[Dictionary] = []
	for row: Dictionary in rows:
		if row.state != "locked" and row.kind + ":" + row.id not in before: result.append(row)
	return result
