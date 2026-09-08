class_name WeaponState
extends RefCounted
## Runtime owns copied values and stable IDs, never a shared content Resource.

var definition_id: StringName = &""
var rank: int = GameRules.STARTING_RANK
var damage: float = 0.0

static func from_definition(definition: WeaponDefinition) -> WeaponState:
	var state: WeaponState = WeaponState.new()
	state.definition_id = definition.id
	state.damage = definition.base_damage
	return state

func to_data() -> Dictionary:
	return {"definition_id": String(definition_id), "rank": rank, "damage": damage}
