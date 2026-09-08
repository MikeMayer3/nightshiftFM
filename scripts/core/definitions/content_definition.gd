class_name ContentDefinition
extends Resource
## Authoring data only. Treat loaded definitions as immutable; never store run state here.
## Godot Resources are mutable by API, so this is an ownership contract, not a freeze API.

@export var id: StringName = &""
@export var name_key: StringName = &""
@export var description_key: StringName = &""
@export var schema_version: int = 1

func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if id.is_empty():
		errors.append("id: required stable ID is empty")
	else:
		for character: String in String(id):
			if not character in "abcdefghijklmnopqrstuvwxyz0123456789_.":
				errors.append("id: use lowercase ASCII letters, digits, underscore, or dot")
				break
	if name_key.is_empty():
		errors.append("name_key: required localization key is empty")
	if description_key.is_empty():
		errors.append("description_key: required localization key is empty")
	if schema_version != 1:
		errors.append("schema_version: unsupported version %d" % schema_version)
	return errors

func referenced_ids() -> Array[StringName]:
	return []
