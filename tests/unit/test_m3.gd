extends RefCounted

func state(seed_value: int = 1, mocks: bool = false) -> DraftState:
	var catalog: Array[TrackDefinition] = M3Content.tracks().duplicate()
	if mocks:
		for index: int in 5:
			var definition: TrackDefinition = M3Content.ARC.duplicate() as TrackDefinition
			definition.id = StringName("fixture.support%d" % index)
			definition.options = []
			for original: UpgradeDefinition in M3Content.ARC.options:
				var option: UpgradeDefinition = original.duplicate() as UpgradeDefinition
				definition.options.append(option)
				option.id = StringName(String(option.id).replace("arc_aerial", String(definition.id)))
				option.target_id = definition.id
				option.prerequisite = StringName(String(option.prerequisite).replace("arc_aerial", String(definition.id)))
			catalog.append(definition)
	var result: DraftState = DraftState.new(catalog, RunRandom.new(seed_value))
	for definition: TrackDefinition in catalog:
		result.equip(definition.id)
	return result

func valid_offers(draft: DraftState) -> bool:
	if draft.offers.is_empty() or draft.offers.size() > 3 or not SaveChecks.unique(Array(draft.offers)): return false
	for id: StringName in draft.offers:
		if id in [DraftState.REPAIR, DraftState.REFILL]:
			for owned: UpgradeTrack in draft.tracks:
				if (not draft.bonus or owned.definition.support) and not owned.eligible(draft.banished).is_empty(): return false
		else:
			var card: UpgradeDefinition = draft.card(id)
			if card == null or draft.track(card.target_id) == null: return false
			if card not in draft.track(card.target_id).eligible(draft.banished): return false
	return true

func run(context: TestContext) -> bool:
	context.check(M3Content.validate().is_empty(), "M3 authored effects and identities validate")
	for definition: TrackDefinition in M3Content.tracks():
		for option: UpgradeDefinition in definition.options:
			context.check(TranslationServer.translate(option.name_key) != option.name_key and TranslationServer.translate(option.description_key) != option.description_key, "card name and effect translate: " + String(option.id))
	var draft: DraftState = state(13, true)
	context.check(draft.tracks.size() == 7 and draft.support_count() == 5, "mock roster enforces five supports plus independent main and shield")
	context.check(not draft.equip(&"arc_aerial") and not draft.equip(&"fixture.support4"), "cannot duplicate or equip a sixth support")
	var valid: bool = true
	var quotas: bool = true
	var overdue: bool = true
	var generated: int = 0
	# 400 missions x 27 screens = 10,800 original drafts, plus rerolls and banishes.
	for seed_value: int in 400:
		draft = state(seed_value, seed_value % 2 == 0)
		for screen: int in 27:
			var before: Dictionary = draft.absences.duplicate()
			draft.begin()
			generated += 1
			valid = valid and valid_offers(draft)
			for owned: UpgradeTrack in draft.tracks:
				if owned.eligible(draft.banished).is_empty(): continue
				var id: StringName = owned.definition.id
				if not owned.definition.support:
					quotas = quotas and int(draft.absences[String(id)]) <= 2
				elif int(before[String(id)]) >= 4 and id not in draft.screen_tracks:
					# If delayed, all three positions must be hard quotas or equally/more overdue supports.
					overdue = overdue and draft.screen_tracks.size() == 3
					for served: StringName in draft.screen_tracks:
						var hard_quota: bool = not draft.track(served).definition.support and int(before[String(served)]) >= 2
						overdue = overdue and (hard_quota or int(before[String(served)]) >= int(before[String(id)]))
			if screen == 1:
				var covered: Array[StringName] = draft.screen_tracks.duplicate()
				draft.reroll()
				valid = valid and valid_offers(draft) and covered == draft.screen_tracks
			if screen == 3:
				for id: StringName in draft.offers.duplicate():
					if draft.banish(id): break
				valid = valid and valid_offers(draft)
			valid = valid and draft.choose(draft.offers[seed_value % draft.offers.size()])
			valid = valid and draft.support_count() <= 5
		quotas = quotas and draft.normal_count == 27
	context.check(valid and generated >= 10000, "%d seeded drafts: eligible, distinct, compatible, within caps, no deadlocks" % generated)
	context.check(quotas, "main and shield offered at least once in every three eligible normal screens")
	context.check(overdue, "overdue supports serviced most-overdue-first after hard quotas")
	# Explicit saturated debt fixture, including tie stability and unavailable debt reset.
	draft = state(1, true)
	for owned: UpgradeTrack in draft.tracks: draft.absences[String(owned.definition.id)] = 5
	draft.absences["arc_aerial"] = 9
	draft.begin()
	context.check(draft.screen_tracks == [&"main", &"shield", &"arc_aerial"], "two hard quotas and oldest support share one screen")
	var before_absences: Dictionary = draft.absences.duplicate()
	draft.begin(true)
	context.check(draft.absences == before_absences and draft.screen_tracks.all(func(id: StringName) -> bool: return draft.track(id).definition.support), "recruitment bonus neither consumes quota screens nor offers main/shield")
	# Branch grammar, capstone reconstruction, actual typed effect application.
	for definition: TrackDefinition in M3Content.tracks():
		var owned: UpgradeTrack = UpgradeTrack.new(definition)
		while owned.rank() < 8:
			var options: Array[UpgradeDefinition] = owned.eligible([])
			var selected: UpgradeDefinition = options[0]
			var before: float = float(owned.stats[selected.stat])
			context.check(owned.accept(selected.id, []) and is_equal_approx(float(owned.stats[selected.stat]), before + selected.amount), "effect applied at rank %d: %s" % [owned.rank(), selected.id])
		context.check(owned.eligible([]).is_empty(), "rank 8 has no further upgrades: " + String(definition.id))
	draft = state()
	# All tracks rank 2: one required branch per track, protected from banish.
	for owned: UpgradeTrack in draft.tracks: owned.accept(owned.eligible([])[0].id, [])
	draft.begin()
	context.check(not draft.banish(draft.offers[0]) and draft.banishes == 1, "mandatory rank-3 choices cannot be banished")
	for owned: UpgradeTrack in draft.tracks:
		while owned.rank() < 8: owned.accept(owned.eligible([])[0].id, [])
	draft.begin()
	context.check(draft.offers == [DraftState.REPAIR, DraftState.REFILL] and draft.choose(DraftState.REPAIR), "no eligible tracks yields bounded consumables and advances selection")
	draft = state()
	for owned: UpgradeTrack in draft.tracks:
		while owned.rank() < (2 if owned.definition.id == &"arc_aerial" else 8): owned.accept(owned.eligible([])[0].id, [])
	draft.begin()
	context.check(draft.offers.size() == 1 and draft.card(draft.offers[0]).required_rank == 3, "fewer than three options remains selectable")
	var left: DraftState = state(999)
	var right: DraftState = state(999)
	var independent: bool = true
	for screen: int in 27:
		for noise: int in 17: right.random.rng("cosmetic").randf()
		left.begin()
		right.begin()
		independent = independent and left.offers == right.offers
		left.choose(left.offers[0])
		right.choose(right.offers[0])
	context.check(independent, "interleaved cosmetic RNG does not change any of 27 drafts")
	var rngs: RunRandom = RunRandom.new(9223372036854775807)
	for stream: String in RunRandom.STREAMS: rngs.rng(stream).randi()
	var encoded: Variant = JSON.parse_string(JSON.stringify(rngs.to_data()))
	var restored: RunRandom = RunRandom.new()
	restored.restore(encoded)
	var exact: bool = true
	for stream: String in RunRandom.STREAMS:
		exact = exact and rngs.rng(stream).randi() == restored.rng(stream).randi()
	context.check(exact, "all four RNG streams survive JSON without 64-bit precision loss")
	context.check(not RunRandom.valid({"seed":"9223372036854775808","wave":"0","draft":"0","combat":"0","cosmetic":"0"}), "overflowing RNG state rejected")
	_effect_tests(context)
	_save_tests(context)
	_mission_tests(context)
	return true

func _save_tests(context: TestContext) -> void:
	var session: CombatSession = CombatSession.new()
	session.start_m3(88, &"run.1")
	var profile: MissionProfile = MissionProfile.new()
	profile.next_run = 2
	var store: MissionStore = MissionStore.new("user://test_m3_store.json")
	for suffix: String in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(store.path + suffix): DirAccess.remove_absolute(store.path + suffix)
	var start: Dictionary = session.to_checkpoint()
	context.check(store.save(profile, start) == OK, "versioned profile/run atomic envelope writes initial checkpoint")
	var restored: CombatSession = CombatSession.new()
	var loaded: Dictionary = store.load_save()
	context.check(not loaded.is_empty() and restored.restore_checkpoint(loaded.run), "initial save loads through strict validation")
	session.advance(3)
	# Capture actual wave-start before actors exist using a checkpoint subscriber.
	session.start_m3(88, &"run.1")
	var snapshots: Array[Dictionary] = []
	var weak_session: WeakRef = weakref(session)
	session.checkpoint_changed.connect(func() -> void: snapshots.append((weak_session.get_ref() as CombatSession).to_checkpoint()))
	session.advance(10)
	context.check(not snapshots.is_empty() and snapshots[0].values.phase == CombatSession.Phase.COMBAT, "wave-start event occurs before spawning")
	var wave_start: Dictionary = snapshots[0]
	context.check(restored.restore_checkpoint(wave_start) and restored.actors.is_empty() and restored.kills == 0, "partial-wave actors and counters roll back at recovery")
	var replay: CombatSession = CombatSession.new()
	replay.restore_checkpoint(wave_start)
	restored.advance(5)
	replay.advance(5)
	context.check(restored.kills == replay.kills and restored.actors.size() == replay.actors.size() and restored.random.to_data() == replay.random.to_data(), "recovered wave reproduces spawn RNG and committed counters")
	while not session.is_deciding() and not session.is_finished(): session.advance(1)
	context.check(session.phase == CombatSession.Phase.DRAFT, "completed first wave reaches draft")
	session.reroll_draft()
	for id: StringName in session.draft.offers.duplicate():
		if session.banish_card(id): break
	var current: Dictionary = session.to_checkpoint()
	context.check(store.save(profile, current) == OK, "draft saves exact offers, reroll and banish tokens")
	loaded = store.load_save()
	context.check(not loaded.is_empty() and restored.restore_checkpoint(loaded.run) and restored.draft.to_data() == session.draft.to_data() and restored.random.to_data() == session.random.to_data(), "upgrade-screen recovery preserves exact offers and RNG")
	var pick: StringName = session.draft.offers[0]
	session.choose_upgrade(pick)
	restored.choose_upgrade(pick)
	context.check(restored.draft.to_data() == session.draft.to_data(), "accepting same saved choice produces same next screen and counts")
	context.check(store.save(profile, session.to_checkpoint()) == OK, "accepted choice commits next screen")
	var corrupt: FileAccess = FileAccess.open(store.path, FileAccess.WRITE)
	corrupt.store_string('{"schema":1,"run":')
	corrupt.close()
	loaded = store.load_save()
	context.check(not loaded.is_empty() and store.recovered and store.error == OK, "truncated primary recovers validated backup")
	corrupt = FileAccess.open(store.path + ".bak", FileAccess.WRITE)
	corrupt.store_string("broken")
	corrupt.close()
	context.check(store.load_save().is_empty() and store.error == ERR_FILE_CORRUPT, "unrecoverable files return safe recovery state")
	var bad: Dictionary = current.duplicate(true)
	bad.schema = 99
	context.check(not restored.restore_checkpoint(bad), "unknown future run schema rejected safely")
	bad = current.duplicate(true)
	bad.content = "m0.1"
	context.check(not restored.restore_checkpoint(bad), "incompatible content version rejected rather than silently migrated")
	bad = current.duplicate(true)
	bad.draft.offers = ["unknown.card"]
	context.check(not restored.restore_checkpoint(bad), "unknown saved card rejected")
	bad = current.duplicate(true)
	bad.draft.tracks[0].choices = ["main.capstone"]
	context.check(not restored.restore_checkpoint(bad), "impossible saved branch history rejected")
	bad = current.duplicate(true)
	bad.values.hull = "100"
	context.check(not restored.restore_checkpoint(bad), "string numeric combat state rejected")
	context.check(MissionStore.new("user://missing_m3_directory/save.json").save(profile, start) != OK, "unwritable save path reports failure")
	for suffix: String in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(store.path + suffix): DirAccess.remove_absolute(store.path + suffix)

func _mission_tests(context: TestContext) -> void:
	var session: CombatSession = CombatSession.new()
	session.start_m3(145, &"run.1")
	var events: Array[CombatEvent] = []
	session.combat_event.connect(func(event: CombatEvent) -> void: events.append(event))
	var windows: Array[int] = []
	var all_saved: bool = true
	var reload: CombatSession = CombatSession.new()
	var weak_session: WeakRef = weakref(session)
	session.checkpoint_changed.connect(func() -> void:
		var current_session: CombatSession = weak_session.get_ref() as CombatSession
		# Individual checkpoint validity, including every accepted choice and results.
		if not reload.restore_checkpoint(JSON.parse_string(JSON.stringify(current_session.to_checkpoint()))):
			context.check(false, "checkpoint rejected phase %d wave %d count %d" % [current_session.phase, current_session.wave, current_session.draft.normal_count]))
	for tick: int in 3000:
		if session.is_finished(): break
		if session.phase == CombatSession.Phase.DRAFT:
			var frozen: float = session.elapsed
			session.advance(50)
			all_saved = all_saved and session.elapsed == frozen
			session.choose_upgrade(session.draft.offers[0])
		elif session.phase == CombatSession.Phase.RECRUIT:
			windows.append(session.wave + 1)
			session.recruit(&"", [&"arc_aerial"])
		else: session.advance(0.5)
	context.check(session.phase == CombatSession.Phase.VICTORY, "natural auto-aim ten-wave M3 fixture reaches victory")
	print("M3 RUN: wave=%d selections=%d bonuses=%d seconds=%.2f hull=%.1f" % [session.wave, session.draft.normal_count, session.draft.bonus_count, session.elapsed, session.hull])
	context.check(session.draft.normal_count == 27 and session.draft.bonus_count == 4 and windows == [2,4,6,8], "exactly 27 normal choices and four separate recruitment bonuses before finale")
	context.check(all_saved and session.draft.offers.is_empty(), "drafts freeze simulation; finale goes directly to results")
	var ordered: bool = true
	var arc_damage: bool = false
	var root_hits: Dictionary = {}
	for event: CombatEvent in events:
		ordered = ordered and event.event_id > 0 and event.generation_depth == 0
		if event.kind == CombatEvent.Kind.DAMAGE:
			ordered = ordered and event.root_attack_id > 0 and event.source_id in [&"main", &"arc_aerial"]
			var key: String = "%d:%d" % [event.root_attack_id, event.target_id]
			ordered = ordered and not root_hits.has(key)
			root_hits[key] = true
			arc_damage = arc_damage or event.source_id == &"arc_aerial"
	context.check(ordered and arc_damage, "bounded distinct-target Arc attacks emit attributed root/source damage events")
	var profile: MissionProfile = MissionProfile.new()
	profile.next_run = 2
	profile.commit_reward(session.run_id)
	var store: MissionStore = MissionStore.new("user://test_m3_result.json")
	var once: bool = true
	for attempt: int in 5:
		once = once and store.save(profile, session.to_checkpoint()) == OK
		var data: Dictionary = store.load_save()
		once = once and not data.is_empty()
		if data.is_empty(): break
		profile.restore(data.profile)
		profile.commit_reward(session.run_id)
	context.check(once and profile.completed == 1, "results reward commits once across five actual disk reloads")
	var definition_before: float = float(M3Content.MAIN.baseline[&"damage"])
	session.run.temporary_modifier_ids.append(&"fixture")
	session.start_m3(146, &"run.2")
	context.check(session.run.main_weapon.rank == 1 and session.run.shield.rank == 1 and session.run.supports[0].rank == 1 and session.run.main_weapon.damage == 8.0 and session.draft.rerolls == 2 and session.draft.banishes == 1 and session.run.temporary_modifier_ids.is_empty(), "second mission resets ranks, stats, tokens and temporary modifiers")
	context.check(float(M3Content.MAIN.baseline[&"damage"]) == definition_before and profile.unlocked == [&"main", &"shield", &"arc_aerial"] and profile.completed == 1, "shared content stays immutable and profile options/record survive")
	for suffix: String in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(store.path + suffix): DirAccess.remove_absolute(store.path + suffix)

func _effect_tests(context: TestContext) -> void:
	for definition: TrackDefinition in M3Content.tracks():
		for card: UpgradeDefinition in definition.options:
			var owned: UpgradeTrack = UpgradeTrack.new(definition)
			while owned.rank() < maxi(1, card.required_rank - 1):
				owned.accept(owned.eligible([])[0].id, [])
			var before: Dictionary = owned.stats.duplicate()
			var applied: bool = owned.accept(card.id, [])
			applied = applied and is_equal_approx(float(owned.stats[card.stat]), float(before[card.stat]) + card.amount)
			if card.second_stat != &"":
				applied = applied and is_equal_approx(float(owned.stats[card.second_stat]), float(before[card.second_stat]) + card.second_amount)
			context.check(applied, "every exposed option applies both authored effects: " + String(card.id))
	var copied: TrackDefinition = M3Content.MAIN.duplicate() as TrackDefinition
	copied.options = []
	for original: UpgradeDefinition in M3Content.MAIN.options: copied.options.append(original.duplicate() as UpgradeDefinition)
	var own: UpgradeTrack = UpgradeTrack.new(copied)
	own.accept(&"main.gain", [])
	context.check(not own.accept(&"main.long_route", []) and not own.accept(&"shield.bastion", []), "future prerequisite and incompatible target cannot be accepted")
	copied.options[3].excludes = [&"main.gain"]
	context.check(own.eligible([]).is_empty(), "excluded authored branch is filtered")
	var recruit_session: CombatSession = CombatSession.new()
	recruit_session.start_m3(3, &"run.1")
	recruit_session.draft.catalog = state(3, true).catalog
	recruit_session.phase = CombatSession.Phase.RECRUIT
	recruit_session.wave = 1
	context.check(not recruit_session.recruit(&"fixture.support0", [&"arc_aerial"]), "recruitment rejects locked test family")
	context.check(recruit_session.recruit(&"fixture.support0", [&"fixture.support0"]) and recruit_session.draft.support_count() == 2 and recruit_session.draft.track(&"fixture.support0").rank() == 1, "mock recruitment equips an unlocked family at rank one in the scheduled window")
	context.check(not recruit_session.recruit(&"fixture.support1", [&"fixture.support1"]), "recruitment window cannot be used twice")
	var session: CombatSession = CombatSession.new()
	session.start_m3(4, &"run.1")
	var wave_state: int = session.random.rng("wave").state
	session.phase = CombatSession.Phase.DRAFT
	session.draft.begin()
	session.reroll_draft()
	context.check(session.random.rng("wave").state == wave_state, "reroll cannot change the mission spawn stream")
	session.phase = CombatSession.Phase.COMBAT
	var first: CombatActor = session.spawn_enemy(CombatContent.SWARMER, 300)
	var left: CombatActor = session.spawn_enemy(CombatContent.SWARMER, 150)
	var right: CombatActor = session.spawn_enemy(CombatContent.SWARMER, 450)
	for actor: CombatActor in [first, left, right]:
		actor.position.y = 300
		actor.health = 100
	var arc: UpgradeTrack = session.draft.track(&"arc_aerial")
	arc.stats[&"targets"] = 6.0
	arc.stats[&"range"] = 180.0
	arc.stats[&"branching"] = 0.0
	session._fire_track(arc, first)
	context.check([first, left, right].filter(func(a: CombatActor) -> bool: return a.health < 100).size() == 2, "ordinary Arc chain requires each successive contact within range")
	for actor: CombatActor in [first, left, right]: actor.health = 100
	arc.stats[&"branching"] = 1.0
	session._fire_track(arc, first)
	context.check([first, left, right].all(func(a: CombatActor) -> bool: return a.health == 95), "Arc capstone branches from prior contacts and hits each target once")
	var projectile: CombatActor = session.spawn_projectile(first)
	context.check(projectile.root_attack_id > 0 and projectile.source_id == first.definition_id and projectile.generation_depth == 0 and projectile.eligible_triggers & CombatEvent.CAN_REFLECT != 0, "generated hostile projectile carries root/source/depth/eligibility metadata")
	session.run.shield.current = 0
	session.recharge_time = 5
	session.ability_left = 2
	session.draft.track(&"shield").stats[&"brace_recharge"] = 6.0
	session.auto_fire = false
	session.spawn_time = 100
	session.wave = 1
	session.advance(0.1)
	context.check(session.run.shield.current > 0 and session.recharge_time > 0, "Live coil restores shield while brace is active during hit delay")
