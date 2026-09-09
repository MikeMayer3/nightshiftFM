class_name EncounterDirector
extends RefCounted
## Bounded enemy behaviors. Visual tells derive from these same clock windows.
static func boss(actor: CombatActor) -> bool:
	return actor.role in [EnemyDefinition.Role.CALLER, EnemyDefinition.Role.CORE, EnemyDefinition.Role.SILENCE]
static func channel(actor: CombatActor) -> bool:
	return actor.role in [EnemyDefinition.Role.CASTER, EnemyDefinition.Role.JAMMER, EnemyDefinition.Role.MORTAR, EnemyDefinition.Role.CALLER, EnemyDefinition.Role.CORE, EnemyDefinition.Role.SILENCE] and not actor.resolved and actor.health > 0 and actor.status.jam_left <= 0 and fmod(actor.ability_time, actor.ability_interval) >= actor.ability_interval - 1.25
static func satellites(s: CombatSession, core: CombatActor) -> Array[CombatActor]:
	return s.actors.filter(func(a: CombatActor) -> bool: return not a.resolved and a.health > 0 and a.owner_id == core.serial)
static func exposed(s: CombatSession, actor: CombatActor) -> bool:
	if actor.role == EnemyDefinition.Role.CORE: return actor.children_spawned == 2 and satellites(s, actor).is_empty()
	return actor.role == EnemyDefinition.Role.SILENCE and fmod(actor.age, 10) >= 6
static func protection(s: CombatSession, actor: CombatActor) -> float:
	if actor.projectile: return 1
	if actor.role == EnemyDefinition.Role.CORE and not exposed(s, actor): return .2
	if actor.role == EnemyDefinition.Role.SILENCE: return 1.5 if exposed(s, actor) else .55
	if actor.role == EnemyDefinition.Role.MIMIC: return .55 if fmod(actor.age, 6) < 3 else 1.2
	for other: CombatActor in s.actors:
		if other != actor and other.role == EnemyDefinition.Role.CASTER and channel(other) and other.position.distance_to(actor.position) < 150: return .65
	return 1
static func jammed_support(s: CombatSession) -> StringName:
	var source: CombatActor
	for actor: CombatActor in s.actors:
		if actor.role in [EnemyDefinition.Role.JAMMER, EnemyDefinition.Role.SILENCE] and channel(actor) and (source == null or actor.serial < source.serial): source = actor
	if source == null: return &""
	var owned: Array[UpgradeTrack] = s.draft.tracks.filter(func(t: UpgradeTrack) -> bool: return t.definition.support)
	if owned.is_empty(): return &""
	return owned[source.serial % owned.size()].definition.id
static func prepare(s: CombatSession, actor: CombatActor) -> void:
	if actor.role == EnemyDefinition.Role.CORE and actor.children_spawned == 0:
		for side: int in [-1, 1]:
			var aerial: CombatActor = s.spawn_enemy(BroadcastContent.enemy(&"m8.aerial"), clampf(actor.position.x + side * 80, 45, 595))
			aerial.owner_id = actor.serial
			aerial.health *= ActiveCombat.health_scale(mini(s.wave, 10)) * .7 * BroadcastRules.health_scale(s.campaign, s.wave)
			aerial.max_health = aerial.health
		actor.children_spawned = 2
static func ability(s: CombatSession, actor: CombatActor) -> void:
	if actor.role in [EnemyDefinition.Role.MORTAR, EnemyDefinition.Role.CALLER, EnemyDefinition.Role.CORE, EnemyDefinition.Role.SILENCE]:
		# At most 3 packets per cycle and 64 living hostile packets in the arena.
		var packets: int = 0
		for existing: CombatActor in s.actors:
			if existing.projectile and not existing.resolved: packets += 1
		for index: int in mini(3 if boss(actor) else 1, maxi(0, 64 - packets)):
			var shot: CombatActor = s.spawn_projectile(actor)
			shot.position.x = clampf(actor.position.x + (index - 1) * 36, 32, 608)
		if actor.role == EnemyDefinition.Role.CALLER and actor.children_spawned < 6:
			for side: int in [-1, 1]: s.spawn_enemy(CombatContent.SWARMER, actor.position.x + side * 75)
			actor.children_spawned += 2
