class_name PatchboardState
extends RefCounted
## M6 selection foundation. No combat listeners, effects, or persistent unlock writes.
## Callers supply an authored catalog and authoritative equipped endpoint roles.
## Main/shield chassis resolve to the roles "main" and "shield" at the adapter boundary.

const MAX_CONNECTIONS: int = 2
const MAX_RECIPES: int = 8
const SCHEMA_VERSION: int = 1
const SUPPORT_IDS: Array[StringName] = [
	&"arc_aerial", &"bass_driver", &"static_net",
	&"echo_deck", &"needle_swarm", &"reverb_well",
]
const ROLE_IDS: Array[StringName] = [&"main", &"shield"]

var _catalog: Dictionary = {}
var _active: Array[StringName] = []
var _configured: bool = false

func configure(definitions: Array[SynergyDefinition]) -> PackedStringArray:
	# One-time setup prevents catalog replacement from silently invalidating a run.
	if _configured:
		return PackedStringArray(["catalog: already configured"])
	var errors: PackedStringArray = []
	if definitions.is_empty() or definitions.size() > MAX_RECIPES:
		errors.append("catalog: expected between one and eight recipes")
	var candidate: Dictionary = {}
	for definition: SynergyDefinition in definitions:
		if definition == null:
			errors.append("catalog: null recipe")
			continue
		for error: String in definition.validate():
			errors.append("%s: %s" % [definition.id, error])
		if candidate.has(definition.id):
			errors.append("%s: duplicate recipe ID" % definition.id)
		var endpoints: Array[StringName] = definition.endpoint_ids
		if endpoints.size() != 2:
			errors.append("%s: exactly two endpoints required" % definition.id)
		elif endpoints[0] == endpoints[1]:
			errors.append("%s: endpoints must be distinct" % definition.id)
		for endpoint: StringName in endpoints:
			if not endpoint in SUPPORT_IDS and not endpoint in ROLE_IDS:
				errors.append("%s: unknown endpoint %s" % [definition.id, endpoint])
		# Copy values, not Resources: subsequent editor/fixture changes cannot mutate a run.
		candidate[definition.id] = {
			"endpoints": endpoints.duplicate(),
			"name_key": definition.name_key,
			"description_key": definition.description_key,
		}
	if not errors.is_empty():
		return errors
	_catalog = candidate
	_configured = true
	return errors

func rewire(requested: Array[StringName], equipped: Array[StringName],
		at_intermission: bool, unlocked: bool) -> PackedStringArray:
	# Pausing for a mid-wave Signal draft is NOT an intermission.
	if not at_intermission:
		return PackedStringArray(["connections: rewiring requires an intermission"])
	var errors: PackedStringArray = _selection_errors(requested, equipped, unlocked)
	if errors.is_empty():
		_active = requested.duplicate()
	return errors

func active_ids() -> Array[StringName]:
	return _active.duplicate()

func is_active(recipe_id: StringName, equipped: Array[StringName]) -> bool:
	# Recheck live equipment, so removing an endpoint cannot leave an effective recipe.
	if not _active.has(recipe_id) or not _equipment_errors(equipped).is_empty():
		return false
	return _missing_endpoints(recipe_id, equipped).is_empty()

func preview(recipe_id: StringName, equipped: Array[StringName]) -> Dictionary:
	if not _catalog.has(recipe_id):
		return {"known": false, "recipe_id": String(recipe_id), "eligible": false}
	var recipe: Dictionary = _catalog[recipe_id]
	var missing: Array[StringName] = _missing_endpoints(recipe_id, equipped)
	return {
		"known": true, "recipe_id": String(recipe_id),
		"name_key": String(recipe["name_key"]),
		"description_key": String(recipe["description_key"]),
		"endpoint_ids": recipe["endpoints"].duplicate(),
		"missing_endpoint_ids": missing,
		"eligible": missing.is_empty() and _equipment_errors(equipped).is_empty(),
	}

func reset_for_mission() -> void:
	# Connections are run selection, not inherited combat power.
	_active.clear()

func to_data() -> Dictionary:
	var connections: Array[String] = []
	for recipe_id: StringName in _active:
		connections.append(String(recipe_id))
	return {"schema_version": SCHEMA_VERSION, "connections": connections}

func restore(value: Variant, equipped: Array[StringName], unlocked: bool) -> PackedStringArray:
	# Call only from the validated checkpoint loader, never as a combat rewire action.
	# Do not trust saved equipment or saved unlock flags. Validate before mutating anything.
	if not value is Dictionary:
		return PackedStringArray(["patchboard save: expected an object"])
	var data: Dictionary = value
	if data.size() != 2 or not data.has("schema_version") or not data.has("connections"):
		return PackedStringArray(["patchboard save: unexpected or missing fields"])
	var version: Variant = data["schema_version"]
	# JSON numbers may be floats; bool must not compare equal to schema version 1.
	if not (typeof(version) == TYPE_INT or typeof(version) == TYPE_FLOAT):
		return PackedStringArray(["patchboard save: schema version must be numeric"])
	if version != SCHEMA_VERSION:
		return PackedStringArray(["patchboard save: unsupported schema version"])
	if not data["connections"] is Array:
		return PackedStringArray(["patchboard save: connections must be an array"])
	var values: Array = data["connections"]
	if values.size() > MAX_CONNECTIONS:
		return PackedStringArray(["patchboard save: more than two connections"])
	var requested: Array[StringName] = []
	for item: Variant in values:
		if typeof(item) != TYPE_STRING:
			return PackedStringArray(["patchboard save: recipe IDs must be strings"])
		requested.append(StringName(item))
	var errors: PackedStringArray = _selection_errors(requested, equipped, unlocked)
	if errors.is_empty():
		_active = requested
	return errors

func _selection_errors(requested: Array[StringName], equipped: Array[StringName],
		unlocked: bool) -> PackedStringArray:
	var errors: PackedStringArray = _equipment_errors(equipped)
	if not _configured:
		errors.append("catalog: configure before selecting or restoring connections")
	if not unlocked and not requested.is_empty():
		errors.append("connections: patchboard is locked")
	if requested.size() > MAX_CONNECTIONS:
		errors.append("connections: at most two recipes may be active")
	var seen: Dictionary = {}
	for recipe_id: StringName in requested:
		if seen.has(recipe_id):
			errors.append("%s: duplicate active recipe" % recipe_id)
		seen[recipe_id] = true
		if not _catalog.has(recipe_id):
			errors.append("%s: unknown recipe" % recipe_id)
			continue
		for endpoint: StringName in _missing_endpoints(recipe_id, equipped):
			errors.append("%s: missing equipped endpoint %s" % [recipe_id, endpoint])
	return errors

func _equipment_errors(equipped: Array[StringName]) -> PackedStringArray:
	var errors: PackedStringArray = []
	var seen: Dictionary = {}
	var supports: int = 0
	for endpoint: StringName in equipped:
		if seen.has(endpoint):
			errors.append("equipment: duplicate endpoint %s" % endpoint)
		seen[endpoint] = true
		if endpoint in SUPPORT_IDS:
			supports += 1
		elif not endpoint in ROLE_IDS:
			errors.append("equipment: unknown endpoint %s" % endpoint)
	if supports > 5:
		errors.append("equipment: at most five support families")
	return errors

func _missing_endpoints(recipe_id: StringName, equipped: Array[StringName]) -> Array[StringName]:
	var missing: Array[StringName] = []
	var recipe: Dictionary = _catalog[recipe_id]
	for endpoint: StringName in recipe["endpoints"]:
		if not endpoint in equipped:
			missing.append(endpoint)
	return missing
