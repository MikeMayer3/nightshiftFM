extends SceneTree
const FIXTURE: Script = preload("res://tests/unit/test_arsenal.gd")
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var builder: RefCounted = FIXTURE.new()
	var results: Array[Dictionary] = []
	for key: String in ArsenalContent.DEFINITIONS:
		var definition: TrackDefinition = ArsenalContent.DEFINITIONS[key]
		for card: UpgradeDefinition in definition.options:
			var branch: int = 1
			for index: int in [1, 2, 3]:
				if ".b%d" % index in String(card.id): branch = index
			var before: UpgradeTrack = builder.path(definition, branch, 1, 0, 1 if card.required_rank == 0 else card.required_rank - 1)
			var after: UpgradeTrack = UpgradeTrack.new(definition)
			for id: StringName in before.choices: after.accept(id, [])
			assert(after.accept(card.id, []))
			var changed: bool = false
			for scenario: int in [0, 1, 2, 3, 4, 5, 6, 7, 8]:
				if signature(builder, key, before, scenario) != signature(builder, key, after, scenario):
					changed = true
					break
			results.append({"id": String(card.id), "effect_observed": changed})
			if not changed: print("NO OBSERVED EFFECT ", card.id)
	FileAccess.open("res://docs/evidence/M5/effect-matrix.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	var passed: int = results.filter(func(r: Dictionary) -> bool: return r.effect_observed).size()
	print("EFFECT MATRIX ", passed, "/", results.size())
	quit(0 if passed == results.size() else 1)

func signature(builder: RefCounted, key: String, owned: UpgradeTrack, scenario: int) -> String:
	var definition: TrackDefinition = owned.definition
	var main: String = key if definition.id == &"main" else "pulse"
	var shield: String = key if definition.id == &"shield" else "capacitor"
	var support: String = key if definition.support else "arc_aerial"
	var s: CombatSession = builder.fixture(main, shield, support)
	if support != "arc_aerial" and support != "echo_deck": s.draft.tracks.remove_at(0); s.draft.equip(&"main")
	for index: int in s.draft.tracks.size():
		if s.draft.tracks[index].definition.id == definition.id: s.draft.tracks[index] = owned
	s.apply_ranks()
	s.run.shield.current = s.run.shield.capacity
	for index: int in 4: s.spawn_enemy(M4Content.enemy(&"m4.elite" if index == 0 else &"m4.plated"), 320)
	var contacts: Array = []
	var listener: Callable = func(e: CombatEvent) -> void: contacts.append([s.elapsed, e.kind, e.source_id, e.target_id, e.amount])
	s.combat_event.connect(listener)
	for index: int in s.actors.size():
		var actor: CombatActor = s.actors[index]
		actor.position = Vector2(320 + (index % 3 - 1) * [24, 190, 65, 120][mini(3, scenario)], 52 + (index / 3) * 190)
		if scenario == 3: actor.position = Vector2(320 + [0, 120, -120, 40, 80, -40, -80, 160, -160, 10, 20, -20][index], 420 + (index % 2) * 15)
		if scenario == 4: actor.position = Vector2(320, 580 - index * 12)
		if scenario == 5: actor.position = Vector2(320 + (index % 3 - 1) * 98, 420 - (index / 3) * 10)
		if scenario == 5 and index == 8: actor.position = Vector2(320, 430)
		if key == "burst" and scenario in [7, 8]:
			actor.position = Vector2(320 + (0 if index == 0 else 98 if index % 2 == 1 else -98), 154 if scenario == 7 else 420)
		actor.health = 10000
		actor.max_health = 10000
		if key == "echo_deck" and scenario == 1: actor.health = 20
		actor.speed = 0
		actor.ability_interval = 10000
		actor.children_spawned = actor.child_limit
		actor.projectiles_fired = actor.projectile_limit
		s.focus_active = scenario == 1
		s.focus_point = Vector2(320, 52)
	if key == "static_net":
		for index: int in 12:
			var projectile: CombatActor = s.spawn_projectile(s.actors[0])
			projectile.position = Vector2(320 + (index % 3) * 30, 620 if scenario != 3 else 425)
			projectile.speed = 0
	if scenario == 7 and key == "echo_deck":
		s.actors.clear()
		var first: CombatActor = s.spawn_enemy(CombatContent.SWARMER, 320)
		first.position = Vector2(320, 450)
		first.health = 10000
		for index: int in 3: s.arsenal.fire_main(s, first)
		s.damage_actor(first, 100000)
		var next: CombatActor = s.spawn_enemy(CombatContent.SWARMER, 510)
		next.position.y = 450
		next.health = 10000
		for index: int in 120: s.arsenal.advance(s, 1.0/60)
		s.combat_event.disconnect(listener)
		return str(next.health)
	var crit_seed: int = 0
	var sample: RandomNumberGenerator = RandomNumberGenerator.new()
	for candidate: int in 1000:
		sample.seed = candidate
		if sample.randf() < .05:
			crit_seed = candidate
			break
	var rows: Array = []
	for tick: int in (2160 if key == "echo_deck" else 720):
		if tick % (480 if scenario == 1 else 120) == 0 and definition.id == &"shield":
			s.activate_shield()
			s.hit_station(80, &"COMBAT_PROJECTILE", &"COMBAT_PROJECTILE_HIT")
			s.hull = 100
			if s.is_finished(): break
		if scenario == 6: s.random.rng("combat").seed = crit_seed
		s.advance(1.0/60)
		if tick % 60 == 0:
			var actors: Array = []
			for actor: CombatActor in s.actors:
				actors.append([actor.health, actor.position, actor.status.charge_left, actor.status.exposure_left, actor.status.slow_left, actor.status.slow, actor.status.jam_left])
			var moving: Array = []
			for needle: Dictionary in s.arsenal.needles: moving.append([needle.x, needle.y, needle.left, needle.hits])
			rows.append([actors, moving, s.arsenal.report.totals.duplicate(true), s.run.shield.current, s.ability_wait, s.damage_taken, s.recharge_time, s.shot_time, s.arsenal.echo_count, s.arsenal.packets.size(), s.arsenal.zones.size(), s.arsenal.overshield, s.arsenal.reservoir, s.arsenal.shield_charge])
	s.combat_event.disconnect(listener)
	return str([rows, contacts])
