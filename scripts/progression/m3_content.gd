class_name M3Content
extends RefCounted
const VERSION: String = "m3.1"
const MAIN: TrackDefinition = preload("res://content/tracks/main.tres")
const SHIELD: TrackDefinition = preload("res://content/tracks/shield.tres")
const ARC: TrackDefinition = preload("res://content/tracks/arc_aerial.tres")

static func tracks() -> Array[TrackDefinition]:
	return [MAIN, SHIELD, ARC]

static func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	var ids: Array[StringName] = []
	for definition: TrackDefinition in tracks():
		for option: UpgradeDefinition in definition.options:
			errors.append_array(option.validate())
			if option.id in ids or option.target_id != definition.id:
				errors.append("duplicate or incompatible card: " + String(option.id))
			ids.append(option.id)
			for stat: StringName in [option.stat, option.second_stat]:
				if stat != &"" and not definition.baseline.has(stat):
					errors.append("unsupported effect: " + String(stat))
	return errors
