class_name CombatContent
extends RefCounted
## This deliberately small M2 fixture is the only playable content.
const MAIN: WeaponDefinition = preload("res://content/weapons/m2_pulse.tres")
const SHIELD: ShieldDefinition = preload("res://content/shields/m2_capacitor.tres")
const SWARMER: EnemyDefinition = preload("res://content/enemies/m2_swarmer.tres")
const DIVER: EnemyDefinition = preload("res://content/enemies/m2_diver.tres")
const CARRIER: EnemyDefinition = preload("res://content/enemies/m2_carrier.tres")
const WAVE_1: WaveDefinition = preload("res://content/waves/m2_wave_1.tres")
const WAVE_2: WaveDefinition = preload("res://content/waves/m2_wave_2.tres")
const WAVE_3: WaveDefinition = preload("res://content/waves/m2_wave_3.tres")
const MISSION: MissionDefinition = preload("res://content/missions/m2_test.tres")

static func definitions() -> Array[ContentDefinition]:
	return [MAIN, SHIELD, SWARMER, DIVER, CARRIER, WAVE_1, WAVE_2, WAVE_3, MISSION]

static func enemy(id: StringName) -> EnemyDefinition:
	for definition: EnemyDefinition in [SWARMER, DIVER, CARRIER]:
		if definition.id == id:
			return definition
	return null

static func waves() -> Array[WaveDefinition]:
	return [WAVE_1, WAVE_2, WAVE_3]
