class_name SynergyDefinition
extends ContentDefinition
## Immutable authored recipe; execution is an explicit, tested combat contract.
@export var endpoint_ids: Array[StringName] = []
@export var capability: StringName = &""
@export var cooldown: float = 1.0
@export var target_cap: int = 6
@export var threshold: int = 1
@export var damage: float = 0.0
@export var radius: float = 120.0
@export var duration: float = 0.0
@export var coefficient: float = 0.0
@export var generation_depth: int = 1

func referenced_ids() -> Array[StringName]:
	return endpoint_ids.duplicate()

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if endpoint_ids.size() != 2 or endpoint_ids[0] == endpoint_ids[1]: errors.append("endpoint_ids: two distinct endpoints required")
	for endpoint: StringName in endpoint_ids:
		if endpoint not in [&"main", &"shield", &"arc_aerial", &"bass_driver", &"static_net", &"echo_deck", &"needle_swarm", &"reverb_well"]: errors.append("endpoint_ids: unknown endpoint")
	if capability not in [&"", &"marked", &"slowed"]: errors.append("capability: unknown status")
	if not is_finite(cooldown) or cooldown < .08 or cooldown > 20: errors.append("cooldown: outside .08..20")
	if target_cap < 1 or target_cap > 8 or threshold < 1 or threshold > 3: errors.append("counts: outside bounded limits")
	if not is_finite(damage) or damage < 0 or damage > 50: errors.append("damage: outside 0..50")
	if not is_finite(radius) or radius < 1 or radius > 400: errors.append("radius: outside 1..400")
	if not is_finite(duration) or duration < 0 or duration > 1: errors.append("duration: outside 0..1")
	if not is_finite(coefficient) or coefficient < 0 or coefficient > 1: errors.append("coefficient: outside 0..1")
	if generation_depth != 1: errors.append("generation_depth: only one secondary generation allowed")
	return errors
