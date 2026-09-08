class_name SignalSupportCombat
extends SupportCombat
## Offensive variants used only by the kill-meter content version.
func arc(session: CombatSession, owned: UpgradeTrack, first: CombatActor) -> void:
	if mode(owned) != 3:
		super.arc(session, owned, first)
		return
	var root: int = _root(session, &"arc_aerial", first.serial)
	var damage: float = float(owned.stats[&"damage"]) * 2.0
	var penetration: float = 35
	if modifier(owned) == 1:
		penetration = 65
		damage *= 0.85
	if modifier(owned) == 2: damage *= 1.7
	var targets: Array[CombatActor] = [first]
	var direction: Vector2 = (first.position - CombatSession.TRANSMITTER).normalized()
	if capped(owned):
		var candidates: Array[CombatActor] = session.actors.filter(func(actor: CombatActor) -> bool:
			var offset: Vector2 = actor.position - first.position
			return not actor.resolved and actor != first and offset.dot(direction) >= 0 and offset.dot(direction) <= 220 and absf(offset.cross(direction)) <= (12 if modifier(owned) == 1 else 24))
		candidates.sort_custom(func(a: CombatActor, b: CombatActor) -> bool: return a.position.distance_squared_to(first.position) < b.position.distance_squared_to(first.position))
		for candidate: CombatActor in candidates:
			if targets.size() == 3: break
			targets.append(candidate)
	for actor: CombatActor in targets:
		session.chain_fired.emit(PackedVector2Array([CombatSession.TRANSMITTER, actor.position]), true)
		session.damage_actor(actor, damage * (1 + actor.status.charged * 0.05), &"arc_aerial", root, penetration)
		actor.status.charge()

func deploy_net(session: CombatSession, owned: UpgradeTrack, at: Vector2) -> void:
	super.deploy_net(session, owned, at)
	field["damage"] = float(owned.stats[&"damage"])
	field["tick_interval"] = 0.75
	field["tick_left"] = 0.0
	if mode(owned) == 3:
		field.damage *= 1.5
		field.radius *= 0.75
		field.slow *= 0.5
		if modifier(owned) == 1:
			field.tick_interval = 0.5
			field.damage *= 0.75
		if modifier(owned) == 2:
			field.tick_interval = 1.25
			field.damage *= 2.0
		if capped(owned):
			field.damage *= 1.5
			field.left += 1

func _tick_field(session: CombatSession, delta: float) -> void:
	super._tick_field(session, delta)
	if field.is_empty(): return
	field.tick_left = maxf(0, float(field.tick_left) - delta)
	if field.tick_left > 0: return
	field.tick_left = field.tick_interval
	var hit: int = 0
	for actor: CombatActor in session.actors:
		if actor.resolved or actor.projectile or actor.position.distance_to(field.position) > float(field.radius): continue
		session.damage_actor(actor, float(field.damage), &"static_net", int(field.root))
		hit += 1
		if hit == 8: break
