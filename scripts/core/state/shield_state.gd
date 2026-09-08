class_name ShieldState
extends RefCounted

var definition_id: StringName = &""
var rank: int = GameRules.STARTING_RANK
var capacity: float = 0.0
var current: float = 0.0

static func from_definition(definition: ShieldDefinition) -> ShieldState:
	var state: ShieldState = ShieldState.new()
	state.definition_id = definition.id
	state.capacity = definition.base_capacity
	state.current = definition.base_capacity
	return state

func to_data() -> Dictionary:
	return {"definition_id": String(definition_id), "rank": rank, "capacity": capacity, "current": current}
