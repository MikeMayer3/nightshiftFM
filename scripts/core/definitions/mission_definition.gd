class_name MissionDefinition
extends ContentDefinition

@export var wave_ids: Array[StringName] = []
@export var campaign_index: int = 0
@export var prototype: bool = false

func referenced_ids() -> Array[StringName]:
	return wave_ids.duplicate()
