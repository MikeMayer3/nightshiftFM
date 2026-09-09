class_name BroadcastDraft
extends ArsenalDraft
## New-mode constraints are enforced on both offers and reconstructed purchases.
const DECLINE: StringName = &"consumable.decline"
var context: CampaignRun

static func endless_recruit(index: int) -> bool:
	var cursor: int = 0
	for wave: int in range(1, 1001):
		cursor += 3 if wave <= 10 else 1
		if wave + 1 in [2, 4, 6, 8, 12, 16]:
			if index == cursor: return true
			cursor += 1
		if index < cursor: return false
	return false

static func endless_credits(wave: int) -> int:
	var result: int = mini(wave, 10) * 3 + maxi(0, wave - 10)
	for window: int in [2, 4, 6, 8, 12, 16]:
		if window <= wave + 1: result += 1
	return result

func equip(id: StringName) -> bool:
	if context != null and id in ArsenalContent.FAMILIES and support_count() >= BroadcastRules.support_limit(context): return false
	return super.equip(id)

func card(id: StringName) -> UpgradeDefinition:
	if id in [REPAIR, REFILL, DECLINE]:
		var result: UpgradeDefinition = UpgradeDefinition.new()
		result.id = id
		result.target_id = &"shield" if id == REFILL else &"main"
		result.name_key = &"BROADCAST_REFILL" if id == REFILL else &"BROADCAST_REPAIR" if id == REPAIR else &"BROADCAST_DECLINE"
		result.description_key = StringName(String(result.name_key) + "_DESC")
		result.required_rank = -1
		return result
	return super.card(id)

func pool() -> Array[StringName]:
	var result: Array[StringName] = []
	var recruitment: bool = context.mode == "endless" and endless_recruit(normal_count)
	for definition: TrackDefinition in catalog:
		var owned: UpgradeTrack = track(definition.id)
		if owned == null:
			if definition.support and support_count() < BroadcastRules.support_limit(context) and (context.mode != "endless" or recruitment): result.append(StringName("recruit." + String(definition.id)))
		elif not recruitment:
			if context.mode != "endless" and definition.id == &"shield" and normal_count % 4 != 3: continue
			for option: UpgradeDefinition in owned.eligible(banished):
				if context.contract == "no_repeats" and accepted.any(func(row: Dictionary) -> bool: return row.id == String(option.id)): continue
				result.append(option.id)
	if recruitment: result.append(DECLINE)
	elif result.is_empty(): result.assign([REPAIR, REFILL])
	return result

func _purchase(id: StringName) -> bool:
	var recruitment: bool = context.mode == "endless" and endless_recruit(normal_count)
	if recruitment and id != DECLINE and not is_new(id): return false
	if id == DECLINE: return recruitment
	if id in [REPAIR, REFILL]: return pool() == [REPAIR, REFILL]
	if id == OVERDRIVE: return false
	if is_new(id):
		if context.mode == "endless" and not recruitment: return false
		return equip(StringName(String(id).trim_prefix("recruit.")))
	var option: UpgradeDefinition = card(id)
	if option == null or track(option.target_id) == null: return false
	if context.mode != "endless" and option.target_id == &"shield" and normal_count % 4 != 3: return false
	return track(option.target_id).accept(id, [])

func restore(data: Variant) -> bool:
	if context.contract == "no_repeats" and data is Dictionary and data.get("accepted") is Array:
		var used: Array[String] = []
		for row: Variant in data.accepted:
			if not row is Dictionary or not row.get("id") is String: return false
			if not row.id.begins_with("consumable."):
				if row.id in used: return false
				used.append(row.id)
	return super.restore(data)

func choose(id: StringName) -> bool:
	if id not in pool(): return false
	return super.choose(id)
