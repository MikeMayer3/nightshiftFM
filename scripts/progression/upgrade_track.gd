class_name UpgradeTrack
extends RefCounted
var definition: TrackDefinition
var choices: Array[StringName] = []
var stats: Dictionary = {}

func _init(content: TrackDefinition) -> void:
	definition = content
	stats = content.baseline.duplicate(true)

func rank() -> int:
	return 1 + choices.size()

func eligible(banished: Array[StringName]) -> Array[UpgradeDefinition]:
	var result: Array[UpgradeDefinition] = []
	if rank() >= GameRules.MAX_RANK:
		return result
	var next: int = rank() + 1
	for card: UpgradeDefinition in definition.options:
		if card.target_id != definition.id or card.id in banished or choices.count(card.id) >= card.stack_cap:
			continue
		if (next in [3, 6, 8] and card.required_rank != next) or (next not in [3, 6, 8] and card.required_rank != 0):
			continue
		if card.prerequisite != &"" and card.prerequisite not in choices:
			continue
		var blocked: bool = false
		for exclusion: StringName in card.excludes:
			blocked = blocked or exclusion in choices
		if not blocked and (card.effects.is_empty() or card.required_rank != 0 or _changes_parameters(card)):
			result.append(card)
	return result

func accept(id: StringName, banished: Array[StringName]) -> bool:
	for card: UpgradeDefinition in eligible(banished):
		if card.id == id:
			choices.append(id)
			for key: StringName in card.effects:
				stats[key] = float(stats.get(key, 0)) + float(card.effects[key])
			stats[card.stat] = float(stats.get(card.stat, 0.0)) + card.amount
			if card.second_stat != &"":
				stats[card.second_stat] = float(stats.get(card.second_stat, 0.0)) + card.second_amount
			return true
	return false

func _changes_parameters(card: UpgradeDefinition) -> bool:
	var prospective: UpgradeTrack = UpgradeTrack.new(definition)
	prospective.stats = stats.duplicate(true)
	for key: StringName in card.effects: prospective.stats[key] = float(stats.get(key, 0)) + float(card.effects[key])
	var before: Dictionary = ArsenalStats.parameters(self)
	var after: Dictionary = ArsenalStats.parameters(prospective)
	for key: StringName in after:
		if key in [&"cadence", &"damage_bonus", &"m5_marker"]: continue
		if not is_equal_approx(float(before.get(key, 0)), float(after[key])): return true
	return false
