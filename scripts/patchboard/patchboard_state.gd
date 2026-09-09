class_name PatchboardState
extends RefCounted
## Explicit hooks, no combat signal subscriptions or shared resource mutation.
## Only direct weapon execution enters these hooks. Generated hits use damage_actor.
const METRICS: Array[String] = ["triggers", "damage", "assisted_damage", "control_seconds", "interrupts", "intercepts"]
var slots: Array[StringName] = [&"", &""]
var awaiting: bool = true
var counters: Dictionary = {"ball_lightning": 0, "double_drop": 0}
var cooldowns: Dictionary = {}
var totals: Dictionary = {}

func _init() -> void:
	for id: StringName in PatchboardContent.RECIPES:
		cooldowns[String(id)] = 0.0
		totals[String(id)] = {}
		for metric: String in METRICS: totals[String(id)][metric] = 0.0

static func eligible(session: CombatSession, id: StringName) -> bool:
	if session.arsenal == null or not PatchboardContent.RECIPES.has(id): return false
	var recipe: SynergyDefinition = PatchboardContent.RECIPES[id]
	for endpoint: StringName in recipe.endpoint_ids:
		if session.draft.track(endpoint) == null: return false
	if recipe.capability == &"marked" and float(ArsenalStats.parameters(session.draft.track(&"needle_swarm")).get(&"mark", 0)) <= 0: return false
	if recipe.capability == &"slowed" and float(ArsenalStats.parameters(session.draft.track(&"static_net")).get(&"slow", 0)) <= 0: return false
	return true

func connected(session: CombatSession, id: StringName) -> bool:
	return id in slots and eligible(session, id)

func rewire(session: CombatSession, index: int, id: StringName) -> bool:
	if session.paused or not session.is_wiring() or index not in [0, 1]: return false
	if id != &"" and (not eligible(session, id) or id == slots[1 - index]): return false
	if slots[index] == id: return true
	slots[index] = id
	# Forget partial trigger progress, but preserve cooldowns against swap exploits.
	for key: String in counters: counters[key] = 0
	session.checkpoint_changed.emit()
	return true

func advance(delta: float) -> void:
	for key: String in cooldowns: cooldowns[key] = maxf(0, float(cooldowns[key]) - delta)

func activate(session: CombatSession, id: StringName) -> bool:
	if session.paused or session.phase != CombatSession.Phase.COMBAT or not connected(session, id) or float(cooldowns[String(id)]) > 0: return false
	var recipe: SynergyDefinition = PatchboardContent.RECIPES[id]
	cooldowns[String(id)] = recipe.cooldown
	add(id, "triggers", 1)
	return true

func add(id: StringName, metric: String, amount: float) -> void:
	if totals.has(String(id)) and metric in METRICS and is_finite(amount) and amount > 0:
		totals[String(id)][metric] += amount

func discovered() -> Array[StringName]:
	var result: Array[StringName] = []
	for id: StringName in PatchboardContent.RECIPES:
		if float(totals[String(id)].triggers) > 0: result.append(id)
	return result

static func enemies(session: CombatSession, center: Vector2, radius: float, limit: int) -> Array[CombatActor]:
	var actors: Array[CombatActor] = session.actors.filter(func(a: CombatActor) -> bool: return not a.resolved and not a.projectile and a.position.distance_to(center) <= radius)
	actors.sort_custom(func(a: CombatActor, b: CombatActor) -> bool: return a.position.distance_squared_to(center) < b.position.distance_squared_to(center))
	if actors.size() > limit: actors.resize(limit)
	return actors

static func in_well(session: CombatSession, actor: CombatActor) -> bool:
	for zone: Dictionary in session.arsenal.zones:
		if zone.source == "reverb_well" and zone.left > 0 and actor.position.distance_to(Vector2(zone.x, zone.y)) <= float(zone.p.radius): return true
	return false

func pulse(session: CombatSession, id: StringName, targets: Array[CombatActor], damage: float, center: Vector2, root: int, radius: float) -> void:
	if root == 0:
		session.attack_serial += 1
		root = session.attack_serial
	session._event(CombatEvent.Kind.ATTACK, id, root, 0, 0)
	for actor: CombatActor in targets:
		session.damage_actor(actor, damage, id, root)
	session.support_effect.emit(id, center, Vector2.ONE * radius)

func arc_hit(session: CombatSession, actor: CombatActor, root: int) -> void:
	var id: StringName = &"ball_lightning"
	if actor.projectile or not connected(session, id) or actor.status.charged <= 0 or not in_well(session, actor) or cooldowns[String(id)] > 0: return
	counters.ball_lightning += 1
	var r: SynergyDefinition = PatchboardContent.RECIPES[id]
	if counters.ball_lightning < r.threshold: return
	if not activate(session, id): return
	counters.ball_lightning = 0
	pulse(session, id, enemies(session, actor.position, ModuleStats.area_radius(session.module_ids(), r.radius), r.target_cap), r.damage * ModuleStats.damage_multiplier(session.module_ids(), id), actor.position, root, ModuleStats.area_radius(session.module_ids(), r.radius))

func net_tick(session: CombatSession, targets: Array[CombatActor], center: Vector2, root: int) -> void:
	var id: StringName = &"live_wire"
	var viable: Array[CombatActor] = targets.filter(func(a: CombatActor) -> bool: return not a.resolved and not a.projectile)
	if viable.is_empty() or not activate(session, id): return
	var r: SynergyDefinition = PatchboardContent.RECIPES[id]
	for index: int in mini(r.target_cap, viable.size()):
		viable[index].status.charge()
		viable[index].status.charge_left = maxf(viable[index].status.charge_left, 3 * (1 + ModuleStats.coefficient(session.module_ids(), &"charged")))
		session._event(CombatEvent.Kind.CONTROL, id, root, viable[index].serial, 1)
	session.support_effect.emit(id, center, Vector2.ONE * r.radius)

func bass_pulse(session: CombatSession, targets: Array[CombatActor], root: int) -> void:
	var id: StringName = &"dead_zone"
	var viable: Array[CombatActor] = targets.filter(func(a: CombatActor) -> bool: return not a.resolved and not a.projectile and a.status.slow > 0 and a.status.slow_left > 0 and a.status.slow_source == &"static_net")
	if viable.is_empty() or not activate(session, id): return
	var r: SynergyDefinition = PatchboardContent.RECIPES[id]
	for index: int in mini(r.target_cap, viable.size()):
		var actor: CombatActor = viable[index]
		var previous: float = actor.status.jam_left
		if actor.status.jam(r.duration, actor.elite, actor.jam_immune): add(id, "interrupts", 1)
		add(id, "control_seconds", maxf(0, actor.status.jam_left - previous))
		session._event(CombatEvent.Kind.CONTROL, id, root, actor.serial, maxf(0, actor.status.jam_left - previous))

func bass_activation(session: CombatSession, center: Vector2, p: Dictionary, root: int) -> void:
	var id: StringName = &"pressure_drop"
	var r: SynergyDefinition = PatchboardContent.RECIPES[id]
	var targets: Array[CombatActor] = enemies(session, center, float(p.radius), 256)
	var trapped: Array[CombatActor] = targets.filter(func(a: CombatActor) -> bool: return in_well(session, a))
	if trapped.size() > r.target_cap: trapped.resize(r.target_cap)
	if not trapped.is_empty() and activate(session, id):
		pulse(session, id, trapped, float(p.damage) * r.coefficient * trapped.size(), center, root, float(p.radius))
	id = &"double_drop"
	if not connected(session, id) or cooldowns[String(id)] > 0: return
	r = PatchboardContent.RECIPES[id]
	counters.double_drop += 1
	if counters.double_drop < r.threshold: return
	if not activate(session, id): return
	counters.double_drop = 0
	pulse(session, id, enemies(session, center, float(p.radius), r.target_cap), float(p.damage) * r.coefficient, center, root, float(p.radius))

func shield_break(session: CombatSession, root: int) -> void:
	var id: StringName = &"feedback_loop"
	if not activate(session, id): return
	var r: SynergyDefinition = PatchboardContent.RECIPES[id]
	pulse(session, id, ArsenalCombat.nearby(session, CombatSession.TRANSMITTER, ModuleStats.area_radius(session.module_ids(), r.radius), r.target_cap), r.damage * ModuleStats.damage_multiplier(session.module_ids(), id), CombatSession.TRANSMITTER, root, ModuleStats.area_radius(session.module_ids(), r.radius))

func to_data() -> Dictionary:
	return {"slots": Array(slots), "awaiting": awaiting, "counters": counters.duplicate(), "cooldowns": cooldowns.duplicate(), "totals": totals.duplicate(true)}

func restore(session: CombatSession, data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5 or not data.get("awaiting") is bool: return false
	if not data.get("slots") is Array or data.slots.size() != 2: return false
	for id: Variant in data.slots:
		if not (id is String or id is StringName) or (id != "" and not eligible(session, StringName(id))): return false
	if data.slots[0] != "" and data.slots[0] == data.slots[1]: return false
	if not data.get("counters") is Dictionary or data.counters.size() != 2: return false
	for key: String in counters:
		if not SaveChecks.number(data.counters.get(key), 0, 2, true): return false
	if not data.get("cooldowns") is Dictionary or data.cooldowns.size() != 8 or not data.get("totals") is Dictionary or data.totals.size() != 8: return false
	for id: StringName in PatchboardContent.RECIPES:
		var r: SynergyDefinition = PatchboardContent.RECIPES[id]
		if not SaveChecks.number(data.cooldowns.get(String(id)), 0, r.cooldown): return false
		var row: Variant = data.totals.get(String(id))
		if not row is Dictionary or row.size() != METRICS.size(): return false
		for key: String in METRICS:
			if not SaveChecks.number(row.get(key), 0, 100000000, key in ["triggers", "interrupts", "intercepts"]): return false
	if data.awaiting and session.phase not in [CombatSession.Phase.INTERMISSION, CombatSession.Phase.DRAFT]: return false
	slots.assign(data.slots)
	awaiting = data.awaiting
	counters = data.counters.duplicate()
	cooldowns = data.cooldowns.duplicate()
	totals = data.totals.duplicate(true)
	return true
