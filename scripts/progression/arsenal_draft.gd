class_name ArsenalDraft
extends SignalDraft
## Offensive choices and acquisitions share one earned pick; no shield quota or wave schedule.

var reroll_limit: int = 2
var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()

func to_data() -> Dictionary:
	var data: Dictionary = super.to_data()
	data["loadout"] = loadout.duplicate()
	return data

func pool() -> Array[StringName]:
	var ids: Array[StringName] = []
	for definition: TrackDefinition in catalog:
		if definition.id == &"shield" and normal_count % 4 != 3: continue
		var owned: UpgradeTrack = track(definition.id)
		if owned == null:
			if definition.support and support_count() < GameRules.MAX_SUPPORTS:
				ids.append(StringName("recruit." + String(definition.id)))
		else:
			for option: UpgradeDefinition in owned.eligible(banished): ids.append(option.id)
	if ids.is_empty(): ids.append(OVERDRIVE)
	return ids

func begin(_is_bonus: bool = false) -> void:
	bonus = false
	_generate([])

func _generate(previous: Array[StringName]) -> void:
	offers.clear()
	screen_tracks.clear()
	var available: Array[StringName] = pool()
	var fresh: Array[StringName] = available.filter(func(id: StringName) -> bool: return id not in previous)
	# Keep a new weapon visible while one is available, without forcing its purchase.
	var recruits: Array[StringName] = fresh.filter(func(id: StringName) -> bool: return is_new(id))
	if recruits.is_empty(): recruits = available.filter(func(id: StringName) -> bool: return is_new(id))
	if not recruits.is_empty():
		var pick: StringName = recruits[random.rng("draft").randi_range(0, recruits.size() - 1)]
		offers.append(pick)
		screen_tracks.append(card(pick).target_id)
		available.erase(pick)
		fresh.erase(pick)
	if normal_count % 4 == 3:
		var shields: Array[StringName] = available.filter(func(id: StringName) -> bool: return card(id).target_id == &"shield")
		if not shields.is_empty():
			var pick: StringName = shields[random.rng("draft").randi_range(0, shields.size() - 1)]
			offers.append(pick)
			screen_tracks.append(&"shield")
			available.erase(pick)
			fresh.erase(pick)
	while offers.size() < 3 and not available.is_empty():
		var options: Array[StringName] = fresh.filter(func(id: StringName) -> bool: return card(id).target_id not in screen_tracks and not is_new(id))
		if options.is_empty(): options = available.filter(func(id: StringName) -> bool: return card(id).target_id not in screen_tracks and not is_new(id))
		if options.is_empty(): options = fresh if not fresh.is_empty() else available
		var pick: StringName = options[random.rng("draft").randi_range(0, options.size() - 1)]
		offers.append(pick)
		if card(pick).target_id not in screen_tracks: screen_tracks.append(card(pick).target_id)
		available.erase(pick)
		fresh.erase(pick)

func _purchase(id: StringName) -> bool:
	if id == OVERDRIVE: return true
	if is_new(id):
		var family: StringName = StringName(String(id).trim_prefix("recruit."))
		return family in ArsenalContent.FAMILIES and equip(family)
	var option: UpgradeDefinition = card(id)
	if option != null and option.target_id == &"shield" and normal_count % 4 != 3: return false
	return option != null and track(option.target_id) != null and track(option.target_id).accept(id, [])

func choose(id: StringName) -> bool:
	if id not in offers or not _purchase(id): return false
	accepted.append({"id": String(id), "bonus": false})
	normal_count += 1
	offers.clear()
	screen_tracks.clear()
	return true

func reroll() -> bool:
	if rerolls <= 0 or offers.is_empty() or offers[0] == OVERDRIVE: return false
	var previous: Array[StringName] = offers.duplicate()
	rerolls -= 1
	_generate(previous)
	return true

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 12: return false
	if not ArsenalContent.valid_loadout(data.get("loadout")) or data.loadout != loadout: return false
	if data.get("bonus") != false or data.get("bonus_count") != 0: return false
	if not SaveChecks.number(data.get("normal_count"), 0, 1000, true): return false
	if not data.get("accepted") is Array or data.accepted.size() != int(data.normal_count): return false
	if not SaveChecks.number(data.get("rerolls"), 0, reroll_limit, true) or not SaveChecks.number(data.get("banishes"), 0, 1, true): return false
	for key: String in ["offers", "banished", "screen_tracks"]:
		if not SaveChecks.ids(data.get(key), 3) or not SaveChecks.unique(data[key]): return false
	if data.banished.size() + int(data.banishes) != 1: return false
	tracks.clear()
	absences.clear()
	offers.clear()
	banished.assign(data.banished)
	for id: StringName in [&"main", &"shield", StringName(loadout.support)]: equip(id)
	normal_count = 0
	for record: Variant in data.accepted:
		if not record is Dictionary or record.size() != 2 or record.get("bonus") != false or not record.get("id") is String: return false
		# Overdrive is legal only once all normal offensive options are exhausted.
		if record.id == String(OVERDRIVE) and pool() != [OVERDRIVE]: return false
		if not _purchase(StringName(record.id)): return false
		normal_count += 1
	if not data.get("tracks") is Array or data.tracks.size() != tracks.size(): return false
	for index: int in tracks.size():
		var item: Variant = data.tracks[index]
		if not item is Dictionary or item.size() != 2 or item.get("id") != String(tracks[index].definition.id): return false
		if not SaveChecks.ids(item.get("choices"), 7) or PackedStringArray(item.choices) != PackedStringArray(tracks[index].choices): return false
	if not data.get("absences") is Dictionary or data.absences.size() != tracks.size(): return false
	for owned: UpgradeTrack in tracks:
		if data.absences.get(String(owned.definition.id)) != 0: return false
	banished.assign(data.banished)
	for id: StringName in banished:
		var option: UpgradeDefinition = super.card(id)
		if option == null or option.required_rank != 0: return false
	var valid_pool: Array[StringName] = pool()
	for id: String in data.offers:
		if StringName(id) not in valid_pool: return false
	offers.assign(data.offers)
	screen_tracks.assign(data.screen_tracks)
	for id: StringName in offers:
		if card(id).target_id not in screen_tracks: return false
	for id: StringName in screen_tracks:
		if not offers.any(func(offer: StringName) -> bool: return card(offer).target_id == id): return false
	accepted.assign(data.accepted.duplicate(true))
	normal_count = int(data.normal_count)
	bonus_count = 0
	bonus = false
	rerolls = int(data.rerolls)
	banishes = int(data.banishes)
	return true
