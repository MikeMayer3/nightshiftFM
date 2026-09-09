class_name BroadcastContent
extends RefCounted
const ENEMIES: Array[EnemyDefinition] = [
	preload("res://content/broadcast/enemies/plated.tres"),
	preload("res://content/broadcast/enemies/caster.tres"),
	preload("res://content/broadcast/enemies/jammer.tres"),
	preload("res://content/broadcast/enemies/mimic.tres"),
	preload("res://content/broadcast/enemies/mortar.tres"),
	preload("res://content/broadcast/enemies/caller.tres"),
	preload("res://content/broadcast/enemies/core.tres"),
	preload("res://content/broadcast/enemies/silence.tres"),
	preload("res://content/broadcast/enemies/aerial.tres"),
]
static func enemy(id: StringName) -> EnemyDefinition:
	for definition: EnemyDefinition in ENEMIES:
		if definition.id == id: return definition
	return EncounterContent.enemy(id)
