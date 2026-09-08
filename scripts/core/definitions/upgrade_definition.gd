class_name UpgradeDefinition
extends ContentDefinition
## Immutable authored option. Effects modify only a reconstructed runtime track.
@export var effects: Dictionary = {} # M5 additive parameters; legacy options leave empty.
@export var target_id: StringName = &""
@export var required_rank: int = 0 # 0 = common ranks 2/4/5/7
@export var prerequisite: StringName = &""
@export var excludes: Array[StringName] = []
@export var stack_cap: int = 3
@export var stat: StringName = &"damage"
@export var amount: float = 0.0
@export var second_stat: StringName = &""
@export var second_amount: float = 0.0

func referenced_ids() -> Array[StringName]:
	return [target_id]

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if required_rank not in [0, 3, 6, 8] or stack_cap < 1 or stack_cap > 4:
		errors.append("rank/stack_cap: invalid upgrade grammar")
	if not is_finite(amount) or not is_finite(second_amount):
		errors.append("effects: must be finite")
	for key: Variant in effects:
		if not (key is StringName or key is String) or not (effects[key] is float or effects[key] is int) or not is_finite(float(effects[key])):
			errors.append("effects: must have named finite numeric parameters")
	return errors
