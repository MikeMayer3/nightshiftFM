class_name CombatActor
extends RefCounted
## Per-mission values copied from content; also used by the bounded ranged fixture.
var status: StatusState = StatusState.new()
var armor: float = 0.0
var elite: bool = false
var jam_immune: bool = false
var displacement_immune: bool = false
var serial: int = 0
var definition_id: StringName
var name_key: StringName
var path_kind: EnemyDefinition.PathKind
var position: Vector2
var origin_x: float
var age: float = 0.0
var health: float
var max_health: float
var speed: float
var radius: float
var breach_damage: float
var child_id: StringName
var child_limit: int
var projectile_limit: int
var children_spawned: int = 0
var projectiles_fired: int = 0
var ability_interval: float
var ability_time: float = 0.0
var root_attack_id: int = 0
var source_id: StringName = &""
var generation_depth: int = 0
var eligible_triggers: int = CombatEvent.DIRECT | CombatEvent.CAN_REFLECT
var projectile: bool = false
var resolved: bool = false

static func from_definition(definition: EnemyDefinition, number: int, at: Vector2) -> CombatActor:
	var actor: CombatActor = CombatActor.new()
	actor.armor = definition.armor
	actor.elite = definition.elite
	actor.jam_immune = definition.jam_immune
	actor.displacement_immune = definition.displacement_immune
	actor.serial = number
	actor.definition_id = definition.id
	actor.name_key = definition.name_key
	actor.path_kind = definition.path_kind
	actor.position = at
	actor.origin_x = at.x
	actor.health = definition.health
	actor.max_health = definition.health
	actor.speed = definition.speed
	actor.radius = definition.radius
	actor.breach_damage = definition.breach_damage
	actor.child_id = definition.child_id
	actor.child_limit = definition.child_limit
	actor.projectile_limit = definition.projectile_limit
	actor.ability_interval = definition.ability_interval
	return actor

func advance(delta: float) -> void:
	status.advance(delta)
	var movement_delta: float = delta * (1.0 - status.slow)
	age += movement_delta
	var multiplier: float = 1.0
	if path_kind == EnemyDefinition.PathKind.DIVE:
		multiplier = 2.7 if age >= 2.0 else 0.55
		position.x = clampf(origin_x + sin(age * 1.7) * 65.0, radius, 640.0 - radius)
	position.y += speed * multiplier * movement_delta
