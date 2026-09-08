extends RefCounted

func isolated() -> CombatSession:
	var session: CombatSession = CombatSession.new()
	session.phase = CombatSession.Phase.COMBAT
	session.wave = 1
	session.spawn_index = 0
	session.spawn_time = 10000.0
	session.auto_fire = false
	return session

func run(context: TestContext) -> bool:
	context.check(ContentValidator.validate(CombatContent.definitions()).is_empty(), "nine M2 definitions validate with resolved references")
	for definition: ContentDefinition in CombatContent.definitions():
		context.check(TranslationServer.translate(definition.name_key) != definition.name_key, "M2 content name translates: %s" % definition.id)
	var invalid: EnemyDefinition = CombatContent.CARRIER.duplicate() as EnemyDefinition
	invalid.child_limit = 500
	invalid.speed = NAN
	context.check(invalid.validate().size() == 2, "enemy validator rejects nonfinite speed and unbounded spawning")
	var session: CombatSession = isolated()
	for x: float in [-100.0, 0.0, 320.0, 640.0, 900.0]:
		var actor: CombatActor = session.spawn_enemy(CombatContent.SWARMER, x)
		context.check(CombatSession.SPAWN_BAND.has_point(actor.position) or actor.position.x == CombatSession.SPAWN_BAND.end.x, "spawn clamps to top band")
	session = isolated()
	var straight: CombatActor = session.spawn_enemy(CombatContent.SWARMER, 100.0)
	var diver: CombatActor = session.spawn_enemy(CombatContent.DIVER, 300.0)
	var carrier: CombatActor = session.spawn_enemy(CombatContent.CARRIER, 500.0)
	session.advance(1.0)
	context.check(is_equal_approx(straight.position.x, 100) and straight.position.y > 110, "swarmer descends straight")
	context.check(diver.position.x != 300 and diver.position.y < 90, "diver telegraphs with a slower weaving approach")
	var before: float = diver.position.y
	session.advance(2.0)
	context.check(diver.position.y - before > 160, "diver accelerates after tell")
	context.check(carrier.position.x == 500 and carrier.position.y < straight.position.y, "carrier follows slower straight path")
	session = isolated()
	for x: float in [0.0, 640.0]:
		var actor: CombatActor = session.spawn_enemy(CombatContent.SWARMER, x)
		actor.position = Vector2(x, CombatSession.BREACH_Y - 0.1)
	session.advance(0.1)
	context.check(session.breaches == 2 and is_equal_approx(session.run.shield.current, 26.0), "both far edges breach once through shield")
	session.advance(0.1)
	context.check(session.breaches == 2, "resolved breach cannot damage twice")
	session = isolated()
	var killed: CombatActor = session.spawn_enemy(CombatContent.SWARMER, 200.0)
	killed.position.y = CombatSession.BREACH_Y - 0.1
	killed.health = 8.0
	session.auto_fire = true
	session.advance(0.02)
	context.check(session.kills == 1 and session.breaches == 0 and session.hull == 100, "main-gun kill at boundary cannot also breach")
	session.damage_actor(killed, 99.0)
	context.check(session.kills == 1, "duplicate kill resolves once")
	session = isolated()
	session.run.shield.current = 10.0
	session.hit_station(25.0, &"fixture")
	context.check(session.run.shield.current == 0 and session.hull == 85, "shield absorbs ten and fifteen overflow reaches hull")
	context.check(session.activate_shield(), "active shield available")
	session.hit_station(20.0, &"fixture")
	context.check(session.hull == 80 and not session.activate_shield(), "brace reduces damage 75 percent and cannot repeat during cooldown")
	var snapshot: Array = [session.elapsed, session.hull, session.run.shield.current, session.ability_left, session.ability_wait, session.recharge_time, session.spawn_time]
	session.paused = true
	session.advance(20.0)
	session.hit_station(100, &"fixture")
	context.check(snapshot == [session.elapsed, session.hull, session.run.shield.current, session.ability_left, session.ability_wait, session.recharge_time, session.spawn_time], "pause freezes wave, firing, shield, recharge and all damage")
	session.paused = false
	session.advance(6.0)
	context.check(session.run.shield.current > 0, "shield recharges only after hit delay")
	session = isolated()
	carrier = session.spawn_enemy(CombatContent.CARRIER, 320)
	carrier.speed = 0.0
	session.hull = 10000.0
	session.advance(30.0)
	context.check(carrier.children_spawned == 3 and carrier.projectiles_fired == 3, "carrier remains capped after twelve ability intervals")
	context.check(session.actors.size() == 1, "finite reinforcements and shots resolve without stale actors")
	session = isolated()
	carrier = session.spawn_enemy(CombatContent.CARRIER, 320)
	var projectile: CombatActor = session.spawn_projectile(carrier)
	projectile.position.y = 600.0
	context.check(session.target() == projectile, "auto-aim can intercept the closest hostile shot")
	session.damage_actor(projectile, 8.0)
	context.check(projectile.resolved and session.intercepted == 1, "ordinary main pulse destroys ranged fixture")
	session.focus_active = true
	session.focus_point = carrier.position
	context.check(session.target() == carrier, "held focus selects target nearest the pointer")
	session.focus_active = false
	var near: CombatActor = session.spawn_enemy(CombatContent.DIVER, 200)
	near.position.y = 500
	context.check(session.target() == near, "release returns to nearest-to-breach targeting")
	# Ten natural full missions using the same session and signal subscription.
	session = CombatSession.new()
	var completions: Array[bool] = []
	session.finished.connect(func(victory: bool) -> void: completions.append(victory))
	for attempt: int in 10:
		session.restart()
		for tick: int in 12000:
			session.advance(CombatSession.STEP)
			if session.is_finished():
				break
		context.check(session.phase == CombatSession.Phase.VICTORY, "auto-aim completes three waves, run %d" % (attempt + 1))
		context.check(session.actors.is_empty() and completions.size() == attempt + 1, "one results signal and no stale actors, run %d" % (attempt + 1))
		print("M2 RUN %d: seconds=%.2f hull=%.1f shield=%.1f kills=%d breaches=%d intercepted=%d" % [attempt + 1, session.elapsed, session.hull, session.run.shield.current, session.kills, session.breaches, session.intercepted])
	session.restart()
	session.auto_fire = false
	for tick: int in 12000:
		session.advance(CombatSession.STEP)
		if session.is_finished(): break
	context.check(session.phase == CombatSession.Phase.DEFEAT and session.hull == 0, "unopposed authored enemies can destroy the station")
	context.check(not session.last_cause.is_empty() and session.breaches > 0, "defeat retains an attributable last hit and breach count")
	session.advance(999.0)
	session.hit_station(999.0, &"fixture")
	context.check(completions.size() == 11, "finished mission cannot emit results twice")
	session.run.main_weapon.rank = 8
	session.run.main_weapon.damage = 999
	session.run.temporary_modifier_ids.append(&"fixture")
	session.restart()
	context.check(session.actors.is_empty() and session.elapsed == 0 and session.ability_wait == 0 and session.spawn_index == 0 and session.shot_time == 0, "restart clears actors and all combat timers")
	context.check(session.run.main_weapon.rank == 1 and session.run.main_weapon.damage == 8 and session.run.shield.current == 50 and session.hull == 100 and session.run.temporary_modifier_ids.is_empty(), "restart restores rank one and fixed baseline with no inherited upgrades")
	context.check(CombatContent.MAIN.base_damage == 8 and CombatContent.SHIELD.base_capacity == 50, "missions never mutate shared definitions")
	return true
