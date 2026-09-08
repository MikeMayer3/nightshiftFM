class_name WaveDefinition
extends ContentDefinition
## Ordered top-band arrivals; no randomized catalog or upgrade schedule.

@export var spawn_interval: float = 1.4
@export var enemy_ids: Array[StringName] = []

func referenced_ids() -> Array[StringName]:
	return enemy_ids.duplicate()

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if not is_finite(spawn_interval) or spawn_interval <= 0.0:
		errors.append("spawn_interval: must be finite and positive")
	return errors
