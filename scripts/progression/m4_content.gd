class_name M4Content
extends RefCounted
const VERSION: String = "m4.1"
const ARC: TrackDefinition = preload("res://content/m4/tracks/arc_aerial.tres")
const BASS: TrackDefinition = preload("res://content/m4/tracks/bass_driver.tres")
const NET: TrackDefinition = preload("res://content/m4/tracks/static_net.tres")
const PLATED: EnemyDefinition = preload("res://content/m4/enemies/plated.tres")
const ELITE: EnemyDefinition = preload("res://content/m4/enemies/elite.tres")
const WAVES: Array[WaveDefinition] = [
	preload("res://content/m4/waves/wave_1.tres"),
	preload("res://content/m4/waves/wave_2.tres"),
	preload("res://content/m4/waves/wave_3.tres"),
	preload("res://content/m4/waves/wave_4.tres"),
	preload("res://content/m4/waves/wave_5.tres"),
	preload("res://content/m4/waves/wave_6.tres"),
	preload("res://content/m4/waves/wave_7.tres"),
	preload("res://content/m4/waves/wave_8.tres"),
	preload("res://content/m4/waves/wave_9.tres"),
	preload("res://content/m4/waves/wave_10.tres")
]

static func tracks() -> Array[TrackDefinition]:
	return [M3Content.MAIN, M3Content.SHIELD, ARC, BASS, NET]

static func enemy(id: StringName) -> EnemyDefinition:
	for definition: EnemyDefinition in [PLATED, ELITE]:
		if definition.id == id: return definition
	return CombatContent.enemy(id)

static func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	var ids: Array[StringName] = []
	for track: TrackDefinition in tracks():
		for option: UpgradeDefinition in track.options:
			errors.append_array(option.validate())
			if option.id in ids or option.target_id != track.id: errors.append("duplicate or incompatible option")
			ids.append(option.id)
			if not track.baseline.has(option.stat): errors.append("unsupported stat")
			if option.prerequisite != &"" and not track.options.any(func(c: UpgradeDefinition) -> bool: return c.id == option.prerequisite): errors.append("missing prerequisite")
	for definition: EnemyDefinition in [PLATED, ELITE]: errors.append_array(definition.validate())
	for wave: WaveDefinition in WAVES:
		errors.append_array(wave.validate())
		for id: StringName in wave.enemy_ids:
			if enemy(id) == null: errors.append("unknown wave enemy")
	return errors
