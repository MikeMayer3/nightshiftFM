class_name ShieldDefinition
extends ContentDefinition

@export var base_capacity: float = 1.0
@export var recharge_delay: float = 5.0
@export var recharge_rate: float = 3.0
@export var ability_duration: float = 2.5
@export var ability_cooldown: float = 12.0

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if not is_finite(base_capacity) or base_capacity <= 0.0:
		errors.append("base_capacity: must be finite and greater than zero")
	for field: String in ["recharge_delay", "recharge_rate", "ability_duration", "ability_cooldown"]:
		var value: float = get(field)
		if not is_finite(value) or value <= 0.0:
			errors.append(field + ": must be finite and positive")
	return errors
