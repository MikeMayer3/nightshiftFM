extends RefCounted

func session(seed_value: int = 42) -> CombatSession:
	var value: CombatSession = CombatSession.new()
	value.start_signal(seed_value, &"run.1")
	return value

func copy(value: CombatSession) -> CombatSession:
	var restored: CombatSession = CombatSession.new()
	if not restored.restore_checkpoint(JSON.parse_string(JSON.stringify(value.to_checkpoint(), "", true, true))): return null
	return restored

func run(context: TestContext) -> bool:
	for definition: TrackDefinition in SignalContent.tracks():
		for option: UpgradeDefinition in definition.options:
			context.check(option.validate().is_empty() and definition.baseline.has(option.stat), "signal option validates: " + String(option.id))
	for wave: WaveDefinition in SignalContent.WAVES:
		context.check(wave.validate().is_empty(), "signal wave validates")
	var value: CombatSession = session()
	context.check(copy(value) != null, "initial signal checkpoint round-trips")
	value.advance(2.1)
	value.auto_fire = false
	var source: CombatActor = value.actors[0]
	var bullet: CombatActor = value.spawn_projectile(source)
	value.damage_actor(bullet, 100)
	context.check(value.signal_progress.earned == 0 and value.intercepted == 1, "intercepting a projectile gives no signal")
	value.damage_actor(source, 100)
	value.damage_actor(source, 100)
	context.check(value.signal_progress.earned == 1 and value.kills == 1, "one enemy gives exactly one signal despite repeat damage")
	for index: int in 6:
		value.damage_actor(value.spawn_enemy(CombatContent.SWARMER, 320), 100)
	value.advance(CombatSession.STEP)
	context.check(value.phase == CombatSession.Phase.DRAFT and value.wave == 1 and value.spawn_index < value.wave_definition().enemy_ids.size(), "kill meter opens a choice during the wave")
	var frozen: String = JSON.stringify(value.to_checkpoint())
	value.advance(60)
	context.check(JSON.stringify(value.to_checkpoint()) == frozen and not value.activate_shield(), "choice freezes combat, timers, and ability input")
	context.check(value.draft.offers.any(func(id: StringName) -> bool: return SignalDraft.is_new(id)), "new weapon offered with offensive upgrades")
	context.check(not value.draft.offers.any(func(id: StringName) -> bool: return value.draft.card(id).target_id == &"shield"), "passive shield upgrades excluded")
	var restored: CombatSession = copy(value)
	context.check(restored != null and restored.draft.offers == value.draft.offers, "pending mid-wave choice restores exact offers")
	if restored == null: return false
	var recruit: StringName = value.draft.offers[0]
	context.check(value.choose_upgrade(recruit) and restored.choose_upgrade(recruit), "new weapon spends one earned choice")
	context.check(value.signal_progress.progress() == 2 and value.signal_progress.threshold() == 7 and value.phase == CombatSession.Phase.COMBAT, "meter carries overflow and resumes same wave")
	context.check(value.draft.track(value.draft.card(recruit).target_id).rank() == 1 and recruit not in (value.draft as SignalDraft).pool(), "new weapon starts rank 1 and cannot be recruited twice")
	context.check(copy(value) != null and not value.choose_upgrade(recruit), "accepted-choice save is valid and repeat purchase rejected")
	value.auto_fire = true
	for index: int in 30:
		value.advance(0.25)
		restored.advance(0.25)
	context.check(JSON.stringify(value.to_checkpoint()) == JSON.stringify(restored.to_checkpoint()), "same decision gives deterministic combat after JSON restore")
	var malformed: Dictionary = value.to_checkpoint()
	malformed.signal.earned += 1
	context.check(not CombatSession.new().restore_checkpoint(malformed), "save rejects signal inconsistent with kills")
	malformed = value.to_checkpoint()
	malformed.draft.offers = ["shield.reserve"]
	context.check(not CombatSession.new().restore_checkpoint(malformed), "save rejects injected defensive choice")
	_branches(context)
	_effects(context)
	_overflow(context)
	_exhaustion(context)
	var proofs: Array[Dictionary] = []
	for style: String in ["main", "arc", "bass", "net", "random"]:
		for seed_value: int in [11, 42, 91]:
			var proof: Dictionary = play(style, seed_value, context)
			context.check(not proof.is_empty(), "signal simulation completed: " + style)
			proofs.append(proof)
	var file: FileAccess = FileAccess.open("res://docs/evidence/M4-signal/balance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(proofs, "\t"))
	return true

func _effects(context: TestContext) -> void:
	var value: CombatSession = session()
	# Obtain both new weapons through earned choices so reconstruction validates the build.
	value.advance(2.1)
	for family: StringName in [&"bass_driver", &"static_net"]:
		value.signal_progress.earned += value.signal_progress.threshold()
		value.kills = value.signal_progress.earned
		value._open_signal_choice()
		var id: StringName = StringName("recruit." + String(family))
		while id not in value.draft.offers: value.draft.begin()
		value.choose_upgrade(id)
	var target: CombatActor = value.spawn_enemy(M4Content.ELITE, 320)
	target.position.y = 400
	value.supports.deploy_net(value, value.draft.track(&"static_net"), target.position)
	value.supports.shocks.append({"y": 500.0, "root": value.attack_serial, "hit": [], "width": 180.0, "x": 320.0, "end_y": 150.0})
	target.status.charge()
	target.status.expose(25)
	target.status.apply_slow(0.2, true)
	value.spawn_projectile(target)
	var restored: CombatSession = copy(value)
	context.check(restored != null, "active enemies, projectile, net, shock and statuses round-trip")
	if restored == null: return
	context.check(JSON.stringify(restored.to_checkpoint()) == JSON.stringify(value.to_checkpoint()), "active snapshot preserves every serialized field")
	for index: int in 20:
		value.advance(CombatSession.STEP)
		restored.advance(CombatSession.STEP)
	context.check(JSON.stringify(restored.to_checkpoint()) == JSON.stringify(value.to_checkpoint()), "restored active effects produce identical subsequent combat")
	context.check(value.supports.report.totals.static_net.damage > 0, "baseline Static Net now deals damage")
	var owned: UpgradeTrack = UpgradeTrack.new(SignalContent.ARC)
	owned.accept(&"arc_aerial.gain", [])
	owned.accept(&"arc_aerial.spear", [])
	var health: float = target.health
	value.supports.arc(value, owned, target)
	context.check(target.health < health and value.run.shield.current <= value.run.shield.capacity, "Lightning Spear is a damaging offensive branch")

func _overflow(context: TestContext) -> void:
	var value: CombatSession = session()
	value.advance(2.1)
	value.signal_progress.earned = 12
	value.kills = 12
	value._open_signal_choice()
	value.choose_upgrade(value.draft.offers[0])
	context.check(value.phase == CombatSession.Phase.DRAFT and value.signal_progress.progress() == 7, "multiple fills queue choices without dropping overflow")
	value.choose_upgrade(value.draft.offers[0])
	context.check(value.phase == CombatSession.Phase.COMBAT and value.signal_progress.progress() == 0, "second queued choice consumes exact next threshold")
	value.wave = 10
	value.spawn_index = value.wave_definition().enemy_ids.size()
	value.actors.clear()
	value.signal_progress.earned += value.signal_progress.threshold()
	value.kills = value.signal_progress.earned
	value.advance(CombatSession.STEP)
	context.check(value.phase == CombatSession.Phase.VICTORY and value.draft.offers.is_empty(), "final victory wins over a newly full meter")
	context.check(copy(value) != null, "signal victory save validates without legacy 27-pick quota")

func play(style: String, seed_value: int, context: TestContext) -> Dictionary:
	var value: CombatSession = session(seed_value)
	var decisions: Array[Dictionary] = []
	var pick_rng: RandomNumberGenerator = RandomNumberGenerator.new()
	pick_rng.seed = seed_value
	var snapshots_ok: bool = true
	for step: int in 6000:
		if value.is_finished(): break
		if value.is_deciding():
			if copy(value) == null: snapshots_ok = false; break
			var choice: StringName = value.draft.offers[pick_rng.randi_range(0, value.draft.offers.size() - 1)]
			var priority: StringName = {"main": &"main", "arc": &"arc_aerial", "bass": &"bass_driver", "net": &"static_net"}.get(style, &"")
			for id: StringName in value.draft.offers:
				if value.draft.card(id).target_id == priority: choice = id
			decisions.append({"seconds": value.elapsed, "wave": value.wave, "id": String(choice)})
			if not value.choose_upgrade(choice): return {}
		else: value.advance(0.25)
	context.check(snapshots_ok and value.is_finished(), "all live decision snapshots validate: " + style + "/" + str(seed_value))
	return {"style": style, "seed": seed_value, "victory": value.phase == CombatSession.Phase.VICTORY, "seconds": value.elapsed, "kills": value.kills, "hull": value.hull, "damage_taken": value.damage_taken, "choices": decisions, "contributions": value.supports.report.totals}

func _exhaustion(context: TestContext) -> void:
	var value: CombatSession = session()
	value.advance(2.1)
	for index: int in 40:
		value.signal_progress.earned += value.signal_progress.threshold()
		value.kills = value.signal_progress.earned
		value._open_signal_choice()
		if value.draft.offers[0] == SignalDraft.OVERDRIVE: break
		value.choose_upgrade(value.draft.offers[0])
	context.check(value.draft.offers == [SignalDraft.OVERDRIVE] and value.draft.track(&"shield").rank() == 1, "exhausted offensive pool offers Overdrive without defensive filler")
	context.check(not value.reroll_draft() and not value.banish_card(SignalDraft.OVERDRIVE), "fallback cannot waste reroll or banish")
	context.check(value.choose_upgrade(SignalDraft.OVERDRIVE) and value.signal_progress.overdrive_left == 20, "Overdrive grants a bounded damage window")
	context.check(copy(value) != null, "fully ranked build and temporary Overdrive survive JSON recovery")
	var actor: CombatActor = value.spawn_enemy(M4Content.ELITE, 320)
	actor.armor = 0
	var before: float = actor.health
	value.damage_actor(actor, 8)
	context.check(is_equal_approx(before - actor.health, 10), "Overdrive multiplies weapon damage by 25 percent")
	value.advance(1)
	context.check(value.signal_progress.overdrive_left < 20, "Overdrive expires with active simulation time")
	value.signal_progress.earned += value.signal_progress.threshold()
	value.kills = value.signal_progress.earned
	value._open_signal_choice()
	value.choose_upgrade(SignalDraft.OVERDRIVE)
	context.check(value.signal_progress.overdrive_left == 20, "repeated Overdrive refreshes duration without stacking strength")
	var bad: Dictionary = value.to_checkpoint()
	bad.values.phase = CombatSession.Phase.INTERMISSION
	bad.values.wave = 10
	bad.actors.clear()
	context.check(not CombatSession.new().restore_checkpoint(bad), "save rejects an intermission beyond the final wave")
	value = session()
	value.advance(30)
	var previous: Array[StringName] = value.draft.offers.duplicate()
	context.check(value.reroll_draft() and not value.draft.offers.any(func(id: StringName) -> bool: return id in previous), "first reroll favors fresh weapon and tuning cards when all have alternatives")
	var common: StringName = &""
	for id: StringName in value.draft.offers:
		if value.draft.card(id).required_rank == 0: common = id
	context.check(value.banish_card(common) and common not in (value.draft as SignalDraft).pool() and copy(value) != null, "offensive banish persists without adding defensive offers")

func ranked(family: StringName, branch: StringName, modifier: StringName) -> UpgradeTrack:
	var value: CombatSession = session()
	value.draft.equip(family)
	var owned: UpgradeTrack = value.draft.track(family)
	while owned.rank() < 8:
		var options: Array[UpgradeDefinition] = owned.eligible([])
		var choice: StringName = options[0].id
		for option: UpgradeDefinition in options:
			if option.id in [branch, modifier]: choice = option.id
		if not owned.accept(choice, []): return null
	return owned

func _branches(context: TestContext) -> void:
	for modifier: StringName in [&"arc_aerial.needle", &"arc_aerial.strike"]:
		var owned: UpgradeTrack = ranked(&"arc_aerial", &"arc_aerial.spear", modifier)
		context.check(owned != null and modifier in owned.choices and &"arc_aerial.spear_cap" in owned.choices, "new Arc path reaches rank-8 capstone: " + String(modifier))
		var value: CombatSession = session()
		value.wave = 1
		value.phase = CombatSession.Phase.COMBAT
		for index: int in 4:
			var actor: CombatActor = value.spawn_enemy(M4Content.ELITE, 320)
			actor.position.y = 400 - index * 50
		var health: float = value.actors[0].health
		value.supports.arc(value, owned, value.actors[0])
		var penetration: float = 65 if modifier == &"arc_aerial.needle" else 35
		var scale: float = 0.85 if modifier == &"arc_aerial.needle" else 1.7
		var expected: float = float(owned.stats[&"damage"]) * 2 * scale * 100 / (100 + maxf(0, value.actors[0].armor - penetration))
		context.check(is_equal_approx(health - value.actors[0].health, expected), "Spear damage uses correct armor penetration and modifier")
		context.check(value.actors[2].health < health and value.actors[3].health == health, "Spear capstone hits three distinct aligned enemies at most")
		context.check(value.supports.report.totals.arc_aerial.healing == 0, "new Arc branch has no passive shield effect")
	for modifier: StringName in [&"static_net.rapid", &"static_net.surge"]:
		var owned: UpgradeTrack = ranked(&"static_net", &"static_net.current", modifier)
		context.check(owned != null and modifier in owned.choices and &"static_net.live_cap" in owned.choices, "new Net path reaches rank-8 capstone: " + String(modifier))
		var value: CombatSession = session()
		value.wave = 1
		value.phase = CombatSession.Phase.COMBAT
		for index: int in 10:
			var actor: CombatActor = value.spawn_enemy(M4Content.ELITE, 320)
			actor.position.y = 400
		value.supports.deploy_net(value, owned, Vector2(320, 400))
		var expected: float = float(owned.stats[&"damage"]) * 1.5 * 1.5 * (0.75 if modifier == &"static_net.rapid" else 2.0)
		context.check(is_equal_approx(value.supports.field.damage, expected) and value.supports.field.tick_interval == (0.5 if modifier == &"static_net.rapid" else 1.25), "Live Current modifier and capstone alter real field damage and tick interval")
		var health: float = value.actors[0].health
		value.supports._tick_field(value, CombatSession.STEP)
		context.check(value.actors[7].health < health and value.actors[8].health == health, "damaging Net tick is bounded to eight enemies")
		context.check(is_equal_approx(value.supports.field.left, float(owned.stats[&"duration"]) + 1 - CombatSession.STEP), "Live Broadcast adds exactly one second of field duration")
