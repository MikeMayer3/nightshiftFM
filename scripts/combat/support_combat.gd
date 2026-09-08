class_name SupportCombat
extends RefCounted
## M4-only support behavior. No dependency on presentation; finite target/field budgets.
var timers: Dictionary = {"arc_aerial": 0.0, "bass_driver": 0.0, "static_net": 0.0}
var report: ContributionReport = ContributionReport.new()
var field: Dictionary = {}
var shocks: Array[Dictionary] = []
var restore_wait: float = 0.0
var reservoir: float = 0.0
var overshield: float = 0.0
var overshield_left: float = 0.0

static func mode(owned: UpgradeTrack) -> int:
	return int(owned.stats.get(&"mode", 0))

static func modifier(owned: UpgradeTrack) -> int:
	return int(owned.stats.get(&"modifier", 0))

static func capped(owned: UpgradeTrack) -> bool:
	return float(owned.stats.get(&"capstone", 0)) > 0

static func attack_interval(owned: UpgradeTrack) -> float:
	var interval: float = float(owned.stats[&"interval"])
	match owned.definition.id:
		&"arc_aerial":
			if mode(owned) == 1 and modifier(owned) == 1: interval *= 1.2
			if mode(owned) == 2 and modifier(owned) == 1: interval *= 0.7
			if mode(owned) == 3 and modifier(owned) == 2: interval *= 1.5
		&"bass_driver":
			if mode(owned) == 2 and modifier(owned) == 1: interval *= 1.25
		&"static_net":
			if mode(owned) == 1 and modifier(owned) == 1: interval *= 1.25
	return maxf(0.25, interval)

func recharge_fraction(owned: UpgradeTrack) -> float:
	return clampf(1.0 - float(timers[String(owned.definition.id)]) / attack_interval(owned), 0, 1)

func tick_passive(delta: float) -> void:
	restore_wait = maxf(0, restore_wait - delta)
	overshield_left = maxf(0, overshield_left - delta)
	if overshield_left == 0: overshield = 0

func advance(session: CombatSession, delta: float) -> void:
	for id: String in timers:
		timers[id] = maxf(0, float(timers[id]) - delta)
		var owned: UpgradeTrack = session.draft.track(StringName(id))
		if owned == null or not session.auto_fire or session.target() == null or timers[id] > 0: continue
		match id:
			"arc_aerial":
				arc(session, owned, session.target())
			"bass_driver":
				bass(session, owned, session.target())
			"static_net":
				deploy_net(session, owned, session.target().position)
		timers[id] = attack_interval(owned)
	_tick_field(session, delta)
	_tick_shocks(session, delta)

func _root(session: CombatSession, source: StringName, target: int) -> int:
	session.attack_serial += 1
	session._event(CombatEvent.Kind.ATTACK, source, session.attack_serial, target, 0)
	return session.attack_serial

func arc(session: CombatSession, owned: UpgradeTrack, first: CombatActor) -> void:
	var root: int = _root(session, &"arc_aerial", first.serial)
	var damage: float = float(owned.stats[&"damage"])
	var reach: float = float(owned.stats[&"range"])
	var targets: int = int(owned.stats[&"targets"])
	if mode(owned) == 1:
		damage *= 0.8
		targets += 2 + (2 if capped(owned) else 0)
		if modifier(owned) == 1: reach += 120
		if modifier(owned) == 2:
			reach *= 0.6
			damage *= 1.35
	elif mode(owned) == 2:
		targets = 1
		damage *= 0.6
	var hit: Array[int] = []
	var contacts: Array[Vector2] = []
	var victim: CombatActor = first
	var origin: Vector2 = CombatSession.TRANSMITTER
	for _index: int in mini(6, targets):
		if victim == null: break
		hit.append(victim.serial)
		contacts.append(victim.position)
		session.chain_fired.emit(PackedVector2Array([origin, victim.position]), true)
		session.damage_actor(victim, damage * (1.0 + victim.status.charged * 0.05), &"arc_aerial", root)
		victim.status.charge()
		if mode(owned) == 2 and restore_wait == 0:
			restore_wait = 0.8
			reservoir = minf(12, reservoir + 2)
			if modifier(owned) != 2: heal(session, 1.5 if modifier(owned) == 1 else 2.0, &"arc_aerial")
		var origins: Array[Vector2] = [victim.position]
		if capped(owned) and mode(owned) == 1: origins = contacts
		victim = null
		var nearest: float = reach
		for endpoint: Vector2 in origins:
			for candidate: CombatActor in session.actors:
				if candidate.resolved or candidate.serial in hit: continue
				var distance: float = endpoint.distance_to(candidate.position)
				if distance <= nearest:
					nearest = distance
					victim = candidate
					origin = endpoint

func heal(session: CombatSession, amount: float, source: StringName) -> void:
	var effective: float = minf(amount, session.run.shield.capacity - session.run.shield.current)
	session.run.shield.current += effective
	report.add(source, &"healing", effective)
	if effective > 0: session._event(CombatEvent.Kind.SHIELD_HEAL, source, 0, 0, effective)

func brace(session: CombatSession) -> void:
	var owned: UpgradeTrack = session.draft.track(&"arc_aerial")
	if mode(owned) != 2: return
	if capped(owned) and reservoir >= 12:
		overshield = 10
		overshield_left = 4
	if modifier(owned) == 2: heal(session, reservoir, &"arc_aerial")
	reservoir = 0

func bass(session: CombatSession, owned: UpgradeTrack, target: CombatActor) -> void:
	var root: int = _root(session, &"bass_driver", target.serial)
	var radius: float = float(owned.stats[&"radius"])
	var dimensions: Vector2 = Vector2.ONE * radius
	if mode(owned) == 1:
		dimensions *= 1.4
		if modifier(owned) == 1: dimensions *= Vector2(1.5, 0.65)
		if modifier(owned) == 2: dimensions *= Vector2(0.7, 1.6)
	elif mode(owned) == 2: dimensions *= 0.65
	if capped(owned) and mode(owned) == 1:
		shocks.append({"y": 640.0, "root": root, "hit": [], "width": dimensions.x, "x": target.position.x, "end_y": 640.0 - minf(600.0, 360.0 * dimensions.y / (radius * 1.4))})
		return
	var center: Vector2 = target.position
	session.support_effect.emit(&"bass_driver", center, dimensions)
	var count: int = 0
	for actor: CombatActor in session.actors.duplicate():
		if actor.resolved or actor.projectile: continue
		if ((actor.position - center) / dimensions).length_squared() <= 1:
			_bass_hit(session, owned, actor, root)
			count += 1
			if count == 8: break

func _bass_hit(session: CombatSession, owned: UpgradeTrack, actor: CombatActor, root: int) -> void:
	var damage: float = float(owned.stats[&"damage"])
	var exposure: float = float(owned.stats[&"exposure"])
	var push: float = float(owned.stats[&"push"])
	if mode(owned) == 1: damage *= 0.8
	if mode(owned) == 2:
		damage *= 1.5
		exposure += 25
		if modifier(owned) == 1: exposure += 25
		if modifier(owned) == 2:
			push *= 0.5
			if actor.elite: damage *= 1.5
		if capped(owned):
			damage *= 1.5
			exposure += 20
	actor.status.expose(exposure)
	session.damage_actor(actor, damage, &"bass_driver", root)
	if actor.resolved: return
	if actor.displacement_immune:
		actor.status.apply_slow(0.15, actor.elite, &"bass_driver")
	else:
		var displacement: float = minf(push * (0.25 if actor.elite else 1.0), maxf(0, actor.position.y - 32))
		actor.position.y -= displacement
		report.add(&"bass_driver", &"push_distance", displacement)

func deploy_net(session: CombatSession, owned: UpgradeTrack, at: Vector2) -> void:
	var radius: float = float(owned.stats[&"radius"])
	var duration: float = float(owned.stats[&"duration"])
	var charges: int = int(owned.stats[&"charges"])
	var strength: float = float(owned.stats[&"slow"])
	var jam: float = 0
	if mode(owned) == 1:
		strength += 0.15
		jam = 0.35
		if modifier(owned) == 1: jam = 0.7
		if modifier(owned) == 2:
			duration += 1.5
			jam = 0.15
		if capped(owned):
			duration += 1
			jam += 0.25
	elif mode(owned) == 2:
		strength *= 0.5
		charges += 3
		if modifier(owned) == 1:
			radius *= 0.75
			charges += 3
		if modifier(owned) == 2:
			radius *= 1.4
			charges -= 1
		if capped(owned):
			charges = 12
			duration += 1
	field = {"position": Vector2(at.x, minf(480, at.y)), "radius": radius, "left": duration,
		"charges": mini(12, charges), "slow": strength, "jam": jam, "root": _root(session, &"static_net", 0)}

func _tick_field(session: CombatSession, delta: float) -> void:
	if field.is_empty(): return
	field.left -= delta
	if field.left <= 0:
		field.clear()
		return
	for actor: CombatActor in session.actors:
		if actor.resolved or actor.position.distance_to(field.position) > float(field.radius): continue
		if actor.projectile:
			if field.charges > 0:
				field.charges -= 1
				session.damage_actor(actor, actor.health, &"static_net", int(field.root))
		else:
			actor.status.apply_slow(float(field.slow), actor.elite)
			if field.jam > 0 and actor.status.jam(float(field.jam), actor.elite, actor.jam_immune):
				report.add(&"static_net", &"interrupts", 1)

func _tick_shocks(session: CombatSession, delta: float) -> void:
	var owned: UpgradeTrack = session.draft.track(&"bass_driver")
	for shock: Dictionary in shocks:
		var before: float = float(shock.y)
		shock.y -= 400 * delta
		for actor: CombatActor in session.actors:
			if actor.resolved or actor.projectile or actor.serial in shock.hit or shock.hit.size() >= 12: continue
			if absf(actor.position.x - float(shock.x)) <= float(shock.width) and actor.position.y >= float(shock.y) - actor.radius and actor.position.y <= before + actor.radius:
				shock.hit.append(actor.serial)
				_bass_hit(session, owned, actor, int(shock.root))
	shocks = shocks.filter(func(s: Dictionary) -> bool: return s.y > s.end_y)

func clear_wave_effects() -> void:
	field.clear()
	shocks.clear()

func to_data() -> Dictionary:
	return {"timers": timers.duplicate(), "report": report.totals.duplicate(true), "restore_wait": restore_wait,
		"reservoir": reservoir, "overshield": overshield, "overshield_left": overshield_left}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6 or not data.get("timers") is Dictionary or data.timers.size() != 3: return false
	for id: String in timers:
		if not SaveChecks.number(data.timers.get(id), 0, 10): return false
	for key: String in ["restore_wait", "reservoir", "overshield", "overshield_left"]:
		if not SaveChecks.number(data.get(key), 0, 12): return false
	if data.restore_wait > 0.8 or data.overshield > 10 or data.overshield_left > 4: return false
	if not report.restore(data.get("report")): return false
	timers = data.timers.duplicate()
	restore_wait = float(data.restore_wait)
	reservoir = float(data.reservoir)
	overshield = float(data.overshield)
	overshield_left = float(data.overshield_left)
	return true
