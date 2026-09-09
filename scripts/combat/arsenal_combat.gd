class_name ArsenalCombat
extends SupportCombat
## M5 runtime: bounded packets, traveling needles, persistent fields and shield state.
## Every generated packet keeps its original root and cannot become an echo source.
var packets: Array[Dictionary] = []
var recordings: Array[Dictionary] = []
var needles: Array[Dictionary] = []
var zones: Array[Dictionary] = []
var marks: Array[Dictionary] = []
var echo_count: float = 0.0
var shield_charge: float = 0
var emergency_wait: float = 0
var peak_pending: int = 0

func _init() -> void:
	timers.clear()
	var ids: Array[StringName] = [&"main", &"shield"]
	ids.append_array(ArsenalContent.FAMILIES)
	report = ContributionReport.new(ids)
	for id: StringName in ArsenalContent.FAMILIES: timers[String(id)] = 0.0

func recharge_fraction(owned: UpgradeTrack) -> float:
	if owned.definition.id == &"echo_deck":
		return clampf(float(echo_count) / float(ArsenalStats.parameters(owned).attacks), 0, 1)
	return clampf(1 - float(timers[String(owned.definition.id)]) / float(ArsenalStats.parameters(owned).interval), 0, 1)

func advance(session: CombatSession, delta: float) -> void:
	emergency_wait = maxf(0, emergency_wait - delta)
	for id: String in timers:
		timers[id] = maxf(0, float(timers[id]) - delta)
		var owned: UpgradeTrack = session.draft.track(StringName(id))
		if owned == null or id == "echo_deck" or not session.auto_fire or session.target() == null or timers[id] > 0: continue
		# Wait for capacity instead of creating and silently dropping a damaging attack.
		if needles.size() > 112 or zones.size() > 20: continue
		var p: Dictionary = ArsenalStats.parameters(owned)
		var first: CombatActor = session.target()
		var root: int = _root(session, StringName(id), first.serial)
		if id == "arc_aerial": _arc(session, first, p, root)
		elif id == "needle_swarm": _needles(session, first, p, root)
		else: _deploy(session, first.position, StringName(id), p, root)
		timers[id] = p.interval
	_tick_packets(session, delta)
	_tick_needles(session, delta)
	_tick_zones(session, delta)
	for mark: Dictionary in marks: mark.left = maxf(0, float(mark.left) - delta)
	marks = marks.filter(func(m: Dictionary) -> bool: return m.left > 0 and actor_by_id(session, int(m.target)) != null)
	peak_pending = maxi(peak_pending, packets.size() + needles.size() + zones.size())

static func actor_by_id(session: CombatSession, serial: int) -> CombatActor:
	for actor: CombatActor in session.actors:
		if actor.serial == serial and not actor.resolved: return actor
	return null

func mark_strength(serial: int) -> float:
	for mark: Dictionary in marks:
		if int(mark.target) == serial: return float(mark.strength)
	return 0

func hit(session: CombatSession, actor: CombatActor, p: Dictionary, source: StringName, root: int, amount: float = -1) -> void:
	var damage: float = float(p.damage) if amount < 0 else amount
	if actor.elite: damage *= 1 + float(p.get(&"elite_bonus", 0))
	if session.random.rng("combat").randf() < float(p.get(&"crit", 0)): damage *= 1.75
	session.damage_actor(actor, damage, source, root, float(p.get(&"penetration", 0)))

func fire_main(session: CombatSession, first: CombatActor) -> void:
	var p: Dictionary = ArsenalStats.parameters(session.draft.track(&"main"))
	var chassis: String = (session.draft as ArsenalDraft).loadout.main
	if first.position.distance_to(CombatSession.TRANSMITTER) > float(p.reach): return
	var root: int = _root(session, &"main", first.serial)
	var packet: Dictionary = {"source": "main", "kind": chassis, "root": root, "target": first.serial, "x": first.position.x, "y": first.position.y, "left": 0.0, "p": p.duplicate(true)}
	if chassis == "burst" and p.get(&"stagger", 0) > 0:
		var count: int = int(p.projectiles)
		for index: int in count:
			var part: Dictionary = packet.duplicate(true)
			part.p.projectiles = 1
			part.left = index * .09
			packets.append(part)
	else: _resolve_packet(session, packet)
	_record_echo(session, packet)

func _record_echo(session: CombatSession, packet: Dictionary) -> void:
	var owned: UpgradeTrack = session.draft.track(&"echo_deck")
	if owned == null or packet.source != "main": return
	var e: Dictionary = ArsenalStats.parameters(owned)
	recordings.append(packet.duplicate(true))
	if recordings.size() > 12: recordings.pop_front()
	echo_count += 1 + ModuleStats.coefficient(session.module_ids(), &"support_rate")
	if echo_count < int(e.attacks): return
	if packets.size() > 112: return # pending replay remains ready, no recursive work generation
	echo_count = maxf(0, echo_count - float(e.attacks)) if session.campaign != null else 0.0
	for index: int in int(e.copies):
		var copy: Dictionary = recordings[maxi(0, recordings.size() - int(e.copies)) + index % mini(recordings.size(), int(e.copies))].duplicate(true) if int(e.mode) == 2 else packet.duplicate(true)
		copy.source = "echo_deck"
		copy.left = float(e.delay) + index * .12
		copy.p.damage *= maxf(.1, float(e.echo_damage))
		copy.p.crit = e.crit
		copy.p[&"retarget"] = e.reach
		copy.p[&"distinct"] = e.get(&"distinct", 0)
		copy.p[&"priority"] = e.get(&"priority", 0)
		copy.p[&"copy_index"] = index
		packets.append(copy)

func _tick_packets(session: CombatSession, delta: float) -> void:
	var ready: Array[Dictionary] = []
	for packet: Dictionary in packets:
		packet.left = maxf(0, float(packet.left) - delta)
		if packet.left == 0: ready.append(packet)
	packets = packets.filter(func(p: Dictionary) -> bool: return p.left > 0)
	for packet: Dictionary in ready:
		if packet.source == "echo_deck": session._event(CombatEvent.Kind.ATTACK, &"echo_deck", int(packet.root), int(packet.target), 0)
		_resolve_packet(session, packet)

func _resolve_packet(session: CombatSession, packet: Dictionary) -> void:
	# Per-resolution tuning cannot leak into an echo recording or shared packet.
	var p: Dictionary = packet.p.duplicate(true)
	var assisted: StringName = &""
	var first: CombatActor = actor_by_id(session, int(packet.target))
	var center: Vector2 = Vector2(float(packet.x), float(packet.y))
	if packet.source == "echo_deck":
		var candidates: Array[CombatActor] = nearby(session, center, float(p.retarget), 12)
		if p.get(&"distinct", 0) > 0 and candidates.size() > 1: candidates = candidates.filter(func(a: CombatActor) -> bool: return a.serial != int(packet.target))
		if p.get(&"priority", 0) > 0: candidates.sort_custom(func(a: CombatActor, b: CombatActor) -> bool: return priority(a) > priority(b))
		if not candidates.is_empty(): first = candidates[int(p.copy_index) % candidates.size()] if p.get(&"distinct", 0) > 0 else candidates[0]
		else: first = null
		if session.patchboard != null and session.patchboard.connected(session, &"b_side"):
			var marked: Array[CombatActor] = candidates.filter(func(a: CombatActor) -> bool: return mark_strength(a.serial) > 0)
			if not marked.is_empty() and session.patchboard.activate(session, &"b_side"):
				first = marked[int(p.copy_index) % marked.size()]
				assisted = &"b_side"
	if first == null: return
	if packet.source == "main" and session.patchboard != null and mark_strength(first.serial) > 0 and session.patchboard.activate(session, &"needle_thread"):
		var recipe: SynergyDefinition = PatchboardContent.RECIPES[&"needle_thread"]
		if packet.kind == "sweep": p.damage *= 1 + recipe.coefficient
		elif packet.kind == "burst": p.penetration += recipe.damage
		else: p.pierce = mini(11, int(p.pierce) + 1)
		assisted = &"needle_thread"
	var source: StringName = StringName(packet.source)
	var root: int = int(packet.root)
	var direction: Vector2 = (first.position - CombatSession.TRANSMITTER).normalized()
	var targets: Array[CombatActor] = [first]
	if packet.kind == "burst":
		targets = nearby(session, first.position, float(p.width), 12)
		for index: int in int(p.projectiles):
			if targets.is_empty(): break
			var victim: CombatActor = targets[index % targets.size()]
			session.chain_fired.emit(PackedVector2Array([CombatSession.TRANSMITTER, victim.position]), false)
			var before: float = victim.health
			hit(session, victim, p, source, root)
			if assisted != &"" and not victim.projectile: session.patchboard.add(assisted, "assisted_damage", before - victim.health)
	else:
		var limit: int = 12 if packet.kind == "sweep" else 1 + int(p.pierce)
		var ordered: Array[CombatActor] = session.actors.duplicate()
		ordered.sort_custom(func(a: CombatActor, b: CombatActor) -> bool: return a.position.y > b.position.y)
		for actor: CombatActor in ordered:
			if targets.size() >= limit: break
			var offset: Vector2 = actor.position - CombatSession.TRANSMITTER
			if actor == first or actor.resolved or offset.length() > float(p.reach): continue
			if offset.dot(direction) > 0 and absf(offset.cross(direction)) <= float(p.width): targets.append(actor)
		var bounces: int = int(p.get(&"bounce", 0))
		for actor: CombatActor in nearby(session, first.position, minf(300, float(p.reach)), 12):
			if bounces <= 0: break
			if actor in targets: continue
			targets.append(actor)
			bounces -= 1
		for actor: CombatActor in targets:
			session.chain_fired.emit(PackedVector2Array([CombatSession.TRANSMITTER, actor.position]), false)
			var before: float = actor.health
			hit(session, actor, p, source, root)
			if assisted != &"" and not actor.projectile: session.patchboard.add(assisted, "assisted_damage", before - actor.health)
	if source == &"echo_deck": session.support_effect.emit(source, first.position, Vector2(30, 30))

func priority(actor: CombatActor) -> float:
	return (1000 if actor.elite else 0) + mark_strength(actor.serial) * 1000 + actor.position.y

static func nearby(session: CombatSession, center: Vector2, radius: float, limit: int) -> Array[CombatActor]:
	var result: Array[CombatActor] = session.actors.filter(func(a: CombatActor) -> bool: return not a.resolved and a.position.distance_to(center) <= radius)
	result.sort_custom(func(a: CombatActor, b: CombatActor) -> bool: return a.position.distance_squared_to(center) < b.position.distance_squared_to(center))
	if result.size() > limit: result.resize(limit)
	return result

func _arc(session: CombatSession, first: CombatActor, p: Dictionary, root: int) -> void:
	var targets: Array[CombatActor] = [first]
	var last: CombatActor = first
	for index: int in int(p.targets) - 1:
		var choices: Array[CombatActor] = nearby(session, last.position, float(p.reach), 12)
		last = null
		for actor: CombatActor in choices:
			if actor not in targets:
				last = actor
				break
		if last == null: break
		targets.append(last)
	if int(p.mode) == 2 and int(p.pierce) > 0:
		var direction: Vector2 = (first.position - CombatSession.TRANSMITTER).normalized()
		for actor: CombatActor in nearby(session, first.position, float(p.reach), 12):
			if targets.size() >= 1 + int(p.pierce): break
			if actor not in targets and absf((actor.position - first.position).cross(direction)) < float(p.width): targets.append(actor)
	var origin: Vector2 = CombatSession.TRANSMITTER
	for actor: CombatActor in targets:
		session.chain_fired.emit(PackedVector2Array([origin, actor.position]), true)
		origin = actor.position
		hit(session, actor, p, &"arc_aerial", root, float(p.damage) * (1 + actor.status.charged * .05))
		if session.patchboard != null: session.patchboard.arc_hit(session, actor, root)
		actor.status.charge()
		actor.status.charge_left = p.duration
	if p.get(&"healing", 0) > 0 and restore_wait <= 0:
		restore_wait = .7
		if p.get(&"reserve", 0) > 0: reservoir = minf(20, reservoir + float(p.healing))
		else: heal(session, float(p.healing), &"arc_aerial")
		if p.get(&"overheal", 0) > 0 and (reservoir >= 20 or session.run.shield.current >= session.run.shield.capacity):
			overshield = minf(10, overshield + 2)
			overshield_left = 4

func _needles(session: CombatSession, first: CombatActor, p: Dictionary, root: int) -> void:
	var targets: Array[CombatActor] = nearby(session, first.position, float(p.reach), 12)
	if p.get(&"priority", 0) > 0: targets.sort_custom(func(a: CombatActor, b: CombatActor) -> bool: return priority(a) > priority(b))
	for index: int in int(p.projectiles):
		var target: CombatActor = targets[index % targets.size()]
		var origin: Vector2 = Vector2(320 + (index - int(p.projectiles) / 2) * 7, 678)
		var direction: Vector2 = (target.position - origin).normalized()
		needles.append({"x": origin.x, "y": origin.y, "dx": direction.x, "dy": direction.y, "target": target.serial, "root": root, "left": float(p.duration), "hits": [], "p": p.duplicate(true)})
	session.support_effect.emit(&"needle_swarm", first.position, Vector2(20, 20))

func _tick_needles(session: CombatSession, delta: float) -> void:
	for needle: Dictionary in needles:
		needle.left = maxf(0, float(needle.left) - delta)
		var p: Dictionary = needle.p
		var start: Vector2 = Vector2(needle.x, needle.y)
		var direction: Vector2 = Vector2(needle.dx, needle.dy)
		var target: CombatActor = actor_by_id(session, int(needle.target))
		if target == null:
			var candidates: Array[CombatActor] = nearby(session, start, float(p.reach), 12)
			for candidate: CombatActor in candidates:
				if candidate.serial not in needle.hits:
					target = candidate
					needle.target = target.serial
					break
		if target != null and float(p.steering) > 0:
			direction = direction.slerp((target.position - start).normalized(), clampf(float(p.steering) * delta, 0, 1)).normalized()
		var end: Vector2 = start + direction * float(p.speed) * delta
		needle.dx = direction.x
		needle.dy = direction.y
		needle.x = clampf(end.x, 0, 640)
		needle.y = clampf(end.y, 0, 720)
		for actor: CombatActor in session.actors:
			if actor.resolved or actor.serial in needle.hits: continue
			if actor.position.distance_to(Geometry2D.get_closest_point_to_segment(actor.position, start, end)) > actor.radius + 4: continue
			var amount: float = float(p.damage) * maxf(.25, 1 - needle.hits.size() * float(p.get(&"falloff", 0)))
			hit(session, actor, p, &"needle_swarm", int(needle.root), amount)
			needle.hits.append(actor.serial)
			if p.get(&"mark", 0) > 0 and not actor.projectile:
				marks = marks.filter(func(m: Dictionary) -> bool: return int(m.target) != actor.serial)
				marks.append({"target": actor.serial, "strength": minf(.5, float(p.mark)), "left": float(p.duration)})
			if needle.hits.size() >= 1 + int(p.pierce):
				needle.left = 0
				break
		if not Rect2(Vector2.ZERO, CombatSession.ARENA).has_point(end): needle.left = 0
	needles = needles.filter(func(n: Dictionary) -> bool: return n.left > 0)

func _deploy(session: CombatSession, at: Vector2, source: StringName, p: Dictionary, root: int) -> void:
	# Net refreshes its one field; wells and aftershocks have explicit independent lifetimes.
	if source == &"static_net": zones = zones.filter(func(z: Dictionary) -> bool: return z.source != "static_net")
	var count: int = 1 + int(p.get(&"pulses", 0)) if source == &"bass_driver" else 0
	zones.append({"source": String(source), "x": at.x, "y": at.y, "root": root, "left": float(p.duration), "tick": 0.0, "remaining": count, "charges": int(p.get(&"charges", 0)), "p": p.duplicate(true)})
	session.support_effect.emit(source, at, Vector2.ONE * float(p.radius))
	if source == &"bass_driver" and session.patchboard != null: session.patchboard.bass_activation(session, at, p, root)

func _tick_zones(session: CombatSession, delta: float) -> void:
	for zone: Dictionary in zones:
		var p: Dictionary = zone.p
		var source: StringName = StringName(zone.source)
		var center: Vector2 = Vector2(zone.x, zone.y)
		zone.left = maxf(0, float(zone.left) - delta)
		zone.tick = maxf(0, float(zone.tick) - delta)
		var targets: Array[CombatActor] = nearby(session, center, float(p.radius), int(p.targets) if source == &"reverb_well" else 12)
		if zone.tick == 0 and session.patchboard != null:
			if source == &"static_net": session.patchboard.net_tick(session, targets, center, int(zone.root))
			elif source == &"bass_driver": session.patchboard.bass_pulse(session, targets, int(zone.root))
		for actor: CombatActor in targets:
			if actor.projectile:
				if source == &"static_net" and int(zone.charges) > 0:
					session.damage_actor(actor, actor.health, source, int(zone.root), 100)
					zone.charges -= 1
				continue
			if source == &"static_net":
				actor.status.apply_slow(float(p.slow), actor.elite, source)
				actor.status.slow_left = maxf(actor.status.slow_left, float(p.residual))
				if p.get(&"jam", 0) > 0 and actor.status.jam(float(p.jam), actor.elite, actor.jam_immune): report.add(source, &"interrupts", 1)
			if source == &"reverb_well":
				var offset: Vector2 = center - actor.position
				if p.get(&"orbit", 0) > 0: offset = offset.rotated(1.0)
				if not actor.displacement_immune:
					var move: Vector2 = offset.limit_length(float(p.pull) * delta * (.25 if actor.elite else 1))
					actor.position += move
					report.add(source, &"push_distance", move.length())
				else: actor.status.apply_slow(.15, actor.elite, source)
				if p.get(&"slow", 0) > 0: actor.status.apply_slow(float(p.slow), actor.elite, source)
			if zone.tick == 0:
				if p.get(&"exposure", 0) > 0:
					actor.status.expose(float(p.exposure), source)
					actor.status.exposure_left = p.duration
				if source == &"bass_driver":
					if not actor.displacement_immune:
						var distance: float = minf(actor.position.y - 32, float(p.push) * (.25 if actor.elite else 1))
						actor.position.y -= maxf(0, distance)
						report.add(source, &"push_distance", distance)
					else: actor.status.apply_slow(.15, actor.elite, source)
				hit(session, actor, p, source, int(zone.root))
		if zone.tick == 0:
			zone.tick = float(p.duration) / maxf(1, 1 + float(p.get(&"pulses", 0))) if source == &"bass_driver" else .6 / maxf(.3, 1 + float(p.get(&"tick_rate", 0)))
			if source == &"bass_driver":
				zone.remaining -= 1
				if zone.remaining <= 0: zone.left = 0
			session.support_effect.emit(source, center, Vector2.ONE * float(p.radius))
		if zone.left == 0 and source == &"reverb_well":
			for actor: CombatActor in targets:
				if actor.projectile or actor.resolved: continue
				if p.get(&"terminal", 0) > 0: hit(session, actor, p, source, int(zone.root), float(p.terminal) * mini(8, targets.size()))
				if p.get(&"release", 0) > 0 and not actor.displacement_immune:
					var move: float = minf(actor.position.y - 32, float(p.release) * (.25 if actor.elite else 1))
					actor.position.y -= maxf(0, move)
					report.add(source, &"push_distance", move)
	zones = zones.filter(func(z: Dictionary) -> bool: return z.left > 0)

func shield_parameters(session: CombatSession) -> Dictionary:
	return ArsenalStats.parameters(session.draft.track(&"shield"))

func shield_activate(session: CombatSession) -> void:
	var p: Dictionary = shield_parameters(session)
	var chassis: String = (session.draft as ArsenalDraft).loadout.shield
	session.ability_left = float(p.duration)
	session.ability_wait = float(p.cooldown)
	if chassis == "capacitor":
		overshield = minf(40, overshield + 20 + float(p.get(&"emergency", 0)) * .25)
		overshield_left = float(p.duration)
	elif chassis == "relay":
		session.recharge_time = 0
		heal(session, 8 + float(p.get(&"recovery", 0)), &"shield")
	if reservoir > 0:
		heal(session, reservoir, &"arc_aerial")
		reservoir = 0
	if shield_charge > 0:
		retaliate(session, shield_charge, 250)
		shield_charge = 0

func before_station_hit(session: CombatSession, amount: float, projectile: bool, incoming_root: int = 0) -> float:
	var p: Dictionary = shield_parameters(session)
	var incoming: float = amount * (1 - clampf(float(p.mitigation), 0, .65))
	if session.ability_left > 0 and (session.draft as ArsenalDraft).loadout.shield == "feedback" and projectile:
		retaliate(session, amount + float(p.get(&"reflect", 0)), 1000, incoming_root)
		report.add(&"shield", &"absorbed", incoming)
		return 0
	shield_charge = minf(80, shield_charge + incoming * float(p.get(&"retaliation", 0)))
	return incoming

func after_station_hit(session: CombatSession, broke: bool) -> void:
	var p: Dictionary = shield_parameters(session)
	session.recharge_time = float(p.delay)
	if broke:
		session.recharge_time = maxf(.1, session.recharge_time - float(p.break_recovery) * .1)
		if p.get(&"break_damage", 0) > 0: retaliate(session, float(p.break_damage), 220 + float(p.get(&"shield_radius", 0)))
	if session.run.shield.current < session.run.shield.capacity * .25 and emergency_wait == 0 and p.get(&"emergency", 0) > 0:
		heal(session, float(p.emergency), &"shield")
		emergency_wait = float(p.cooldown)

func retaliate(session: CombatSession, damage: float, radius: float, incoming_root: int = 0) -> void:
	damage *= ModuleStats.damage_multiplier(session.module_ids(), &"shield")
	radius = ModuleStats.area_radius(session.module_ids(), radius)
	var root: int = incoming_root if incoming_root > 0 else _root(session, &"shield", 0)
	if incoming_root > 0: session._event(CombatEvent.Kind.ATTACK, &"shield", root, 0, 0)
	for actor: CombatActor in nearby(session, CombatSession.TRANSMITTER, radius, 8):
		# Generated outgoing damage cannot hit the station or generate another reflection.
		session.damage_actor(actor, damage, &"shield", root, 20)
	session.support_effect.emit(&"shield", CombatSession.TRANSMITTER, Vector2.ONE * minf(radius, 250))

func clear_wave_effects() -> void:
	super.clear_wave_effects()
	packets.clear()
	recordings.clear()
	needles.clear()
	zones.clear()
	marks.clear()
	echo_count = 0.0

func to_data() -> Dictionary:
	return {"timers": timers.duplicate(), "report": report.totals.duplicate(true), "restore_wait": restore_wait, "reservoir": reservoir, "overshield": overshield, "overshield_left": overshield_left,
		"packets": packets.duplicate(true), "recordings": recordings.duplicate(true), "needles": needles.duplicate(true), "zones": zones.duplicate(true), "marks": marks.duplicate(true), "echo_count": echo_count, "shield_charge": shield_charge, "emergency_wait": emergency_wait, "peak_pending": peak_pending}

func restore(data: Variant) -> bool:
	if not ArsenalRuntime.valid(data): return false
	if not report.restore(data.report): return false
	timers = data.timers.duplicate()
	for key: String in ["restore_wait", "reservoir", "overshield", "overshield_left", "echo_count", "shield_charge", "emergency_wait", "peak_pending"]: set(key, data[key])
	packets.assign(data.packets.duplicate(true))
	recordings.assign(data.recordings.duplicate(true))
	needles.assign(data.needles.duplicate(true))
	zones.assign(data.zones.duplicate(true))
	marks.assign(data.marks.duplicate(true))
	return true
