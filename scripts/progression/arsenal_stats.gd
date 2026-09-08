class_name ArsenalStats
extends RefCounted
## Derived, bounded parameters shared by combat and comparison previews.
static func parameters(owned: UpgradeTrack) -> Dictionary:
	var result: Dictionary = owned.stats.duplicate(true)
	result.damage = float(result.damage) * maxf(.1, 1 + float(result.damage_bonus))
	result.interval = maxf(.08, float(result.interval) / maxf(.3, 1 + float(result.cadence)))
	result.crit = clampf(float(result.crit), 0, .5)
	result.duration = clampf(float(result.duration), .5, 10)
	result.reach = clampf(float(result.reach), 40, 1000)
	result.width = clampf(float(result.width), 4, 250)
	result.targets = clampi(int(result.targets), 1, 12)
	result.pierce = clampi(int(result.pierce), 0, 10)
	for key: StringName in [&"copies", &"projectiles", &"attacks"]:
		if result.has(key): result[key] = clampi(int(result[key]), 1, 12)
	if result.has(&"delay"): result[&"delay"] = maxf(.08, float(result[&"delay"]))
	if result.has(&"cooldown"): result[&"cooldown"] = maxf(3, float(result[&"cooldown"]))
	if result.has(&"capacity"): result[&"capacity"] = maxf(10, float(result[&"capacity"]))
	return result
