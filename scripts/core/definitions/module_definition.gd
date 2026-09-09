class_name ModuleDefinition
extends ContentDefinition
## Immutable, bounded pre-mission sidegrades.
@export var unlock_mission: int = 4
@export var effects: Dictionary = {}
const KEYS: Array[StringName] = [&"attack_rate", &"recharge", &"reach", &"hull", &"capacity", &"cooldown", &"damage", &"delay", &"support_rate", &"radius", &"direct_damage", &"force", &"speed", &"charged", &"rerolls", &"main_damage", &"main_crit"]

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if unlock_mission < 4 or unlock_mission > 12: errors.append("unlock_mission: expected 4–12")
	if effects.size() != 2: errors.append("effects: exactly one benefit and one cost required")
	var benefits: int = 0
	var costs: int = 0
	for key: Variant in effects:
		if key not in KEYS or not effects[key] is float and not effects[key] is int or not is_finite(float(effects[key])) or absf(float(effects[key])) > 1:
			errors.append("effects: invalid bounded coefficient")
			continue
		var signed: float = float(effects[key]) * (-1 if key in [&"cooldown", &"delay"] else 1)
		if signed > 0: benefits += 1
		if signed < 0: costs += 1
	if benefits != 1 or costs != 1: errors.append("effects: one actual benefit and one actual cost required")
	return errors
