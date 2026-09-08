class_name CombatEvent
extends RefCounted
## An explicit event, independent of art and text. IDs restart from the saved checkpoint.
enum Kind { ATTACK, DAMAGE, KILL, INTERCEPT, BREACH, STATION_DAMAGE, SHIELD_BREAK, SHIELD_HEAL, CONTROL }
const DIRECT: int = 1
const CAN_ECHO: int = 2
const CAN_REFLECT: int = 4
var event_id: int
var root_attack_id: int
var source_id: StringName
var generation_depth: int = 0
var eligible_triggers: int = DIRECT
var kind: Kind
var target_id: int
var amount: float

func _init(serial: int, root_id: int, source: StringName, type: Kind, target: int, value: float) -> void:
	event_id = serial
	root_attack_id = root_id
	source_id = source
	kind = type
	target_id = target
	amount = value
