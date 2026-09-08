class_name MissionDefinition
extends ContentDefinition

@export var wave_ids: Array[StringName] = []

func referenced_ids() -> Array[StringName]:
	return wave_ids.duplicate()
