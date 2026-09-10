class_name CombatSession
extends RefCounted
## Fixed-step, renderer-independent mission. No timers, listeners or actors survive reset.
signal finished(victory: bool)
signal station_hit(amount: float)
signal fired(target: Vector2)
signal wave_started(number: int)
signal checkpoint_changed
signal combat_event(event: CombatEvent)
signal support_effect(source: StringName, center: Vector2, radius: Vector2)
signal chain_fired(points: PackedVector2Array, support: bool)

enum Phase { INTERMISSION, COMBAT, VICTORY, DEFEAT, DRAFT, RECRUIT }
const ARENA: Vector2 = Vector2(640, 720)
const SPAWN_BAND: Rect2 = Rect2(32, 32, 576, 40)
const BREACH_Y: float = 640.0
const TRANSMITTER: Vector2 = Vector2(320, 684)
const HULL_MAX: float = 100.0
const STEP: float = 1.0 / 60.0
var campaign: CampaignRun
var achievement_run: AchievementRun
var patchboard: PatchboardState
var arsenal: ArsenalCombat
var active_combat: ActiveCombat
var signal_progress: SignalProgress
var supports: SupportCombat
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
var draft: DraftState
var random: RunRandom
var run_id: StringName
var recruitment_done: Array[int] = []
var support_time: float = 0.0
var event_serial: int = 0
var attack_serial: int = 0
var _serial: int = 0
var _accumulator: float = 0.0

func _init() -> void:
	restart()

func restart() -> void:
	achievement_run = null
	campaign = null
	patchboard = null
	arsenal = null
	active_combat = null
	signal_progress = null
	supports = null
	draft = null
	random = null
	run_id = &""
	recruitment_done.clear()
	support_time = 0.0
	event_serial = 0
	attack_serial = 0
	run = RunState.new()
	run.main_weapon = WeaponState.from_definition(CombatContent.MAIN)
	run.shield = ShieldState.from_definition(CombatContent.SHIELD)
	actors.clear()
	hull = HULL_MAX
	wave = 0
	elapsed = 0.0
	phase_time = 0.0 if RadioBalance.enabled(self) else 2.0
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
	if paused or is_finished() or is_deciding() or is_wiring() or not is_finite(delta) or delta <= 0.0:
		return
	_accumulator += delta
	while _accumulator >= STEP and not is_finished() and not is_deciding() and not is_wiring() and not paused:
		_accumulator -= STEP
		_step(STEP)

func is_finished() -> bool:
	return phase == Phase.VICTORY or phase == Phase.DEFEAT

func activate_shield() -> bool:
	if paused or is_finished() or is_deciding() or is_wiring() or ability_wait > 0.0:
		return false
	if achievement_run != null: achievement_run.activation_hits.clear()
	if arsenal != null:
		arsenal.shield_activate(self)
		return true
	ability_left = shield_stat(&"duration", CombatContent.SHIELD.ability_duration)
	ability_wait = shield_stat(&"cooldown", CombatContent.SHIELD.ability_cooldown)
	if supports != null: supports.brace(self)
	return true

func spawn_enemy(definition: EnemyDefinition, x: float) -> CombatActor:
	_serial += 1
	var actor: CombatActor = CombatActor.from_definition(definition, _serial,
		Vector2(clampf(x, SPAWN_BAND.position.x, SPAWN_BAND.end.x), RadioBalance.SPAWN_Y if RadioBalance.enabled(self) else SPAWN_BAND.position.y + 20.0))
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
	actor.breach_damage = 15.0 * (BroadcastRules.damage_scale(campaign, wave) if BroadcastRules.expanded(self) else 1.0)
	actor.projectile = true
	attack_serial += 1
	actor.root_attack_id = attack_serial
	actor.source_id = source.definition_id
	_event(CombatEvent.Kind.ATTACK, actor.source_id, actor.root_attack_id, 0, 0.0)
	actors.append(actor)
	return actor

func target(source: StringName = &"") -> CombatActor:
	var best: CombatActor
	var score: float = INF
	var reach: float = RadioBalance.reach(self, source) if source != &"" and RadioBalance.enabled(self) else INF
	for actor: CombatActor in actors:
		if not RadioBalance.entered(self, actor) or actor.position.distance_squared_to(TRANSMITTER) > reach * reach:
			continue
		var candidate: float = actor.position.distance_squared_to(focus_point) if focus_active else BREACH_Y - actor.position.y
		if BroadcastRules.expanded(self) and not focus_active:
			if actor.role == EnemyDefinition.Role.AERIAL: candidate -= 250
			elif actor.role in [EnemyDefinition.Role.CASTER, EnemyDefinition.Role.JAMMER] and EncounterDirector.channel(actor): candidate -= 180
		if candidate < score:
			best = actor
			score = candidate
	return best

func damage_actor(actor: CombatActor, amount: float, source: StringName = &"main", root_id: int = 0, penetration: float = 0.0) -> void:
	if not RadioBalance.can_hit(self, actor, source) or paused or is_finished() or is_deciding() or actor.resolved or amount <= 0.0 or not is_finite(amount):
		return
	if signal_progress != null and signal_progress.overdrive_left > 0: amount *= 1.25
	if arsenal != null: amount *= 1 + arsenal.mark_strength(actor.serial)
	if BroadcastRules.expanded(self): amount *= EncounterDirector.protection(self, actor)
	var base_amount: float = amount
	if supports != null and not actor.projectile:
		amount *= 100.0 / (100.0 + maxf(0, actor.armor - penetration - actor.status.exposure))
		var unexposed: float = minf(actor.health, base_amount * 100.0 / (100.0 + maxf(0, actor.armor - penetration)))
		if actor.status.exposure > 0: supports.report.add(actor.status.exposure_source if arsenal != null else &"bass_driver", &"exposure_bonus", minf(actor.health, amount) - unexposed)
	var effective: float = minf(actor.health, amount)
	if supports != null and not actor.projectile: supports.report.add(source, &"damage", effective)
	if patchboard != null and not actor.projectile: patchboard.add(source, "damage", effective)
	actor.health = maxf(0.0, actor.health - amount)
	_event(CombatEvent.Kind.DAMAGE, source, root_id, actor.serial, effective)
	if actor.health == 0.0:
		actor.resolved = true
		if actor.projectile:
			intercepted += 1
			if patchboard != null: patchboard.add(source, "intercepts", 1)
			if supports != null: supports.report.add(source, &"intercepts", 1)
			_event(CombatEvent.Kind.INTERCEPT, source, root_id, actor.serial, 0.0)
		else:
			kills += 1
			if signal_progress != null and not signal_progress is BroadcastProgress: signal_progress.earned += 1
			if achievement_run != null and EncounterDirector.boss(actor): achievement_run.wave_bosses.append(String(actor.definition_id))
			_event(CombatEvent.Kind.KILL, source, root_id, actor.serial, 0.0)

func hit_station(amount: float, cause: StringName, kind: StringName = &"COMBAT_BREACH_HIT", source_id: StringName = &"station", root_id: int = 0, target_id: int = 0) -> void:
	if paused or is_finished() or is_deciding() or not is_finite(amount) or amount <= 0.0:
		return
	# Capacitor active: 75% damage reduction, still shield-first; never reflects.
	var temporary_reserve: float = supports.overshield if supports != null else 0
	var incoming: float = arsenal.before_station_hit(self, amount, kind == &"COMBAT_PROJECTILE_HIT", root_id) if arsenal != null else amount * (0.25 if ability_left > 0.0 else 1.0)
	if supports != null:
		var over_absorbed: float = minf(supports.overshield, incoming)
		supports.overshield -= over_absorbed
		incoming -= over_absorbed
		supports.report.add(&"shield" if arsenal != null else &"arc_aerial", &"absorbed", over_absorbed)
	if achievement_run != null and ability_left > 0 and target_id > 0:
		var active_prevented: bool = (temporary_reserve > 0 and supports.overshield < temporary_reserve) or (arsenal != null and (draft as ArsenalDraft).loadout.shield == "feedback" and kind == &"COMBAT_PROJECTILE_HIT" and incoming == 0) or (arsenal == null and amount > incoming)
		if active_prevented and target_id not in achievement_run.activation_hits: achievement_run.activation_hits.append(target_id)
		achievement_run.best_activation = maxi(achievement_run.best_activation, achievement_run.activation_hits.size())
		if kind == &"COMBAT_PROJECTILE_HIT" and arsenal != null and (draft as ArsenalDraft).loadout.shield == "feedback" and incoming == 0 and root_id not in achievement_run.wave_reflections: achievement_run.wave_reflections.append(root_id)
	var previous_shield: float = run.shield.current
	var absorbed: float = minf(run.shield.current, incoming)
	run.shield.current -= absorbed
	if supports != null:
		supports.report.add(&"shield", &"absorbed", absorbed)
		if previous_shield > 0 and run.shield.current == 0:
			supports.report.add(&"shield", &"breaks", 1)
			_event(CombatEvent.Kind.SHIELD_BREAK, &"shield", root_id, target_id, absorbed)
	if achievement_run != null:
		var hull_lost: float = minf(hull, incoming - absorbed)
		achievement_run.hull_damage += hull_lost
		var category: String = "breach" if kind == &"COMBAT_BREACH_HIT" else "projectile" if kind == &"COMBAT_PROJECTILE_HIT" else "other"
		achievement_run.loss_history[category] += hull_lost
		if previous_shield > 0 and run.shield.current == 0: achievement_run.broken = true
	hull = maxf(0.0, hull - (incoming - absorbed))
	recharge_time = CombatContent.SHIELD.recharge_delay
	var broke: bool = previous_shield > 0 and run.shield.current == 0
	if arsenal != null: arsenal.after_station_hit(self, broke)
	if patchboard != null and broke: patchboard.shield_break(self, root_id)
	damage_taken += incoming
	last_cause = cause
	last_kind = kind
	_event(CombatEvent.Kind.STATION_DAMAGE, source_id, root_id, target_id, incoming)
	station_hit.emit(incoming)
	if hull == 0.0:
		_finish(false)

func _step(delta: float) -> void:
	elapsed += delta
	if patchboard != null: patchboard.advance(delta)
	if active_combat != null: active_combat.cooldown = maxf(0, active_combat.cooldown - delta)
	if signal_progress != null: signal_progress.overdrive_left = maxf(0, signal_progress.overdrive_left - delta)
	if supports != null: supports.tick_passive(delta)
	ability_left = maxf(0.0, ability_left - delta)
	ability_wait = maxf(0.0, ability_wait - delta)
	recharge_time = maxf(0.0, recharge_time - delta)
	if arsenal != null and recharge_time > 0:
		run.shield.current = minf(run.shield.capacity, run.shield.current + float(arsenal.shield_parameters(self).get(&"sustain", 0)) * shield_stat(&"recharge", 0) * delta)
	if recharge_time == 0.0:
		run.shield.current = minf(run.shield.capacity, run.shield.current + shield_stat(&"recharge", CombatContent.SHIELD.recharge_rate) * delta)
	if ability_left > 0.0:
		if supports != null: supports.heal(self, shield_stat(&"brace_recharge", 0.0) * delta, &"shield")
		else: run.shield.current = minf(run.shield.capacity, run.shield.current + shield_stat(&"brace_recharge", 0.0) * delta)
	if achievement_run != null: achievement_run.observe(self)
	if phase == Phase.INTERMISSION:
		phase_time = 0.0 if RadioBalance.enabled(self) else maxf(0.0, phase_time - delta)
		if phase_time <= 0.0:
			wave += 1
			phase = Phase.COMBAT
			spawn_index = 0
			spawn_time = 0.0
			wave_started.emit(wave)
			checkpoint_changed.emit()
		return
	var definition: WaveDefinition = wave_definition()
	spawn_time = maxf(0.0, spawn_time - delta)
	if spawn_index < definition.enemy_ids.size() and spawn_time <= 0.0:
		var group_size: int = 5 if active_combat != null else 1
		if EncounterContent.authored(self) or BroadcastRules.expanded(self): group_size = definition.group_size
		var group: int = spawn_index / group_size
		var center: float = random.rng("wave").randf_range(120, 520) if active_combat != null else 320.0
		for member: int in mini(group_size, definition.enemy_ids.size() - spawn_index):
			var spawn_x: float = random.rng("wave").randf_range(64.0, 576.0) if random != null else 64.0 + float((spawn_index * 173 + wave * 67) % 512)
			if active_combat != null: spawn_x = center + (member - 2) * 38.0
			if EncounterContent.authored(self) or BroadcastRules.expanded(self): spawn_x = EncounterContent.spawn_x(definition, group, member, center)
			var spawned: CombatActor = spawn_enemy(enemy_definition(definition.enemy_ids[spawn_index]), spawn_x)
			if draft != null:
				spawned.health *= ActiveCombat.health_scale(wave) if active_combat != null else 1.0 + float(wave - 1) * (0.08 if supports != null else 0.22)
				if active_combat != null and active_combat.automatic_radio: spawned.health *= RadioBalance.health_scale(wave)
				if BroadcastRules.expanded(self):
					spawned.health *= BroadcastRules.health_scale(campaign, wave)
					spawned.breach_damage *= BroadcastRules.damage_scale(campaign, wave)
				spawned.max_health = spawned.health
			if achievement_run != null: achievement_run.encounter(spawned)
			spawn_index += 1
		spawn_time += definition.spawn_interval
	# Resolve main-gun kills before movement/breach in the same fixed step.
	shot_time = maxf(0.0, shot_time - delta)
	var aimed: CombatActor = target(&"main")
	if auto_fire and shot_time == 0.0 and aimed != null:
		if draft == null:
			fired.emit(aimed.position)
			damage_actor(aimed, run.main_weapon.damage)
			shot_time = CombatContent.MAIN.attack_interval
		elif arsenal != null:
			arsenal.fire_main(self, aimed)
			shot_time = float(ArsenalStats.parameters(draft.track(&"main")).interval)
		else:
			_fire_track(draft.track(&"main"), aimed)
			shot_time = float(draft.track(&"main").stats[&"interval"])
	support_time = maxf(0.0, support_time - delta)
	if supports != null: supports.advance(self, delta)
	if supports == null and draft != null and auto_fire and support_time == 0.0 and target() != null:
		_fire_track(draft.track(&"arc_aerial"), target())
		support_time = float(draft.track(&"arc_aerial").stats[&"interval"])
	var active: Array[CombatActor] = actors.duplicate()
	for actor: CombatActor in active:
		if actor.resolved:
			continue
		if supports != null and not actor.projectile:
			supports.report.add(actor.status.slow_source, &"slow_seconds", actor.status.slow * minf(delta, actor.status.slow_left))
		if BroadcastRules.expanded(self) and not actor.projectile: EncounterDirector.prepare(self, actor)
		actor.advance(delta, 300.0 if RadioBalance.enabled(self) else 170.0)
		if actor.position.y >= BREACH_Y:
			actor.resolved = true
			if not actor.projectile:
				breaches += 1
				_event(CombatEvent.Kind.BREACH, actor.definition_id, 0, actor.serial, actor.breach_damage)
			hit_station(actor.breach_damage, actor.name_key,
				&"COMBAT_PROJECTILE_HIT" if actor.projectile else &"COMBAT_BREACH_HIT",
				actor.source_id if actor.projectile else actor.definition_id, actor.root_attack_id, actor.serial)
			if is_finished():
				return
			continue
		if not RadioBalance.entered(self, actor): continue
		actor.ability_time += delta * actor.status.ability_rate()
		if actor.ability_time >= actor.ability_interval:
			actor.ability_time -= actor.ability_interval
			if BroadcastRules.expanded(self): EncounterDirector.ability(self, actor)
			if actor.children_spawned < actor.child_limit:
				# Reinforcements always enter through the top band, not mid-field.
				spawn_enemy(CombatContent.enemy(actor.child_id), actor.position.x + float(actor.children_spawned - 1) * 48.0)
				actor.children_spawned += 1
			if actor.projectiles_fired < actor.projectile_limit:
				spawn_projectile(actor)
				actor.projectiles_fired += 1
	actors = actors.filter(func(actor: CombatActor) -> bool: return not actor.resolved)
	if signal_progress != null:
		var cleared: bool = actors.is_empty() and spawn_index == definition.enemy_ids.size()
		if cleared:
			if achievement_run != null: achievement_run.complete_wave(self)
			if signal_progress is BroadcastProgress: signal_progress.earned = BroadcastDraft.endless_credits(wave)
			supports.clear_wave_effects()
			if wave == total_waves():
				_finish(true)
				return
			phase = Phase.INTERMISSION
			phase_time = 0.0 if RadioBalance.enabled(self) else 2.0
			if patchboard != null: patchboard.awaiting = not BroadcastRules.expanded(self) and (campaign == null or campaign.cleared >= 2)
		if signal_progress.ready(): _open_signal_choice()
		elif cleared: checkpoint_changed.emit()
		return
	if actors.is_empty() and spawn_index == definition.enemy_ids.size():
		if supports != null: supports.clear_wave_effects()
		if wave == total_waves():
			_finish(true)
		elif draft != null:
			phase = Phase.DRAFT
			_accumulator = 0.0
			focus_active = false
			draft.begin()
			checkpoint_changed.emit()
		else:
			phase = Phase.INTERMISSION
			phase_time = 0.0 if RadioBalance.enabled(self) else 2.0

func _finish(victory: bool) -> void:
	if is_finished():
		return
	if patchboard != null: patchboard.awaiting = false
	if supports != null: supports.clear_wave_effects()
	phase = Phase.VICTORY if victory else Phase.DEFEAT
	if achievement_run != null:
		achievement_run.observe(self)
		achievement_run.completed = victory or signal_progress is BroadcastProgress
	actors.clear()
	focus_active = false
	_accumulator = 0.0
	finished.emit(victory)
	checkpoint_changed.emit()

func start_m3(seed_value: int, identity: StringName) -> void:
	restart()
	run_id = identity
	random = RunRandom.new(seed_value)
	draft = DraftState.new(M3Content.tracks(), random)
	for id: StringName in [&"main", &"shield", &"arc_aerial"]: draft.equip(id)
	apply_ranks()

func start_m4(seed_value: int, identity: StringName) -> void:
	restart()
	run_id = identity
	random = RunRandom.new(seed_value)
	draft = DraftState.new(M4Content.tracks(), random)
	for id: StringName in [&"main", &"shield", &"arc_aerial"]: draft.equip(id)
	supports = SupportCombat.new()
	apply_ranks()

func start_signal(seed_value: int, identity: StringName) -> void:
	restart()
	run_id = identity
	random = RunRandom.new(seed_value)
	signal_progress = SignalProgress.new()
	draft = SignalDraft.new(SignalContent.tracks(), random)
	for id: StringName in [&"main", &"shield", &"arc_aerial"]: draft.equip(id)
	supports = SignalSupportCombat.new()
	apply_ranks()

func start_active(seed_value: int, identity: StringName) -> void:
	start_signal(seed_value, identity)
	active_combat = ActiveCombat.new()
	signal_progress.active_rules = true

func start_arsenal(seed_value: int, identity: StringName, loadout: Dictionary = ArsenalContent.DEFAULT) -> bool:
	if not ArsenalContent.valid_loadout(loadout): return false
	restart()
	run_id = identity
	random = RunRandom.new(seed_value)
	signal_progress = SignalProgress.new()
	signal_progress.active_rules = true
	active_combat = ActiveCombat.new()
	active_combat.content_version = ArsenalContent.VERSION
	var choices: ArsenalDraft = ArsenalDraft.new(ArsenalContent.tracks(loadout), random)
	choices.loadout = loadout.duplicate()
	draft = choices
	for id: StringName in [&"main", &"shield", StringName(loadout.support)]: draft.equip(id)
	arsenal = ArsenalCombat.new()
	supports = arsenal
	apply_ranks()
	run.shield.current = run.shield.capacity
	return true

func start_patchboard(seed_value: int, identity: StringName, loadout: Dictionary = ArsenalContent.DEFAULT) -> bool:
	if not start_arsenal(seed_value, identity, loadout): return false
	active_combat.content_version = PatchboardContent.VERSION
	patchboard = PatchboardState.new()
	return true

func start_campaign(seed_value: int, identity: StringName, loadout: Dictionary, context: Dictionary) -> bool:
	var selected: CampaignRun = CampaignRun.new()
	if not selected.restore(context) or not CampaignContent.valid_selection(loadout, selected.modules, selected.cleared): return false
	if not start_patchboard(seed_value, identity, loadout): return false
	campaign = selected
	active_combat.automatic_radio = true
	active_combat.content_version = BroadcastRules.VERSION if campaign.expanded else EncounterContent.VERSION if EncounterWaves.MISSIONS.has(campaign.mission) else CampaignContent.VERSION
	if campaign.expanded:
		var expanded_draft: BroadcastDraft = BroadcastDraft.new(ArsenalContent.tracks(loadout), random)
		expanded_draft.context = campaign
		expanded_draft.loadout = loadout.duplicate()
		draft = expanded_draft
		for id: StringName in [&"main", &"shield", StringName(loadout.support)]: draft.equip(id)
		if campaign.mode == "endless": signal_progress = BroadcastProgress.new()
	achievement_run = AchievementRun.new()
	achievement_run.expanded = campaign.expanded
	achievement_run.eligible = AchievementRun.production_build() and (EncounterContent.authored(self) or campaign.expanded)
	draft.catalog = draft.catalog.filter(func(definition: TrackDefinition) -> bool: return not definition.support or String(definition.id) in CampaignContent.options(campaign.cleared, "support"))
	(draft as ArsenalDraft).reroll_limit = 2 + int(ModuleStats.coefficient(campaign.modules, &"rerolls"))
	draft.rerolls = (draft as ArsenalDraft).reroll_limit
	patchboard.awaiting = not campaign.expanded and campaign.cleared >= 2
	if campaign.expanded: patchboard.mixer = MixerState.new()
	apply_ranks()
	hull = maximum_hull()
	run.shield.current = run.shield.capacity
	return true

func module_ids() -> Array[StringName]:
	if campaign != null: return campaign.modules
	var empty: Array[StringName] = []
	return empty

func maximum_hull() -> float:
	return ModuleStats.maximum_hull(module_ids()) * (.55 if BroadcastRules.expanded(self) and campaign.contract == "fragile_broadcast" else 1.0)

func is_wiring() -> bool:
	return patchboard != null and patchboard.awaiting and phase == Phase.INTERMISSION

func launch_wave() -> bool:
	if paused or not is_wiring(): return false
	patchboard.awaiting = false
	_accumulator = 0
	checkpoint_changed.emit()
	return true

func _open_signal_choice() -> void:
	phase = Phase.DRAFT
	_accumulator = 0.0
	focus_active = false
	draft.begin()
	if signal_progress is BroadcastProgress and draft.offers == [BroadcastDraft.DECLINE] and draft.support_count() == 5:
		_choose_signal(BroadcastDraft.DECLINE)
		return
	checkpoint_changed.emit()

func _choose_signal(id: StringName) -> bool:
	if paused or phase != Phase.DRAFT or not signal_progress.ready() or not draft.choose(id): return false
	signal_progress.consume()
	if id == SignalDraft.OVERDRIVE: signal_progress.overdrive_left = 20.0
	if id == DraftState.REPAIR: hull = minf(maximum_hull(), hull + 12)
	if id == DraftState.REFILL: run.shield.current = minf(run.shield.capacity, run.shield.current + 20)
	apply_ranks()
	_accumulator = 0.0
	if signal_progress.ready():
		_open_signal_choice()
	else:
		phase = Phase.COMBAT
		if actors.is_empty() and spawn_index == wave_definition().enemy_ids.size():
			phase = Phase.INTERMISSION
			phase_time = 0.0 if RadioBalance.enabled(self) else 2.0
		checkpoint_changed.emit()
	return true

func swap_branch(id: StringName) -> bool:
	if supports == null or paused or phase != Phase.DRAFT: return false
	var option: UpgradeDefinition = draft.card(id)
	if option == null or option.required_rank not in [3, 6] or draft.track(option.target_id) == null: return false
	if option not in draft.track(option.target_id).eligible(draft.banished): return false
	if id in draft.offers: return false
	for index: int in draft.offers.size():
		var current: UpgradeDefinition = draft.card(draft.offers[index])
		if current != null and current.target_id == option.target_id:
			draft.offers[index] = id
			checkpoint_changed.emit()
			return true
	return false

func total_waves() -> int:
	return 1000 if BroadcastRules.expanded(self) and campaign.mode == "endless" else 10 if draft != null else 3

func wave_definition() -> WaveDefinition:
	if BroadcastRules.expanded(self): return BroadcastRules.wave_for(campaign, maxi(1, wave))
	if EncounterContent.authored(self): return EncounterWaves.MISSIONS[campaign.mission][wave - 1]
	if active_combat != null and active_combat.content_version in [ActiveCombat.VERSION, ArsenalContent.VERSION, PatchboardContent.VERSION, CampaignContent.VERSION] and wave == 8: return ActiveContent.FIRST_ELITES
	if active_combat != null: return ActiveContent.WAVES[wave - 1]
	if signal_progress != null: return SignalContent.WAVES[wave - 1]
	if supports != null: return M4Content.WAVES[wave - 1]
	if draft == null: return CombatContent.waves()[wave - 1]
	# M3 schedule reuses authored M2 patterns; full mission content is deferred.
	return CombatContent.waves()[mini(2, (wave - 1) / 3)]

func enemy_definition(id: StringName) -> EnemyDefinition:
	if BroadcastRules.expanded(self): return BroadcastContent.enemy(id)
	if EncounterContent.authored(self): return EncounterContent.enemy(id)
	return M4Content.enemy(id) if supports != null else CombatContent.enemy(id)

func is_deciding() -> bool:
	return phase in [Phase.DRAFT, Phase.RECRUIT]

func shield_stat(key: StringName, fallback: float) -> float:
	if arsenal != null: return float(arsenal.shield_parameters(self).get(key, fallback))
	return float(draft.track(&"shield").stats.get(key, fallback)) if draft != null else fallback

func apply_ranks() -> void:
	if campaign != null:
		for owned: UpgradeTrack in draft.tracks:
			owned.modules = campaign.modules.duplicate()
			owned.mixer = patchboard.mixer if patchboard != null else null
	var main: UpgradeTrack = draft.track(&"main")
	run.main_weapon.rank = main.rank()
	run.main_weapon.damage = float(main.stats[&"damage"])
	run.shield.rank = draft.track(&"shield").rank()
	run.shield.capacity = shield_stat(&"capacity", 50.0)
	run.shield.current = minf(run.shield.current, run.shield.capacity)
	run.supports.clear()
	for owned: UpgradeTrack in draft.tracks:
		if owned.definition.support:
			var support: WeaponState = WeaponState.new()
			support.definition_id = owned.definition.id
			support.rank = owned.rank()
			support.damage = float(owned.stats.get(&"damage", 0.0))
			run.supports.append(support)
	if achievement_run != null: achievement_run.observe(self)

func choose_upgrade(id: StringName) -> bool:
	if signal_progress != null: return _choose_signal(id)
	if paused or phase != Phase.DRAFT or not draft.choose(id): return false
	if id == DraftState.REPAIR: hull = minf(HULL_MAX, hull + 10.0)
	if id == DraftState.REFILL: run.shield.current = minf(run.shield.capacity, run.shield.current + 15.0)
	apply_ranks()
	if draft.normal_count < wave * 3:
		draft.begin()
	elif wave + 1 in [2, 4, 6, 8] and wave + 1 not in recruitment_done:
		phase = Phase.RECRUIT
	else:
		phase = Phase.INTERMISSION
		phase_time = 0.0 if RadioBalance.enabled(self) else 2.0
	checkpoint_changed.emit()
	return true

func recruit(id: StringName, unlocked: Array[StringName]) -> bool:
	if paused or phase != Phase.RECRUIT: return false
	if id != &"" and (id not in unlocked or not _recruitable(id) or not draft.equip(id)): return false
	recruitment_done.append(wave + 1)
	if id == &"":
		phase = Phase.DRAFT
		draft.begin(true)
	else:
		apply_ranks()
		phase = Phase.INTERMISSION
		phase_time = 0.0 if RadioBalance.enabled(self) else 2.0
	checkpoint_changed.emit()
	return true

func _recruitable(id: StringName) -> bool:
	for definition: TrackDefinition in draft.catalog:
		if definition.id == id: return definition.support
	return false

func reroll_draft() -> bool:
	if paused or phase != Phase.DRAFT or not draft.reroll(): return false
	checkpoint_changed.emit()
	return true

func banish_card(id: StringName) -> bool:
	if paused or phase != Phase.DRAFT or not draft.banish(id): return false
	checkpoint_changed.emit()
	return true

func _fire_track(owned: UpgradeTrack, first: CombatActor) -> void:
	attack_serial += 1
	var root_id: int = attack_serial
	_event(CombatEvent.Kind.ATTACK, owned.definition.id, root_id, first.serial, 0)
	var contacts: Array[Vector2] = []
	var hit_ids: Array[int] = []
	var victim: CombatActor = first
	var origin: Vector2 = TRANSMITTER
	for _jump: int in int(owned.stats[&"targets"]):
		if victim == null: break
		var position: Vector2 = victim.position
		contacts.append(position)
		hit_ids.append(victim.serial)
		chain_fired.emit(PackedVector2Array([origin, position]), owned.definition.support)
		damage_actor(victim, float(owned.stats[&"damage"]), owned.definition.id, root_id)
		victim = null
		var nearest: float = float(owned.stats[&"range"])
		var endpoints: Array[Vector2] = [position]
		if float(owned.stats.get(&"branching", 0.0)) > 0: endpoints = contacts
		for endpoint: Vector2 in endpoints:
			for candidate: CombatActor in actors:
				if candidate.resolved or candidate.serial in hit_ids: continue
				var distance: float = endpoint.distance_to(candidate.position)
				if distance <= nearest:
					nearest = distance
					victim = candidate
					origin = endpoint

func _event(kind: CombatEvent.Kind, source: StringName, root_id: int, target_id: int, amount: float, can_echo: bool = true) -> void:
	# A support can refill the shield and an enemy can hit it in the same step.
	if achievement_run != null and kind == CombatEvent.Kind.SHIELD_HEAL: achievement_run.observe(self)
	event_serial += 1
	var event: CombatEvent = CombatEvent.new(event_serial, root_id, source, kind, target_id, amount)
	if source == &"main" and can_echo and (arsenal == null or kind == CombatEvent.Kind.ATTACK): event.eligible_triggers |= CombatEvent.CAN_ECHO
	if arsenal != null and (source in [&"echo_deck", &"shield"] or PatchboardContent.RECIPES.has(source)):
		event.generation_depth = 1
		event.eligible_triggers = 0
	combat_event.emit(event)

func to_checkpoint() -> Dictionary:
	if signal_progress != null: return SignalSnapshot.capture(self)
	var values: Dictionary = {}
	for field: String in checkpoint_fields(): values[field] = get(field)
	var data: Dictionary = {"schema": 1, "content": M4Content.VERSION if supports != null else M3Content.VERSION, "engine": Engine.get_version_info().string,
		"run_id": String(run_id), "random": random.to_data(), "draft": draft.to_data(),
		"values": values, "shield": run.shield.current, "recruitment_done": recruitment_done.duplicate(),
		"last_cause": String(last_cause), "last_kind": String(last_kind)}
	if supports != null: data["slice"] = supports.to_data()
	return data

static func checkpoint_fields() -> Array[String]:
	return ["phase", "hull", "wave", "elapsed", "phase_time", "spawn_time", "spawn_index",
		"shot_time", "support_time", "recharge_time", "ability_left", "ability_wait",
		"kills", "breaches", "intercepted", "damage_taken", "_serial", "event_serial", "attack_serial"]

func restore_checkpoint(data: Variant) -> bool:
	if data is Dictionary and data.get("content") in [SignalContent.VERSION, ActiveCombat.VERSION, ActiveCombat.LEGACY_VERSION, ArsenalContent.VERSION, PatchboardContent.VERSION, CampaignContent.VERSION, EncounterContent.VERSION, BroadcastRules.VERSION]: return SignalSnapshot.restore(self, data)
	if not data is Dictionary or data.get("schema") != 1: return false
	var is_m4: bool = data.get("content") == M4Content.VERSION
	if data.size() != (12 if is_m4 else 11): return false
	if data.get("content") not in [M3Content.VERSION, M4Content.VERSION] or data.get("engine") != Engine.get_version_info().string: return false
	if not data.get("run_id") is String or not data.run_id.begins_with("run.") or not data.run_id.trim_prefix("run.").is_valid_int(): return false
	if not RunRandom.valid(data.get("random")) or not data.get("values") is Dictionary: return false
	if data.values.size() != checkpoint_fields().size(): return false
	for field: String in checkpoint_fields():
		if not SaveChecks.number(data.values.get(field), 0, 10000000.0): return false
	for field: String in ["phase", "wave", "spawn_index", "kills", "breaches", "intercepted", "_serial", "event_serial", "attack_serial"]:
		if not SaveChecks.number(data.values[field], 0, 10000000, true): return false
	if int(data.values.phase) not in Phase.values() or data.values.wave > 10 or data.values.hull > HULL_MAX: return false
	if not data.get("recruitment_done") is Array or data.recruitment_done.size() > 4: return false
	var previous: int = 0
	for value: Variant in data.recruitment_done:
		if not SaveChecks.number(value, 2, 8, true) or int(value) not in [2,4,6,8] or value <= previous or value > data.values.wave + 1: return false
		previous = int(value)
	if data.get("last_cause") not in ["COMBAT_NO_DAMAGE", "M2_SWARMER_NAME", "M2_DIVER_NAME", "M2_CARRIER_NAME", "COMBAT_PROJECTILE", "M4_PLATED_NAME", "M4_ELITE_NAME"]: return false
	if data.get("last_kind") not in ["COMBAT_BREACH_HIT", "COMBAT_PROJECTILE_HIT"]: return false
	if is_m4: start_m4(int(data.random.seed), StringName(data.run_id))
	else: start_m3(int(data.random.seed), StringName(data.run_id))
	if is_m4 and not supports.restore(data.get("slice")): return false
	if not draft.restore(data.get("draft")): return false
	random.restore(data.random)
	apply_ranks()
	if not SaveChecks.number(data.get("shield"), 0, run.shield.capacity): return false
	for field: String in checkpoint_fields(): set(field, data.values[field])
	run.shield.current = float(data.shield)
	recruitment_done.assign(data.recruitment_done)
	last_cause = StringName(data.last_cause)
	last_kind = StringName(data.last_kind)
	# Only wave boundaries and decision/results screens are legal saves. No actors are serialized.
	if phase == Phase.COMBAT and (wave < 1 or spawn_index != 0 or spawn_time != 0): return false
	if phase == Phase.DRAFT and (draft.offers.is_empty() or wave < 1 or wave > 9): return false
	if phase != Phase.DRAFT and not draft.offers.is_empty(): return false
	if phase == Phase.RECRUIT and (wave + 1 not in [2,4,6,8] or wave + 1 in recruitment_done): return false
	if phase == Phase.VICTORY and (wave != 10 or draft.normal_count != 27): return false
	if phase == Phase.DEFEAT and hull != 0: return false
	if phase != Phase.DEFEAT and hull <= 0: return false
	var minimum: int = maxi(0, wave - 1) * 3
	var maximum: int = mini(27, wave * 3)
	if draft.normal_count < minimum or draft.normal_count > maximum: return false
	if phase in [Phase.COMBAT, Phase.DEFEAT] and draft.normal_count != minimum: return false
	if phase in [Phase.INTERMISSION, Phase.RECRUIT] and draft.normal_count != maximum: return false
	if draft.bonus_count > recruitment_done.size(): return false
	if phase == Phase.DRAFT:
		if draft.bonus and (draft.normal_count != maximum or wave + 1 not in recruitment_done): return false
		if not draft.bonus and draft.normal_count >= maximum: return false
	if phase in [Phase.COMBAT, Phase.INTERMISSION, Phase.VICTORY, Phase.DEFEAT]:
		for window: int in [2, 4, 6, 8]:
			var required_wave: int = wave + 1 if phase == Phase.INTERMISSION else wave
			if window <= required_wave and window not in recruitment_done: return false
	return true

func finish_endless() -> bool:
	if not BroadcastRules.expanded(self) or campaign.mode != "endless" or is_finished() or achievement_run.cleared_waves == 0: return false
	# Leaving commits only the last completed wave. Pending choices never count as clears.
	draft.offers.clear()
	draft.screen_tracks.clear()
	_finish(true)
	return true
