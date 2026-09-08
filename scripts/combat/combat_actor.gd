class_name CombatActor
extends RefCounted
## Per-mission values copied from content; also used by the bounded ranged fixture.
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
var projectile: bool = false
var resolved: bool = false

static func from_definition(definition: EnemyDefinition, number: int, at: Vector2) -> CombatActor:
	var actor: CombatActor = CombatActor.new()
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
	age += delta
	var multiplier: float = 1.0
	if path_kind == EnemyDefinition.PathKind.DIVE:
		multiplier = 2.7 if age >= 2.0 else 0.55
		position.x = clampf(origin_x + sin(age * 1.7) * 65.0, radius, 640.0 - radius)
	position.y += speed * multiplier * delta
