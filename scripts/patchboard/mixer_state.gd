class_name MixerState
extends RefCounted
## Explicit run-local allocations. Existing projectiles keep their captured mix.
const CHANNELS: Array[String] = ["direct", "area", "control"]
const LIMIT: int = 4
var levels: Array[int] = [0, 0, 0]

static func budget(cleared: int) -> int:
	return 7 if cleared >= 12 else 5 if cleared >= 4 else 3

func spent() -> int:
	return levels[0] + levels[1] + levels[2]

func restore(data: Variant, points: int) -> bool:
	if not data is Array or data.size() != 3: return false
	var total: int = 0
	for value: Variant in data:
		if not SaveChecks.number(value, 0, LIMIT, true): return false
		total += int(value)
	if total > points: return false
	levels.assign(data)
	return true

func adjust(session: CombatSession, channel: int, value: int) -> bool:
	if not session.paused or session.is_finished() or not BroadcastRules.expanded(session): return false
	if channel < 0 or channel >= 3: return false
	var proposed: Array[int] = levels.duplicate()
	proposed[channel] = value
	if not restore(proposed, budget(session.campaign.cleared)): return false
	session.checkpoint_changed.emit()
	return true

func modify(owned: UpgradeTrack, values: Dictionary) -> void:
	if owned.definition.id == &"shield": return
	var area: bool = owned.definition.attack_kind == &"area"
	var gain: float = 1 + levels[1] * .08 if area else 1 + levels[0] * .10
	if gain > 1:
		values.damage = minf(300, float(values.damage) * gain)
		if values.has(&"terminal"): values.terminal = minf(1000, float(values.terminal) * gain)
	if area and levels[1] > 0:
		for key: StringName in [&"radius", &"width"]:
			if values.has(key): values[key] = minf(400 if key == &"radius" else 250, float(values[key]) * (1 + levels[1] * .06))
	if levels[2] > 0:
		for key: StringName in [&"slow", &"push", &"pull", &"jam", &"release"]:
			if values.has(key):
				var ceiling: float = float(ArsenalRuntime.BOUNDS[key][1]) if ArsenalRuntime.BOUNDS.has(key) else 1000.0
				values[key] = minf(ceiling, float(values[key]) * (1 + levels[2] * .12))
