class_name SynergyDefinition
extends ContentDefinition
## Event conditions and bounded generation policies are deferred to their milestone.

@export var endpoint_ids: Array[StringName] = []

func referenced_ids() -> Array[StringName]:
	return endpoint_ids.duplicate()
