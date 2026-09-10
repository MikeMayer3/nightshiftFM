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
		if BroadcastRules.expanded(session): item["owner_id"] = actor.owner_id
		if session.arsenal != null: item.status["exposure_source"] = String(actor.status.exposure_source)
		actors.append(item)
	var field: Dictionary = session.supports.field.duplicate(true)
	if not field.is_empty(): field.position = [field.position.x, field.position.y]
	var result: Dictionary = {"schema": 2, "content": session.active_combat.content_version if session.active_combat != null else SignalContent.VERSION, "engine": Engine.get_version_info().string,
		"run_id": String(session.run_id), "random": session.random.to_data(), "draft": session.draft.to_data(),
		"values": values, "shield": session.run.shield.current, "signal": session.signal_progress.to_data(),
		"last_cause": String(session.last_cause), "last_kind": String(session.last_kind),
		"slice": session.supports.to_data(), "actors": actors, "field": field, "shocks": session.supports.shocks.duplicate(true)}

	if session.active_combat != null: result["active"] = session.active_combat.to_data()
	if session.patchboard != null: result["patchboard"] = session.patchboard.to_data()
	if session.campaign != null: result["campaign"] = session.campaign.to_data()
	if session.achievement_run != null:
		result.schema = 3
		result["achievements"] = session.achievement_run.to_data()
	return result

static func _point(value: Variant, minimum_y: float = 0) -> bool:
	return value is Array and value.size() == 2 and SaveChecks.number(value[0], 0, 640) and SaveChecks.number(value[1], minimum_y, 720)

static func restore(session: CombatSession, data: Dictionary) -> bool:
	var is_active: bool = data.get("content") in [ActiveCombat.VERSION, ActiveCombat.LEGACY_VERSION, ArsenalContent.VERSION, PatchboardContent.VERSION, CampaignContent.VERSION, EncounterContent.VERSION, BroadcastRules.VERSION]
	var is_campaign: bool = data.get("content") in [CampaignContent.VERSION, EncounterContent.VERSION, BroadcastRules.VERSION]
	var is_patchboard: bool = data.get("content") in [PatchboardContent.VERSION, CampaignContent.VERSION, EncounterContent.VERSION, BroadcastRules.VERSION]
	var has_history: bool = data.get("schema") == 3
	if has_history and not is_campaign: return false
	if data.size() != (18 if is_campaign else 17 if is_patchboard else 16 if is_active else 15) + int(has_history) or not SaveChecks.number(data.get("schema"), 2, 3, true) or data.get("engine") != Engine.get_version_info().string: return false
	if not data.get("run_id") is String or not data.run_id.begins_with("run.") or not data.run_id.trim_prefix("run.").is_valid_int(): return false
	if not RunRandom.valid(data.get("random")) or not data.get("values") is Dictionary: return false
	if data.values.size() != CombatSession.checkpoint_fields().size(): return false
	for key: String in CombatSession.checkpoint_fields():
		if not SaveChecks.number(data.values.get(key), 0, 10000000): return false
	for key: String in ["phase", "wave", "spawn_index", "kills", "breaches", "intercepted", "_serial", "event_serial", "attack_serial"]:
		if not SaveChecks.number(data.values[key], 0, 10000000, true): return false
	if int(data.values.phase) not in [0, 1, 2, 3, 4] or data.values.wave > (1000 if data.get("content") == BroadcastRules.VERSION else 10) or data.values.hull > 100: return false
	var causes: Array[String] = ["COMBAT_NO_DAMAGE", "M2_SWARMER_NAME", "M2_DIVER_NAME", "M2_CARRIER_NAME", "COMBAT_PROJECTILE", "M4_PLATED_NAME", "M4_ELITE_NAME"]
	if data.get("content") in [EncounterContent.VERSION, BroadcastRules.VERSION]:
		for definition: EnemyDefinition in EncounterContent.ELITES: causes.append(String(definition.name_key))
	if data.get("content") == BroadcastRules.VERSION:
		for definition: EnemyDefinition in BroadcastContent.ENEMIES: causes.append(String(definition.name_key))
	if data.get("last_cause") not in causes: return false
	if data.get("last_kind") not in ["COMBAT_BREACH_HIT", "COMBAT_PROJECTILE_HIT"]: return false
	if data.get("content") in [ArsenalContent.VERSION, PatchboardContent.VERSION, CampaignContent.VERSION, EncounterContent.VERSION, BroadcastRules.VERSION]:
		if not data.get("draft") is Dictionary or not ArsenalContent.valid_loadout(data.draft.get("loadout")): return false
		if is_campaign:
			if not data.get("campaign") is Dictionary or not session.start_campaign(int(data.random.seed), StringName(data.run_id), data.draft.loadout, data.campaign): return false
		elif is_patchboard: session.start_patchboard(int(data.random.seed), StringName(data.run_id), data.draft.loadout)
		else: session.start_arsenal(int(data.random.seed), StringName(data.run_id), data.draft.loadout)
	elif is_active: session.start_active(int(data.random.seed), StringName(data.run_id))
	else: session.start_signal(int(data.random.seed), StringName(data.run_id))
	if is_active: session.active_combat.content_version = data.content
	if data.get("content") == EncounterContent.VERSION and not EncounterContent.authored(session): return false
	if is_active and not session.active_combat.restore(data.get("active")): return false
	if not session.signal_progress.restore(data.get("signal")) or not session.draft.restore(data.get("draft")): return false
	if not session.signal_progress is BroadcastProgress and session.signal_progress.earned != int(data.values.kills): return false
	if session.signal_progress.choices != session.draft.normal_count: return false
	if not session.supports.restore(data.get("slice")): return false
	session.random.restore(data.random)
	session.apply_ranks()
	if float(data.values.hull) > session.maximum_hull(): return false
	if not SaveChecks.number(data.get("shield"), 0, session.run.shield.capacity): return false
	for key: String in CombatSession.checkpoint_fields(): session.set(key, data.values[key])
	session.run.shield.current = float(data.shield)
	session.last_cause = StringName(data.last_cause)
	session.last_kind = StringName(data.last_kind)
	if is_patchboard and not session.patchboard.restore(session, data.get("patchboard")): return false
	if not _actors(session, data.get("actors")) or not _effects(session, data): return false
	if session.arsenal != null and not ArsenalRuntime.references(session): return false
	if is_patchboard and session.patchboard.awaiting and session.phase == CombatSession.Phase.DRAFT:
		if not session.actors.is_empty() or session.spawn_index != session.wave_definition().enemy_ids.size(): return false
	if session.phase == CombatSession.Phase.DRAFT:
		if session.draft.offers.is_empty() or not session.signal_progress.ready() or session.wave < 1: return false
	elif not session.draft.offers.is_empty(): return false
	if session.phase == CombatSession.Phase.DEFEAT and session.hull != 0: return false
	if session.phase != CombatSession.Phase.DEFEAT and session.hull <= 0: return false
	if session.phase == CombatSession.Phase.VICTORY and session.wave != 10 and not session.signal_progress is BroadcastProgress: return false
	if session.phase == CombatSession.Phase.COMBAT and session.wave < 1: return false
	if session.phase == CombatSession.Phase.INTERMISSION and session.wave >= session.total_waves(): return false
	if session.phase == CombatSession.Phase.DRAFT and session.wave == session.total_waves() and session.actors.is_empty() and session.spawn_index == session.wave_definition().enemy_ids.size(): return false
	if session.signal_progress.overdrive_left > 0 and not session.draft.accepted.any(func(record: Dictionary) -> bool: return record.id == String(SignalDraft.OVERDRIVE)): return false
	if session.wave == 0:
		if session.phase != CombatSession.Phase.INTERMISSION or session.spawn_index != 0 or session.kills != 0: return false
	elif session.spawn_index > session.wave_definition().enemy_ids.size(): return false
	if session.phase in [CombatSession.Phase.INTERMISSION, CombatSession.Phase.VICTORY, CombatSession.Phase.DEFEAT]:
		if not session.actors.is_empty() or not session.supports.field.is_empty() or not session.supports.shocks.is_empty(): return false
	# Never invent history for a legacy run, including one that has already healed.
	session.achievement_run = null
	if has_history:
		var history: AchievementRun = AchievementRun.new()
		if not history.restore(data.get("achievements")): return false
		if history.max_supports < session.draft.support_count(): return false
		if BroadcastRules.expanded(session):
			if not history.expanded or history.cleared_waves > session.wave or history.cleared_waves < maxi(0, session.wave - 1): return false
			if history.max_supports > BroadcastRules.support_limit(session.campaign): return false
			if session.signal_progress is BroadcastProgress and session.signal_progress.earned != BroadcastDraft.endless_credits(history.cleared_waves): return false
		if history.completed and session.phase != CombatSession.Phase.VICTORY and not (session.signal_progress is BroadcastProgress and session.phase == CombatSession.Phase.DEFEAT): return false
		if history.eligible and not (EncounterContent.authored(session) or BroadcastRules.expanded(session)): return false
		session.achievement_run = history
	return true

static func _actors(session: CombatSession, items: Variant) -> bool:
	if not items is Array or items.size() > 256: return false
	var seen: Array[int] = []
	for item: Variant in items:
		if not item is Dictionary or item.size() != ACTOR_FIELDS.size() + 4 + int(BroadcastRules.expanded(session)) or not _point(item.get("position"), RadioBalance.SPAWN_Y if RadioBalance.enabled(session) else 0): return false
		if not item.get("id") is String or not item.get("source") is String: return false
		var projectile: bool = item.id == "m2.projectile"
		var definition: EnemyDefinition = session.enemy_definition(&"m2.swarmer" if projectile else StringName(item.id))
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
		if BroadcastRules.expanded(session):
			if not SaveChecks.number(item.get("owner_id"), 0, session._serial, true): return false
			actor.owner_id = int(item.owner_id)
			if actor.role == EnemyDefinition.Role.AERIAL:
				if actor.owner_id <= 0 or actor.owner_id >= int(item.serial): return false
			elif actor.owner_id != 0: return false
			if actor.role == EnemyDefinition.Role.CORE and int(item.children_spawned) not in [0, 2]: return false
			if actor.role == EnemyDefinition.Role.CALLER and int(item.children_spawned) not in [0, 2, 4, 6]: return false
			if actor.role == EnemyDefinition.Role.SILENCE and int(item.children_spawned) != 0: return false
			actor.breach_damage *= BroadcastRules.damage_scale(session.campaign, session.wave)
		if actor.serial < 1 or actor.serial > session._serial or actor.serial in seen: return false
		if actor.health <= 0 or actor.health > actor.max_health or actor.max_health > (8.0 if projectile else definition.health * (ActiveCombat.health_scale(maxi(10, session.wave)) if session.active_combat != null else 1.72) * (BroadcastRules.health_scale(session.campaign, session.wave) if BroadcastRules.expanded(session) else 1.0)) + 0.001: return false
		if actor.origin_x > 640 or actor.children_spawned > (6 if BroadcastRules.expanded(session) and EncounterDirector.boss(actor) else actor.child_limit) or actor.projectiles_fired > actor.projectile_limit or actor.root_attack_id > session.attack_serial: return false
		if projectile and session.enemy_definition(StringName(item.source)) == null: return false
		actor.source_id = StringName(item.source)
		var status: Variant = item.get("status")
		if not status is Dictionary or status.size() != STATUS_LIMITS.size() + 1 + (1 if session.arsenal != null and status.has("exposure_source") else 0) or status.get("source") not in (["static_net", "bass_driver", "reverb_well"] if session.arsenal != null else ["static_net", "bass_driver"]): return false
		for key: String in STATUS_LIMITS:
			if not SaveChecks.number(status.get(key), 0, (10.0 if session.arsenal != null and key in ["charge_left", "exposure_left", "slow_left"] else float(STATUS_LIMITS[key])), key == "charged"): return false
			actor.status.set(key, status[key])
		if session.arsenal != null:
			if status.get("exposure_source", "bass_driver") not in ["bass_driver", "reverb_well"]: return false
			actor.status.exposure_source = StringName(status.get("exposure_source", "bass_driver"))
		actor.status.slow_source = StringName(status.source)
		seen.append(actor.serial)
		session.actors.append(actor)
	return true

static func _effects(session: CombatSession, data: Dictionary) -> bool:
	if not data.get("field") is Dictionary or not data.get("shocks") is Array or data.shocks.size() > 16: return false
	if session.arsenal != null and (not data.field.is_empty() or not data.shocks.is_empty()): return false
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
