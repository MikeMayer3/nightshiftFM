class_name DraftState
extends RefCounted
## Screen quotas count normal screens only. Rerolls retain the allocated tracks.
const REPAIR: StringName = &"consumable.hull"
const REFILL: StringName = &"consumable.shield"
var catalog: Array[TrackDefinition]
var tracks: Array[UpgradeTrack] = []
var random: RunRandom
var offers: Array[StringName] = []
var banished: Array[StringName] = []
var absences: Dictionary = {}
var accepted: Array[Dictionary] = []
var rerolls: int = 2
var banishes: int = 1
var normal_count: int = 0
var bonus_count: int = 0
var bonus: bool = false
var screen_tracks: Array[StringName] = []

func _init(content: Array[TrackDefinition], rngs: RunRandom) -> void:
	catalog = content
	random = rngs

func equip(id: StringName) -> bool:
	if track(id) != null:
		return false
	for definition: TrackDefinition in catalog:
		if definition.id == id:
			if definition.support and support_count() >= GameRules.MAX_SUPPORTS:
				return false
			tracks.append(UpgradeTrack.new(definition))
			absences[String(id)] = 0
			return true
	return false

func support_count() -> int:
	var count: int = 0
	for owned: UpgradeTrack in tracks:
		if owned.definition.support: count += 1
	return count

func track(id: StringName) -> UpgradeTrack:
	for owned: UpgradeTrack in tracks:
		if owned.definition.id == id: return owned
	return null

func card(id: StringName) -> UpgradeDefinition:
	for definition: TrackDefinition in catalog:
		for option: UpgradeDefinition in definition.options:
			if option.id == id: return option
	return null

func begin(is_bonus: bool = false) -> void:
	bonus = is_bonus
	screen_tracks.clear()
	var available: Array[UpgradeTrack] = []
	for owned: UpgradeTrack in tracks:
		if owned.eligible(banished).is_empty():
			absences[String(owned.definition.id)] = 0
		elif not bonus or owned.definition.support:
			available.append(owned)
	if not bonus:
		# Reserve both hard quotas first, then service supports most-overdue-first.
		for owned: UpgradeTrack in available:
			if not owned.definition.support and int(absences[String(owned.definition.id)]) >= 2:
				screen_tracks.append(owned.definition.id)
		var overdue: Array[UpgradeTrack] = available.filter(func(t: UpgradeTrack) -> bool:
			return t.definition.support and int(absences[String(t.definition.id)]) >= 4)
		overdue.sort_custom(func(a: UpgradeTrack, b: UpgradeTrack) -> bool:
			return int(absences[String(a.definition.id)]) > int(absences[String(b.definition.id)]))
		for owned: UpgradeTrack in overdue:
			if screen_tracks.size() < 3: screen_tracks.append(owned.definition.id)
	var pool: Array[UpgradeTrack] = available.filter(func(t: UpgradeTrack) -> bool: return t.definition.id not in screen_tracks)
	while screen_tracks.size() < 3 and not pool.is_empty():
		var index: int = random.rng("draft").randi_range(0, pool.size() - 1)
		screen_tracks.append(pool[index].definition.id)
		pool.remove_at(index)
	if not bonus:
		for owned: UpgradeTrack in available:
			var id: String = String(owned.definition.id)
			absences[id] = 0 if owned.definition.id in screen_tracks else int(absences[id]) + 1
	_generate([])

func _generate(previous: Array[StringName]) -> void:
	offers.clear()
	for id: StringName in screen_tracks:
		var options: Array[UpgradeDefinition] = track(id).eligible(banished)
		if options.is_empty(): continue
		var fresh: Array[UpgradeDefinition] = options.filter(func(c: UpgradeDefinition) -> bool: return c.id not in previous)
		if not fresh.is_empty(): options = fresh
		offers.append(options[random.rng("draft").randi_range(0, options.size() - 1)].id)
	var remaining: Array[StringName] = []
	for id: StringName in screen_tracks:
		for option: UpgradeDefinition in track(id).eligible(banished):
			if option.id not in offers: remaining.append(option.id)
	while offers.size() < 3 and not remaining.is_empty():
		var index: int = random.rng("draft").randi_range(0, remaining.size() - 1)
		offers.append(remaining[index])
		remaining.remove_at(index)
	if offers.is_empty(): offers.assign([REPAIR, REFILL])

func reroll() -> bool:
	if rerolls <= 0 or offers.is_empty() or offers[0] in [REPAIR, REFILL]: return false
	var previous: Array[StringName] = offers.duplicate()
	rerolls -= 1
	_generate(previous)
	return true

func banish(id: StringName) -> bool:
	var option: UpgradeDefinition = card(id)
	if banishes <= 0 or id not in offers or option == null or option.required_rank != 0:
		return false
	# Never erase the final common needed to reach a required branch.
	var owned: UpgradeTrack = track(option.target_id)
	var next_bans: Array[StringName] = banished.duplicate()
	next_bans.append(id)
	if owned.eligible(next_bans).is_empty(): return false
	banishes -= 1
	banished.append(id)
	_generate(offers.duplicate())
	return true

func choose(id: StringName) -> bool:
	if id not in offers: return false
	if id not in [REPAIR, REFILL]:
		var option: UpgradeDefinition = card(id)
		if option == null or not track(option.target_id).accept(id, banished): return false
	accepted.append({"id": String(id), "bonus": bonus})
	if bonus: bonus_count += 1
	else: normal_count += 1
	offers.clear()
	screen_tracks.clear()
	return true

func to_data() -> Dictionary:
	var equipment: Array[Dictionary] = []
	for owned: UpgradeTrack in tracks:
		equipment.append({"id": String(owned.definition.id), "choices": Array(owned.choices)})
	return {"tracks": equipment, "offers": Array(offers), "banished": Array(banished),
		"absences": absences.duplicate(), "accepted": accepted.duplicate(true),
		"rerolls": rerolls, "banishes": banishes, "normal_count": normal_count,
		"bonus_count": bonus_count, "bonus": bonus, "screen_tracks": Array(screen_tracks)}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 11: return false
	if not data.get("tracks") is Array or data.tracks.size() < 3 or data.tracks.size() > 7: return false
	for field: String in ["offers", "banished", "screen_tracks"]:
		if not SaveChecks.ids(data.get(field), 3): return false
		if not SaveChecks.unique(data[field]): return false
	for field: String in ["rerolls", "banishes", "normal_count", "bonus_count"]:
		if not SaveChecks.number(data.get(field), 0, 27, true): return false
	if data.rerolls > 2 or data.banishes > 1 or data.bonus_count > 4: return false
	if not data.get("bonus") is bool or not data.get("accepted") is Array or data.accepted.size() > 31: return false
	if not data.get("absences") is Dictionary or data.absences.size() != data.tracks.size(): return false
	tracks.clear()
	for item: Variant in data.tracks:
		if not item is Dictionary or item.size() != 2 or not item.get("id") is String or not SaveChecks.ids(item.get("choices"), 7): return false
		if not equip(StringName(item.id)): return false
		var owned: UpgradeTrack = track(StringName(item.id))
		for id: String in item.choices:
			if not owned.accept(StringName(id), []): return false
		if not SaveChecks.number(data.absences.get(item.id), 0, 27, true): return false
	if track(&"main") == null or track(&"shield") == null or track(&"arc_aerial") == null: return false
	banished.assign(data.banished)
	for id: StringName in banished:
		if card(id) == null or card(id).required_rank != 0: return false
	if banished.size() + int(data.banishes) != 1: return false
	var counted_normal: int = 0
	var counted_bonus: int = 0
	var histories: Dictionary = {}
	for owned: UpgradeTrack in tracks: histories[String(owned.definition.id)] = []
	for record: Variant in data.accepted:
		if not record is Dictionary or record.size() != 2 or not record.get("id") is String or not record.get("bonus") is bool: return false
		var id: StringName = StringName(record.id)
		if record.bonus: counted_bonus += 1
		else: counted_normal += 1
		if id not in [REPAIR, REFILL]:
			var option: UpgradeDefinition = card(id)
			if option == null or track(option.target_id) == null: return false
			if record.bonus and not track(option.target_id).definition.support: return false
			histories[String(option.target_id)].append(String(id))
	for owned: UpgradeTrack in tracks:
		if PackedStringArray(owned.choices) != PackedStringArray(histories[String(owned.definition.id)]): return false
	if counted_normal != int(data.normal_count) or counted_bonus != int(data.bonus_count): return false
	bonus = data.bonus
	offers.assign(data.offers)
	screen_tracks.assign(data.screen_tracks)
	for id: StringName in screen_tracks:
		if track(id) == null or (bonus and not track(id).definition.support): return false
	for id: StringName in offers:
		if id in [REPAIR, REFILL]:
			for owned: UpgradeTrack in tracks:
				if (not bonus or owned.definition.support) and not owned.eligible(banished).is_empty(): return false
		else:
			var option: UpgradeDefinition = card(id)
			if option == null or option.target_id not in screen_tracks: return false
			if option not in track(option.target_id).eligible(banished): return false
	absences.clear()
	for key: String in data.absences: absences[key] = int(data.absences[key])
	accepted.assign(data.accepted.duplicate(true))
	rerolls = int(data.rerolls)
	banishes = int(data.banishes)
	normal_count = int(data.normal_count)
	bonus_count = int(data.bonus_count)
	return true
