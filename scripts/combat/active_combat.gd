class_name ActiveCombat
extends RefCounted
## Player-directed burst and clustered attacks, versioned separately from passive saves.
const VERSION: String = "m4.active.2"
const LEGACY_VERSION: String = "m4.active.1"
const COOLDOWN: float = 5.0
const RADIUS: float = 110.0
var cooldown: float = 0.0
var uses: int = 0
var damage: float = 0.0
var content_version: String = VERSION

func burst_damage(choices: int) -> float:
	return 45.0 + choices * (3.0 if content_version == LEGACY_VERSION else 3.25)

static func health_scale(wave: int) -> float:
	return 2.0 + (wave - 1) * 0.12

func radius_for(session: CombatSession) -> float:
	return ModuleStats.area_radius(session.module_ids(), RADIUS)

func burst(session: CombatSession, at: Vector2) -> bool:
	if session.paused or session.phase != CombatSession.Phase.COMBAT or cooldown > 0: return false
	if not at.is_finite() or not Rect2(Vector2.ZERO, CombatSession.ARENA).has_point(at): return false
	# A released drag outside the battlefield cannot fire, and empty ground costs nothing.
	var targets: Array[CombatActor] = session.actors.filter(func(a: CombatActor) -> bool: return not a.resolved and a.position.distance_to(at) <= radius_for(session))
	if targets.is_empty(): return false
	cooldown = COOLDOWN
	uses += 1
	session.attack_serial += 1
	var root: int = session.attack_serial
	session._event(CombatEvent.Kind.ATTACK, &"main", root, 0, 0, session.arsenal == null)
	session.support_effect.emit(&"main", at, Vector2.ONE * radius_for(session))
	var hit: int = 0
	for actor: CombatActor in targets:
		var before: float = actor.health
		# Earned choices scale the burst equally for every offensive build.
		session.damage_actor(actor, burst_damage(session.signal_progress.choices) * ModuleStats.damage_multiplier(session.module_ids(), &"main"), &"main", root, 55.0)
		if not actor.projectile: damage += before - actor.health
		if not actor.projectile and not actor.resolved: actor.status.jam(0.6, actor.elite, actor.jam_immune)
		hit += 1
		if hit == 8: break
	# Complete the next fixed step before opening a choice, so multi-hit attacks finish.
	return true

func to_data() -> Dictionary:
	return {"cooldown": cooldown, "uses": uses, "damage": damage}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 3: return false
	if not SaveChecks.number(data.get("cooldown"), 0, COOLDOWN) or not SaveChecks.number(data.get("uses"), 0, 100000, true) or not SaveChecks.number(data.get("damage"), 0, 100000000): return false
	cooldown = float(data.cooldown)
	uses = int(data.uses)
	damage = float(data.damage)
	return true
