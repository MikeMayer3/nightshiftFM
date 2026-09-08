class_name CombatSession
extends RefCounted
## Fixed-step, renderer-independent mission. No timers, listeners or actors survive reset.
signal finished(victory: bool)
signal station_hit(amount: float)
signal fired(target: Vector2)
signal wave_started(number: int)

enum Phase { INTERMISSION, COMBAT, VICTORY, DEFEAT }
const ARENA: Vector2 = Vector2(640, 720)
const SPAWN_BAND: Rect2 = Rect2(32, 32, 576, 40)
const BREACH_Y: float = 640.0
const TRANSMITTER: Vector2 = Vector2(320, 684)
const HULL_MAX: float = 100.0
const STEP: float = 1.0 / 60.0
var phase: Phase = Phase.INTERMISSION
var run: RunState
var actors: Array[CombatActor] = []
var hull: float = HULL_MAX
var wave: int = 0
var elapsed: float = 0.0
var phase_time: float = 0.0
var spawn_time: float = 0.0
var spawn_index: int = 0
var shot_time: float = 0.0
var recharge_time: float = 0.0
var ability_left: float = 0.0
var ability_wait: float = 0.0
var paused: bool = false
var auto_fire: bool = true
var focus_active: bool = false
var focus_point: Vector2
var kills: int = 0
var breaches: int = 0
var intercepted: int = 0
var damage_taken: float = 0.0
var last_cause: StringName = &"COMBAT_NO_DAMAGE"
var last_kind: StringName = &"COMBAT_BREACH_HIT"
var _serial: int = 0
var _accumulator: float = 0.0

func _init() -> void:
	restart()

func restart() -> void:
	run = RunState.new()
	run.main_weapon = WeaponState.from_definition(CombatContent.MAIN)
	run.shield = ShieldState.from_definition(CombatContent.SHIELD)
	actors.clear()
	hull = HULL_MAX
	wave = 0
	elapsed = 0.0
	phase_time = 2.0
	phase = Phase.INTERMISSION
	spawn_time = 0.0
	spawn_index = 0
	shot_time = 0.0
	recharge_time = 0.0
	ability_left = 0.0
	ability_wait = 0.0
	paused = false
	auto_fire = true
	focus_active = false
	kills = 0
	breaches = 0
	intercepted = 0
	damage_taken = 0.0
	last_cause = &"COMBAT_NO_DAMAGE"
	last_kind = &"COMBAT_BREACH_HIT"
	_serial = 0
	_accumulator = 0.0

func advance(delta: float) -> void:
	if paused or is_finished() or not is_finite(delta) or delta <= 0.0:
		return
	_accumulator += delta
	while _accumulator >= STEP and not is_finished():
		_accumulator -= STEP
		_step(STEP)

func is_finished() -> bool:
	return phase == Phase.VICTORY or phase == Phase.DEFEAT

func activate_shield() -> bool:
	if paused or is_finished() or ability_wait > 0.0:
		return false
	ability_left = CombatContent.SHIELD.ability_duration
	ability_wait = CombatContent.SHIELD.ability_cooldown
	return true

func spawn_enemy(definition: EnemyDefinition, x: float) -> CombatActor:
	_serial += 1
	var actor: CombatActor = CombatActor.from_definition(definition, _serial,
		Vector2(clampf(x, SPAWN_BAND.position.x, SPAWN_BAND.end.x), SPAWN_BAND.position.y + 20.0))
	actors.append(actor)
	return actor

func spawn_projectile(source: CombatActor) -> CombatActor:
	_serial += 1
	var actor: CombatActor = CombatActor.from_definition(CombatContent.SWARMER, _serial, source.position)
	actor.definition_id = &"m2.projectile"
	actor.name_key = &"COMBAT_PROJECTILE"
	actor.health = 8.0
	actor.max_health = 8.0
	actor.radius = 12.0
	actor.speed = 100.0
	actor.breach_damage = 15.0
	actor.projectile = true
	actors.append(actor)
	return actor

func target() -> CombatActor:
	var best: CombatActor
	var score: float = INF
	for actor: CombatActor in actors:
		if actor.resolved or actor.health <= 0.0:
			continue
		var candidate: float = actor.position.distance_squared_to(focus_point) if focus_active else BREACH_Y - actor.position.y
		if candidate < score:
			best = actor
			score = candidate
	return best

func damage_actor(actor: CombatActor, amount: float) -> void:
	if paused or is_finished() or actor.resolved or amount <= 0.0 or not is_finite(amount):
		return
	actor.health = maxf(0.0, actor.health - amount)
	if actor.health == 0.0:
		actor.resolved = true
		if actor.projectile:
			intercepted += 1
		else:
			kills += 1

func hit_station(amount: float, cause: StringName, kind: StringName = &"COMBAT_BREACH_HIT") -> void:
	if paused or is_finished() or not is_finite(amount) or amount <= 0.0:
		return
	# Capacitor active: 75% damage reduction, still shield-first; never reflects.
	var incoming: float = amount * (0.25 if ability_left > 0.0 else 1.0)
	var absorbed: float = minf(run.shield.current, incoming)
	run.shield.current -= absorbed
	hull = maxf(0.0, hull - (incoming - absorbed))
	recharge_time = CombatContent.SHIELD.recharge_delay
	damage_taken += incoming
	last_cause = cause
	last_kind = kind
	station_hit.emit(incoming)
	if hull == 0.0:
		_finish(false)

func _step(delta: float) -> void:
	elapsed += delta
	ability_left = maxf(0.0, ability_left - delta)
	ability_wait = maxf(0.0, ability_wait - delta)
	recharge_time = maxf(0.0, recharge_time - delta)
	if recharge_time == 0.0:
		run.shield.current = minf(run.shield.capacity, run.shield.current + CombatContent.SHIELD.recharge_rate * delta)
	if phase == Phase.INTERMISSION:
		phase_time -= delta
		if phase_time <= 0.0:
			wave += 1
			phase = Phase.COMBAT
			spawn_index = 0
			spawn_time = 0.0
			wave_started.emit(wave)
		return
	var definition: WaveDefinition = CombatContent.waves()[wave - 1]
	spawn_time -= delta
	if spawn_index < definition.enemy_ids.size() and spawn_time <= 0.0:
		spawn_enemy(CombatContent.enemy(definition.enemy_ids[spawn_index]), 64.0 + float((spawn_index * 173 + wave * 67) % 512))
		spawn_index += 1
		spawn_time += definition.spawn_interval
	# Resolve main-gun kills before movement/breach in the same fixed step.
	shot_time = maxf(0.0, shot_time - delta)
	var aimed: CombatActor = target()
	if auto_fire and shot_time == 0.0 and aimed != null:
		fired.emit(aimed.position)
		damage_actor(aimed, run.main_weapon.damage)
		shot_time = CombatContent.MAIN.attack_interval
	var active: Array[CombatActor] = actors.duplicate()
	for actor: CombatActor in active:
		if actor.resolved:
			continue
		actor.advance(delta)
		if actor.position.y >= BREACH_Y:
			actor.resolved = true
			if not actor.projectile:
				breaches += 1
			hit_station(actor.breach_damage, actor.name_key,
				&"COMBAT_PROJECTILE_HIT" if actor.projectile else &"COMBAT_BREACH_HIT")
			if is_finished():
				return
			continue
		actor.ability_time += delta
		if actor.ability_time >= actor.ability_interval:
			actor.ability_time -= actor.ability_interval
			if actor.children_spawned < actor.child_limit:
				# Reinforcements always enter through the top band, not mid-field.
				spawn_enemy(CombatContent.enemy(actor.child_id), actor.position.x + float(actor.children_spawned - 1) * 48.0)
				actor.children_spawned += 1
			if actor.projectiles_fired < actor.projectile_limit:
				spawn_projectile(actor)
				actor.projectiles_fired += 1
	actors = actors.filter(func(actor: CombatActor) -> bool: return not actor.resolved)
	if actors.is_empty() and spawn_index == definition.enemy_ids.size():
		if wave == CombatContent.waves().size():
			_finish(true)
		else:
			phase = Phase.INTERMISSION
			phase_time = 2.0

func _finish(victory: bool) -> void:
	if is_finished():
		return
	phase = Phase.VICTORY if victory else Phase.DEFEAT
	actors.clear()
	focus_active = false
	_accumulator = 0.0
	finished.emit(victory)
