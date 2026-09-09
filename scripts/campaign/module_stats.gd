class_name ModuleStats
extends RefCounted
## One derivation path for loadout previews, runtime tracks, and restored runs.
static func coefficient(ids: Array[StringName], key: StringName) -> float:
	var value: float = 0
	for id: StringName in ids: value += float(CampaignContent.MODULES[id].effects.get(key, 0))
	return value

static func modify(owned: UpgradeTrack, values: Dictionary) -> void:
	var ids: Array[StringName] = owned.modules
	if ids.is_empty(): return
	var main: bool = owned.definition.id == &"main"
	var shield: bool = owned.definition.id == &"shield"
	if shield:
		for key: StringName in [&"capacity", &"recharge", &"cooldown"]:
			values[key] = float(values[key]) * (1 + coefficient(ids, key))
		values.delay += coefficient(ids, &"delay")
	else:
		values.damage_bonus += coefficient(ids, &"damage")
		if owned.definition.attack_kind == &"direct": values.damage_bonus += coefficient(ids, &"direct_damage")
		if main: values.damage_bonus += coefficient(ids, &"main_damage")
		if values.has(&"terminal"): values.terminal *= damage_multiplier(ids, owned.definition.id)
		values.cadence += coefficient(ids, &"attack_rate")
		if owned.definition.support: values.cadence += coefficient(ids, &"support_rate")
		values.reach *= 1 + coefficient(ids, &"reach")
		for key: StringName in [&"radius", &"width"]:
			if values.has(key) and (key == &"radius" or owned.definition.attack_kind == &"area"):
				values[key] *= 1 + coefficient(ids, &"radius")
		for key: StringName in [&"push", &"pull", &"release"]:
			if values.has(key): values[key] *= 1 + coefficient(ids, &"force")
		if values.has(&"speed"): values.speed *= 1 + coefficient(ids, &"speed")
		if owned.definition.id == &"arc_aerial": values.duration *= 1 + coefficient(ids, &"charged")
		if main: values.crit += coefficient(ids, &"main_crit")

static func maximum_hull(ids: Array[StringName]) -> float:
	return 100 * (1 + coefficient(ids, &"hull"))

static func damage_multiplier(ids: Array[StringName], source: StringName, area: bool = true) -> float:
	return maxf(.1, 1 + coefficient(ids, &"damage") + (coefficient(ids, &"main_damage") if source == &"main" else 0.0) + (0.0 if area else coefficient(ids, &"direct_damage")))

static func area_radius(ids: Array[StringName], radius: float) -> float:
	return radius * (1 + coefficient(ids, &"radius"))
