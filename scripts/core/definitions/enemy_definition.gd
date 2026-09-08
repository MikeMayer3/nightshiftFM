class_name EnemyDefinition
extends ContentDefinition

enum PathKind { STRAIGHT, DIVE, CARRIER }
@export var armor: float = 0.0
@export var elite: bool = false
@export var jam_immune: bool = false
@export var displacement_immune: bool = false
@export var path_kind: PathKind = PathKind.STRAIGHT
@export var health: float = 16.0
@export var speed: float = 65.0
@export var radius: float = 18.0
@export var breach_damage: float = 12.0
@export var child_id: StringName = &""
@export var child_limit: int = 0
@export var ability_interval: float = 3.0
@export var projectile_limit: int = 0

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	for field: String in ["health", "speed", "radius", "breach_damage", "ability_interval"]:
		var value: float = get(field)
		if not is_finite(value) or value <= 0.0:
			errors.append(field + ": must be finite and positive")
	if not is_finite(armor) or armor < 0 or armor > 1000:
		errors.append("armor: outside supported bounds")
	if path_kind not in PathKind.values():
		errors.append("path_kind: unknown path")
	if child_limit < 0 or child_limit > 4 or projectile_limit < 0 or projectile_limit > 4:
		errors.append("ability limits: must be between zero and four")
	if child_limit > 0 and child_id.is_empty():
		errors.append("child_id: required for spawning")
	return errors

func referenced_ids() -> Array[StringName]:
	return [] if child_id.is_empty() else [child_id]
