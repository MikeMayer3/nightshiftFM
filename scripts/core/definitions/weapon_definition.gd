class_name WeaponDefinition
extends ContentDefinition
## M2 implements the instant pulse behavior; other behaviors and upgrades are deferred.

enum Slot { MAIN, SUPPORT }
enum Behavior { PROJECTILE, BEAM, VOLLEY, SUPPORT, PULSE }
@export var slot: Slot = Slot.MAIN
@export var behavior: Behavior = Behavior.PROJECTILE
@export var support_family: GameRules.SupportFamily = GameRules.SupportFamily.ARC_AERIAL
@export var base_damage: float = 1.0
@export var attack_interval: float = 1.0

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if not is_finite(base_damage) or base_damage < 0.0:
		errors.append("base_damage: must be finite and nonnegative")
	if not is_finite(attack_interval) or attack_interval <= 0.0:
		errors.append("attack_interval: must be finite and greater than zero")
	if slot not in Slot.values():
		errors.append("slot: unknown equipment slot")
	if behavior not in Behavior.values():
		errors.append("behavior: unknown behavior")
	if slot == Slot.SUPPORT and support_family not in GameRules.SupportFamily.values():
		errors.append("support_family: must belong to the six-family roster")
	return errors
