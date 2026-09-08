class_name ContentValidator
extends RefCounted
## M0 checks identity, basic numeric validity, and reference existence only.
## Full compatibility, branch reachability, and unlock cycles require later schemas.

static func validate(definitions: Array[ContentDefinition]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var ids: Dictionary[StringName, bool] = {}
	for index: int in definitions.size():
		var definition: ContentDefinition = definitions[index]
		if definition == null:
			errors.append("entry[%d]: null definition" % index)
			continue
		var label: String = "%s [%s]" % [definition.resource_path, definition.id]
		for error: String in definition.validate():
			errors.append("%s: %s" % [label, error])
		if ids.has(definition.id):
			errors.append("%s: duplicate id" % label)
		ids[definition.id] = true
	for definition: ContentDefinition in definitions:
		if definition == null:
			continue
		for reference: StringName in definition.referenced_ids():
			if reference.is_empty() or not ids.has(reference):
				errors.append("%s [%s]: missing reference '%s'" % [definition.resource_path, definition.id, reference])
	return errors
