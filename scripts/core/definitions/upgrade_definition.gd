class_name UpgradeDefinition
extends ContentDefinition
## Identity/reference skeleton only; no exposed upgrade cards or effects in M0.

@export var target_id: StringName = &""

func referenced_ids() -> Array[StringName]:
	return [target_id]
