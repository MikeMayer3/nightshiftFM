class_name SignalSnapshot
extends RefCounted
## Mid-combat checkpoints include active actors and effects, so an earned choice cannot replay kills.
const ACTOR_FIELDS: Array[String] = ["serial", "origin_x", "age", "health", "max_health", "ability_time", "children_spawned", "projectiles_fired", "root_attack_id"]
const STATUS_LIMITS: Dictionary = {"charged": 3, "charge_left": 3.0, "slow": 0.6, "slow_left": 0.6, "exposure": 100.0, "exposure_left": 3.0, "jam_left": 1.0, "jam_cooldown": 4.0, "fallback_left": 0.6}

static func capture(session: CombatSession) -> Dictionary:
	var values: Dictionary = {}
	for key: String in CombatSession.checkpoint_fields(): values[key] = session.get(key)
	var actors: Array[Dictionary] = []
	for actor: CombatActor in session.actors:
		var item: Dictionary = {"id": String(actor.definition_id), "source": String(actor.source_id), "position": [actor.position.x, actor.position.y], "status": {"source": String(actor.status.slow_source)}}
		for key: String in ACTOR_FIELDS: item[key] = actor.get(key)
		for key: String in STATUS_LIMITS: item.status[key] = actor.status.get(key)
		actors.append(item)
	var field: Dictionary = session.supports.field.duplicate(true)
	if not field.is_empty(): field.position = [field.position.x, field.position.y]
	var result: Dictionary = {"schema": 2, "content": session.active_combat.content_version if session.active_combat != null else SignalContent.VERSION, "engine": Engine.get_version_info().string,
		"run_id": String(session.run_id), "random": session.random.to_data(), "draft": session.draft.to_data(),
		"values": values, "shield": session.run.shield.current, "signal": session.signal_progress.to_data(),
		"last_cause": String(session.last_cause), "last_kind": String(session.last_kind),
		"slice": session.supports.to_data(), "actors": actors, "field": field, "shocks": session.supports.shocks.duplicate(true)}

	if session.active_combat != null: result["active"] = session.active_combat.to_data()
	return result

static func _point(value: Variant) -> bool:
	return value is Array and value.size() == 2 and SaveChecks.number(value[0], 0, 640) and SaveChecks.number(value[1], 0, 720)

static func restore(session: CombatSession, data: Dictionary) -> bool:
	var is_active: bool = data.get("content") in [ActiveCombat.VERSION, ActiveCombat.LEGACY_VERSION]
	if data.size() != (16 if is_active else 15) or data.get("schema") != 2 or data.get("engine") != Engine.get_version_info().string: return false
	if not data.get("run_id") is String or not data.run_id.begins_with("run.") or not data.run_id.trim_prefix("run.").is_valid_int(): return false
	if not RunRandom.valid(data.get("random")) or not data.get("values") is Dictionary: return false
	if data.values.size() != CombatSession.checkpoint_fields().size(): return false
	for key: String in CombatSession.checkpoint_fields():
		if not SaveChecks.number(data.values.get(key), 0, 10000000): return false
	for key: String in ["phase", "wave", "spawn_index", "kills", "breaches", "intercepted", "_serial", "event_serial", "attack_serial"]:
		if not SaveChecks.number(data.values[key], 0, 10000000, true): return false
	if int(data.values.phase) not in [0, 1, 2, 3, 4] or data.values.wave > 10 or data.values.hull > 100: return false
	if data.get("last_cause") not in ["COMBAT_NO_DAMAGE", "M2_SWARMER_NAME", "M2_DIVER_NAME", "M2_CARRIER_NAME", "COMBAT_PROJECTILE", "M4_PLATED_NAME", "M4_ELITE_NAME"]: return false
	if data.get("last_kind") not in ["COMBAT_BREACH_HIT", "COMBAT_PROJECTILE_HIT"]: return false
	if is_active: session.start_active(int(data.random.seed), StringName(data.run_id))
	else: session.start_signal(int(data.random.seed), StringName(data.run_id))
	if is_active: session.active_combat.content_version = data.content
	if is_active and not session.active_combat.restore(data.get("active")): return false
	if not session.signal_progress.restore(data.get("signal")) or not session.draft.restore(data.get("draft")): return false
	if session.signal_progress.earned != int(data.values.kills) or session.signal_progress.choices != session.draft.normal_count: return false
	if not session.supports.restore(data.get("slice")): return false
	session.random.restore(data.random)
	session.apply_ranks()
	if not SaveChecks.number(data.get("shield"), 0, session.run.shield.capacity): return false
	for key: String in CombatSession.checkpoint_fields(): session.set(key, data.values[key])
	session.run.shield.current = float(data.shield)
	session.last_cause = StringName(data.last_cause)
	session.last_kind = StringName(data.last_kind)
	if not _actors(session, data.get("actors")) or not _effects(session, data): return false
	if session.phase == CombatSession.Phase.DRAFT:
		if session.draft.offers.is_empty() or not session.signal_progress.ready() or session.wave < 1: return false
	elif not session.draft.offers.is_empty(): return false
	if session.phase == CombatSession.Phase.DEFEAT and session.hull != 0: return false
	if session.phase != CombatSession.Phase.DEFEAT and session.hull <= 0: return false
	if session.phase == CombatSession.Phase.VICTORY and session.wave != 10: return false
	if session.phase == CombatSession.Phase.COMBAT and session.wave < 1: return false
	if session.phase == CombatSession.Phase.INTERMISSION and session.wave >= 10: return false
	if session.phase == CombatSession.Phase.DRAFT and session.wave == 10 and session.actors.is_empty() and session.spawn_index == session.wave_definition().enemy_ids.size(): return false
	if session.signal_progress.overdrive_left > 0 and not session.draft.accepted.any(func(record: Dictionary) -> bool: return record.id == String(SignalDraft.OVERDRIVE)): return false
	if session.wave == 0:
		if session.phase != CombatSession.Phase.INTERMISSION or session.spawn_index != 0 or session.kills != 0: return false
	elif session.spawn_index > session.wave_definition().enemy_ids.size(): return false
	if session.phase in [CombatSession.Phase.INTERMISSION, CombatSession.Phase.VICTORY, CombatSession.Phase.DEFEAT]:
		if not session.actors.is_empty() or not session.supports.field.is_empty() or not session.supports.shocks.is_empty(): return false
	return true

static func _actors(session: CombatSession, items: Variant) -> bool:
	if not items is Array or items.size() > 256: return false
	var seen: Array[int] = []
	for item: Variant in items:
		if not item is Dictionary or item.size() != ACTOR_FIELDS.size() + 4 or not _point(item.get("position")): return false
		if not item.get("id") is String or not item.get("source") is String: return false
		var projectile: bool = item.id == "m2.projectile"
		var definition: EnemyDefinition = M4Content.enemy(&"m2.swarmer" if projectile else StringName(item.id))
		if definition == null: return false
		var actor: CombatActor = CombatActor.from_definition(definition, 0, Vector2(float(item.position[0]), float(item.position[1])))
		if projectile:
			actor.definition_id = &"m2.projectile"
			actor.name_key = &"COMBAT_PROJECTILE"
			actor.radius = 12.0
			actor.speed = 100.0
			actor.breach_damage = 15.0
			actor.projectile = true
		for key: String in ACTOR_FIELDS:
			if not SaveChecks.number(item.get(key), 0, 10000000, key in ["serial", "children_spawned", "projectiles_fired", "root_attack_id"]): return false
			actor.set(key, item[key])
		if actor.serial < 1 or actor.serial > session._serial or actor.serial in seen: return false
		if actor.health <= 0 or actor.health > actor.max_health or actor.max_health > (8.0 if projectile else definition.health * (ActiveCombat.health_scale(10) if session.active_combat != null else 1.72)) + 0.001: return false
		if actor.origin_x > 640 or actor.children_spawned > actor.child_limit or actor.projectiles_fired > actor.projectile_limit or actor.root_attack_id > session.attack_serial: return false
		if projectile and M4Content.enemy(StringName(item.source)) == null: return false
		actor.source_id = StringName(item.source)
		var status: Variant = item.get("status")
		if not status is Dictionary or status.size() != STATUS_LIMITS.size() + 1 or status.get("source") not in ["static_net", "bass_driver"]: return false
		for key: String in STATUS_LIMITS:
			if not SaveChecks.number(status.get(key), 0, float(STATUS_LIMITS[key]), key == "charged"): return false
			actor.status.set(key, status[key])
		actor.status.slow_source = StringName(status.source)
		seen.append(actor.serial)
		session.actors.append(actor)
	return true

static func _effects(session: CombatSession, data: Dictionary) -> bool:
	if not data.get("field") is Dictionary or not data.get("shocks") is Array or data.shocks.size() > 16: return false
	var field: Dictionary = data.field.duplicate(true)
	if not field.is_empty():
		if session.draft.track(&"static_net") == null or field.size() != 10 or not _point(field.get("position")): return false
		for key: String in ["radius", "left", "charges", "slow", "jam", "root", "damage", "tick_interval", "tick_left"]:
			if not SaveChecks.number(field.get(key), 0, 10000000, key in ["charges", "root"]): return false
		if field.radius > 400 or field.left > 10 or field.charges > 12 or field.slow > 0.6 or field.jam > 1 or field.damage > 100 or field.tick_interval <= 0 or field.tick_interval > 2 or field.tick_left > field.tick_interval or field.root > session.attack_serial: return false
		field.charges = int(field.charges)
		field.root = int(field.root)
		field.position = Vector2(float(field.position[0]), float(field.position[1]))
		session.supports.field = field
	for item: Variant in data.shocks:
		if session.draft.track(&"bass_driver") == null or not item is Dictionary or item.size() != 6: return false
		for key: String in ["y", "root", "width", "x", "end_y"]:
			if not SaveChecks.number(item.get(key), 0, 10000000, key == "root"): return false
		if item.y > 640 or item.x > 640 or item.end_y > item.y or item.width > 1000 or item.root > session.attack_serial: return false
		if not item.get("hit") is Array or item.hit.size() > 12: return false
		var seen: Array[int] = []
		for value: Variant in item.hit:
			if not SaveChecks.number(value, 1, session._serial, true) or int(value) in seen: return false
			seen.append(int(value))
		var shock: Dictionary = item.duplicate(true)
		shock.root = int(shock.root)
		shock.hit = Array(seen)
		session.supports.shocks.append(shock)
	return true
