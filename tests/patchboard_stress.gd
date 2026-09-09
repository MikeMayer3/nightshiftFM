extends SceneTree
const FIXTURE: Script = preload("res://tests/unit/test_patchboard.gd")
const M5: Script = preload("res://tests/unit/test_arsenal.gd")
var failed: bool = false
var rows: Array[Dictionary] = []
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var ids: Array = PatchboardContent.RECIPES.keys()
	for left: int in ids.size():
		for right: int in range(left + 1, ids.size()):
			var s: CombatSession = FIXTURE.new().fixture(ids[left], true, ["pulse", "sweep", "burst"][(left + right) % 3], "feedback")
			for endpoint: StringName in (PatchboardContent.RECIPES[ids[right]] as SynergyDefinition).endpoint_ids:
				if s.draft.track(endpoint) == null: s.draft.equip(endpoint)
			for index: int in s.draft.tracks.size():
				var owned: UpgradeTrack = s.draft.tracks[index]
				s.draft.tracks[index] = M5.new().path(owned.definition, 3 if owned.definition.id == &"needle_swarm" else 2, 1)
			s.patchboard.slots[1] = ids[right]
			s.apply_ranks()
			if not s.patchboard.connected(s, ids[left]) or not s.patchboard.connected(s, ids[right]): failed = true
			s.actors.clear()
			for index: int in 150:
				var actor: CombatActor = s.spawn_enemy(M4Content.enemy(&"m4.elite" if index % 10 == 0 else &"m4.plated"), 80 + index % 15 * 32)
				actor.position.y = 200 + index / 15 * 32
				actor.health = 100000
				actor.max_health = 100000
			for index: int in 400:
				var shot: CombatActor = s.spawn_projectile(s.actors[index % 150])
				shot.position = Vector2(70 + index % 20 * 25, 200 + index / 20 * 18)
			var meter: Dictionary = {"events": 0, "recipe_damage_hits": 0, "max_per_root": 0, "bad_generation": false, "roots": {}}
			s.combat_event.connect(func(e: CombatEvent) -> void:
				meter.events += 1
				if (e.source_id in [&"echo_deck", &"shield"] or PatchboardContent.RECIPES.has(e.source_id)) and e.kind in [CombatEvent.Kind.ATTACK, CombatEvent.Kind.DAMAGE, CombatEvent.Kind.KILL, CombatEvent.Kind.INTERCEPT]:
					if e.generation_depth != 1 or e.eligible_triggers != 0 or e.root_attack_id <= 0: meter.bad_generation = true
				if PatchboardContent.RECIPES.has(e.source_id) and e.kind == CombatEvent.Kind.DAMAGE:
					meter.recipe_damage_hits += 1
					meter.roots[e.root_attack_id] = int(meter.roots.get(e.root_attack_id, 0)) + 1
					meter.max_per_root = maxi(meter.max_per_root, meter.roots[e.root_attack_id]))
			var main_timer: float = 0
			var start: int = Time.get_ticks_usec()
			for tick: int in 600:
				s.patchboard.advance(CombatSession.STEP)
				s.arsenal.tick_passive(CombatSession.STEP)
				main_timer -= CombatSession.STEP
				if main_timer <= 0 and s.target() != null:
					s.arsenal.fire_main(s, s.target())
					main_timer = ArsenalStats.parameters(s.draft.track(&"main")).interval
				s.arsenal.advance(s, CombatSession.STEP)
				if tick % 60 == 0:
					s.run.shield.current = 1
					s.ability_left = 1 if tick % 120 == 0 else 0
					s.hit_station(2, &"M2_SWARMER_NAME", &"COMBAT_PROJECTILE_HIT" if tick % 120 == 0 else &"COMBAT_BREACH_HIT")
				for actor: CombatActor in s.actors: actor.status.advance(CombatSession.STEP)
				s.actors = s.actors.filter(func(a: CombatActor) -> bool: return not a.resolved)
			var milliseconds: float = (Time.get_ticks_usec() - start) / 1000.0
			var row: Dictionary = {"connections": [String(ids[left]), String(ids[right])], "simulated_seconds": 10, "initial_enemies": 150, "initial_projectiles": 400, "cpu_ms": milliseconds, "events": meter.events, "recipe_damage_hits": meter.recipe_damage_hits, "max_recipe_hits_per_root": meter.max_per_root, "peak_pending": s.arsenal.peak_pending, "bad_generation": meter.bad_generation}
			rows.append(row)
			if meter.bad_generation or meter.max_per_root > 16 or s.arsenal.peak_pending > 256 or meter.events > 40000: failed = true
			print(JSON.stringify(row))
	var file: FileAccess = FileAccess.open("res://docs/evidence/M6/stress.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": not failed, "fixtures": rows}, "\t"))
	file.close()
	print("RESULT: %d pair fixtures; passed=%s" % [rows.size(), not failed])
	quit(1 if failed else 0)
