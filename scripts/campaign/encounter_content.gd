class_name EncounterContent
extends RefCounted
## M8 opening encounters. The M7 content version continues its original waves.
const VERSION: String = "m8.encounters.1"
const ELITES: Array[EnemyDefinition] = [
	preload("res://content/encounters/enemies/elite_swarmer.tres"),
	preload("res://content/encounters/enemies/elite_carrier.tres"),
	preload("res://content/encounters/enemies/elite_diver.tres"),
]

static func authored(session: CombatSession) -> bool:
	return session.campaign != null and session.active_combat != null and session.active_combat.content_version == VERSION and EncounterWaves.MISSIONS.has(session.campaign.mission)

static func enemy(id: StringName) -> EnemyDefinition:
	for definition: EnemyDefinition in ELITES:
		if definition.id == id: return definition
	return M4Content.enemy(id)

static func spawn_x(definition: WaveDefinition, group: int, member: int, center: float) -> float:
	match definition.formation:
		WaveDefinition.Formation.ALTERNATING:
			return (150.0 if group % 2 == 0 else 490.0) + (member - (definition.group_size - 1) * .5) * 38.0
		WaveDefinition.Formation.FAN:
			return 80.0 + member * 480.0 / maxf(1, definition.group_size - 1)
		WaveDefinition.Formation.ESCORT:
			return 320.0 + (member - (definition.group_size - 1) * .5) * 48.0
	return center + (member - (definition.group_size - 1) * .5) * 38.0

static func validate() -> PackedStringArray:
	var definitions: Array[ContentDefinition] = [CombatContent.SWARMER, CombatContent.DIVER, CombatContent.CARRIER]
	definitions.append_array(ELITES)
	var errors: PackedStringArray = []
	for mission: int in EncounterWaves.MISSIONS:
		var content: MissionDefinition = CampaignContent.MISSIONS[mission - 1]
		definitions.append(content)
		var waves: Array = EncounterWaves.MISSIONS[mission]
		if content.prototype or waves.size() != 10: errors.append("authored mission must have ten waves")
		var seen: Array[StringName] = []
		for index: int in waves.size():
			var wave: WaveDefinition = waves[index]
			definitions.append(wave)
			if content.wave_ids[index] != wave.id: errors.append("mission wave order mismatch")
			if wave.enemy_ids.is_empty() or wave.enemy_ids.size() > 80: errors.append("wave enemy count outside authored budget")
			for id: StringName in wave.enemy_ids:
				if index == 9 and id not in seen: errors.append("unintroduced finale enemy: " + String(id))
			if index < 9: seen.append_array(wave.enemy_ids)
	errors.append_array(ContentValidator.validate(definitions))
	return errors
