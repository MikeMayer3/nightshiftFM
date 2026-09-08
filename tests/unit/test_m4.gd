extends RefCounted

func session() -> CombatSession:
	var value: CombatSession = CombatSession.new()
	value.start_m4(410, &"run.1")
	value.phase = CombatSession.Phase.COMBAT
	value.wave = 1
	return value

func ranked(track: StringName, branch: String, modifier: String, rank: int = 8) -> UpgradeTrack:
	var value: CombatSession = session()
	value.draft.equip(track)
	var owned: UpgradeTrack = value.draft.track(track)
	while owned.rank() < rank:
		var options: Array[UpgradeDefinition] = owned.eligible([])
		var chosen: UpgradeDefinition = options[0]
		for option: UpgradeDefinition in options:
			if String(option.id) == String(track) + "." + branch or String(option.id) == String(track) + "." + modifier: chosen = option
		owned.accept(chosen.id, [])
	return owned

func enemy(value: CombatSession, position: Vector2, armored: bool = false) -> CombatActor:
	var actor: CombatActor = value.spawn_enemy(M4Content.ELITE if armored else CombatContent.SWARMER, position.x)
	actor.position = position
	actor.health = 10000
	actor.max_health = 10000
	return actor

func run(context: TestContext) -> bool:
	context.check(M4Content.validate().is_empty(), "M4 catalog validates all tracks, effects and ten waves")
	context.check(M4Content.tracks().size() == 5 and M4Content.WAVES.size() == 10, "M4 contains only main/shield and three support families")
	var paths: Dictionary = {"arc_aerial": [["storm", "long_route"], ["storm", "tight"], ["tap", "quick"], ["tap", "reserve"]], "bass_driver": [["wide", "wide_cone"], ["wide", "deep"], ["compression", "hard"], ["compression", "direct"]], "static_net": [["dead", "blank"], ["dead", "hum"], ["screen", "dense"], ["screen", "wide"]]}
	for family: String in paths:
		for route: Array in paths[family]:
			var owned: UpgradeTrack = ranked(StringName(family), route[0], route[1])
			context.check(owned.rank() == 8 and owned.choices.has(StringName(family + "." + route[0])) and owned.choices.has(StringName(family + "." + route[1])), "legal complete rank-8 path: " + family + "/" + route[1])
			var replay: UpgradeTrack = UpgradeTrack.new(owned.definition)
			for id: StringName in owned.choices: replay.accept(id, [])
			context.check(replay.stats == owned.stats and replay.eligible([]).is_empty(), "rank reconstruction and cap: " + family + "/" + route[1])
	# Every tuning has a live supported stat and changes its runtime value.
	for definition: TrackDefinition in [M4Content.ARC, M4Content.BASS, M4Content.NET]:
		for card: UpgradeDefinition in definition.options:
			if card.required_rank != 0: continue
			var owned: UpgradeTrack = UpgradeTrack.new(definition)
			var before: float = float(owned.stats[card.stat])
			context.check(owned.accept(card.id, []) and is_equal_approx(float(owned.stats[card.stat]), before + card.amount), "effective tuning: " + String(card.id))
	_status_checks(context)
	_support_checks(context)
	_save_checks(context)
	var proofs: Array[Dictionary] = []
	for style: String in ["damage", "defense"]:
		var proof: Dictionary = play(style, context)
		context.check(not proof.is_empty(), "simulation completed without script error: " + style)
		proofs.append(proof)
	var file: FileAccess = FileAccess.open("res://docs/evidence/M4/simulated-builds.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(proofs, "\t"))
	return true

func _status_checks(context: TestContext) -> void:
	var status: StatusState = StatusState.new()
	for i: int in 50:
		status.charge()
		status.apply_slow(4, false)
		status.expose(999)
	context.check(status.charged == 3 and status.slow == 0.6 and status.exposure == 100, "charge, slow and exposure have hard caps")
	status.advance(3.1)
	context.check(status.charged == 0 and status.slow == 0 and status.exposure == 0, "status durations expire without permanent modifiers")
	status.apply_slow(1, true)
	context.check(status.slow == 0.25, "elite slow is capped at 25 percent")
	context.check(status.jam(2, true, false) and status.jam_left == 0.2 and not status.jam(2, true, false), "elite interrupt capped and repeat jam rejected")
	status.advance(0.3)
	status.jam(2, true, false)
	context.check(status.ability_rate() == 0.8, "elite on cooldown retains ability slowdown fallback")
	status = StatusState.new()
	context.check(not status.jam(1, true, true) and status.ability_rate() == 0.8, "jam immunity retains ability slowdown")
	var value: CombatSession = session()
	var actor: CombatActor = enemy(value, Vector2(320, 400), true)
	actor.status.expose(100)
	value.damage_actor(actor, 20)
	context.check(is_equal_approx(actor.health, 9980), "exposure reduces armor to zero without negative armor amplification")
	context.check(value.supports.report.totals.main.damage == 20 and value.supports.report.totals.bass_driver.exposure_bonus > 0, "damage and exposure assistance have separate attribution")
	var pulse: UpgradeTrack = ranked(&"bass_driver", "compression", "hard")
	actor.displacement_immune = true
	value.supports.bass(value, pulse, actor)
	context.check(actor.status.slow == 0.15 and actor.status.slow_source == &"bass_driver", "displacement immune targets retain Bass movement-control value")
	value.run.shield.current = 5
	value.hit_station(8, &"M4_ELITE_NAME")
	value.hit_station(8, &"M4_ELITE_NAME")
	context.check(value.supports.report.totals.shield.breaks == 1 and value.supports.report.totals.shield.absorbed == 5, "true shield break fires once; empty shield does not repeatedly break")
	actor.status.charge()
	var before: Dictionary = value.to_checkpoint()
	for i: int in 20:
		value.paused = true
		value.advance(2)
		context.check(value.to_checkpoint() == before and actor.status.charge_left == 3, "pause freezes statuses, contribution and timers cycle %d" % i)
		value.paused = false

func _support_checks(context: TestContext) -> void:
	for route: String in ["long_route", "tight"]:
		var value: CombatSession = session()
		var owned: UpgradeTrack = ranked(&"arc_aerial", "storm", route)
		var a: CombatActor = enemy(value, Vector2(320, 350))
		var b: CombatActor = enemy(value, Vector2(320, 580))
		value.supports.arc(value, owned, a)
		context.check((b.health < 10000) == (route == "long_route"), "Arc rank-6 changes reachable contacts: " + route)
	var value: CombatSession = session()
	var owned: UpgradeTrack = ranked(&"arc_aerial", "storm", "long_route")
	for i: int in 12: enemy(value, Vector2(280 + i * 6, 400))
	value.supports.arc(value, owned, value.actors[0])
	context.check(value.actors.filter(func(a: CombatActor) -> bool: return a.health < 10000).size() == 6, "Broadcast Storm hits at most six distinct targets")
	for route: String in ["quick", "reserve"]:
		value = session()
		owned = ranked(&"arc_aerial", "tap", route)
		value.draft.tracks[2] = owned
		value.apply_ranks()
		value.run.shield.current = 20
		var actor: CombatActor = enemy(value, Vector2(320, 400))
		value.supports.arc(value, owned, actor)
		context.check(is_equal_approx(value.run.shield.current, 21.5 if route == "quick" else 20.0), "Shield Tap modifier has real restoration behavior: " + route)
		var shield_before: float = value.run.shield.current
		value.supports.arc(value, owned, actor)
		context.check(value.run.shield.current == shield_before and value.supports.reservoir == 2, "direct hit restoration has a shared cooldown")
		for i: int in 5:
			value.supports.restore_wait = 0
			value.supports.arc(value, owned, actor)
		value.activate_shield()
		context.check(value.supports.overshield == 10 and value.supports.reservoir == 0, "Closed Circuit consumes full reservoir for bounded overshield: " + route)
		if route == "reserve": context.check(value.run.shield.current == 32, "Reserve Charge releases exactly stored energy on brace")
		value.run.shield.current = value.run.shield.capacity
		shield_before = value.supports.report.totals.arc_aerial.healing
		value.supports.heal(value, 100, &"arc_aerial")
		context.check(value.supports.report.totals.arc_aerial.healing == shield_before, "contribution excludes overhealing")
	for route: String in ["wide_cone", "deep"]:
		value = session()
		owned = ranked(&"bass_driver", "wide", route, 6)
		var a: CombatActor = enemy(value, Vector2(320, 400))
		var side: CombatActor = enemy(value, Vector2(495, 400))
		var forward: CombatActor = enemy(value, Vector2(320, 210))
		value.supports.bass(value, owned, a)
		context.check((side.health < 10000) == (route == "wide_cone") and (forward.health < 10000) == (route == "deep"), "Bass rank-6 changes area shape: " + route)
	for route: String in ["hard", "direct"]:
		value = session()
		owned = ranked(&"bass_driver", "compression", route)
		var a: CombatActor = enemy(value, Vector2(320, 400), true)
		value.supports.bass(value, owned, a)
		context.check(a.status.exposure == (85 if route == "hard" else 60) and a.health < 10000, "Compression modifier and capstone apply exposure and damage: " + route)
		context.check(a.position.y > 390, "elite knockback resistance is retained")
	value = session()
	owned = ranked(&"bass_driver", "wide", "wide_cone")
	value.draft.equip(&"bass_driver")
	value.draft.tracks[3] = owned
	for i: int in 20: enemy(value, Vector2(250 + i * 5, 500))
	value.supports.bass(value, owned, value.actors[0])
	for i: int in 120: value.supports._tick_shocks(value, CombatSession.STEP)
	context.check(value.supports.shocks.is_empty() and value.actors.filter(func(a: CombatActor) -> bool: return a.health < 10000).size() == 12, "Wall of Sound travels finitely and hits only 12 distinct targets")
	for route: Array in [["dead", "blank"], ["dead", "hum"], ["screen", "dense"], ["screen", "wide"]]:
		value = session()
		owned = ranked(&"static_net", route[0], route[1])
		var actor: CombatActor = enemy(value, Vector2(320, 400))
		value.supports.deploy_net(value, owned, actor.position)
		value.supports._tick_field(value, 0.01)
		context.check(actor.status.slow > 0 and (actor.status.jam_left > 0) == (route[0] == "dead"), "Net path applies appropriate control: " + String(route[1]))
		if route[0] == "screen":
			for i: int in 20: value.spawn_projectile(actor)
			value.supports._tick_field(value, 0.01)
			context.check(value.intercepted == 12 and value.supports.field.charges == 0 and value.supports.report.totals.static_net.intercepts == 12, "Signal Firewall enforces 12-shot budget: " + String(route[1]))
		else:
			context.check(value.supports.field.jam > 0.3 and value.supports.field.left > 3, "Dead Zone extends field and bounded interruption")
		value.supports._tick_field(value, 10)
		context.check(value.supports.field.is_empty(), "Net fields expire without self-extension")

func _save_checks(context: TestContext) -> void:
	var value: CombatSession = session()
	value.supports.report.add(&"static_net", &"slow_seconds", 12.5)
	value.supports.reservoir = 8
	value.supports.timers.bass_driver = 1.2
	var data: Dictionary = value.to_checkpoint()
	var restored: CombatSession = CombatSession.new()
	context.check(restored.restore_checkpoint(JSON.parse_string(JSON.stringify(data))) and restored.to_checkpoint() == data, "M4 contribution, support timers, reservoir and draft restore exactly")
	var invalid: Dictionary = data.duplicate(true)
	invalid.slice.report.static_net.healing = -1
	context.check(not CombatSession.new().restore_checkpoint(invalid), "invalid contribution data rejected")
	var legacy: CombatSession = CombatSession.new()
	legacy.start_m3(88, &"run.1")
	context.check(restored.restore_checkpoint(legacy.to_checkpoint()) and restored.supports == null and restored.draft.catalog.size() == 3, "M3 saved missions retain original content and continue unchanged")
	var profile: MissionProfile = MissionProfile.new()
	profile.next_run = 2
	profile.enable_m4()
	var store: MissionStore = MissionStore.new("user://test_m4_mission.json")
	context.check(store.save(profile, data) == OK and restored.restore_checkpoint(store.load_save().run) and restored.to_checkpoint() == data, "M4 saves pass atomic disk validation")
	value.supports.report.add(&"static_net", &"slow_seconds", 99)
	context.check(restored.restore_checkpoint(store.load_save().run) and restored.supports.report.totals.static_net.slow_seconds == 12.5, "partial-wave recovery discards uncommitted contribution")
	value.start_m4(999, &"run.2")
	context.check(value.supports.report.totals.static_net.slow_seconds == 0 and value.supports.reservoir == 0 and value.draft.support_count() == 1, "new M4 mission clears supports, reservoir and report")

func play(style: String, context: TestContext) -> Dictionary:
	var value: CombatSession = CombatSession.new()
	value.start_m4(420, &"run.1")
	var selections: Array[String] = []
	var checkpoints: Array[Dictionary] = []
	var chosen_support: StringName = &"bass_driver" if style == "damage" else &"static_net"
	for step: int in 12000:
		if value.is_finished(): break
		if value.phase == CombatSession.Phase.DRAFT:
			var priorities: Array[StringName] = [chosen_support, &"arc_aerial", &"main", &"shield"]
			if style == "defense": priorities.assign([chosen_support, &"arc_aerial", &"shield", &"main"])
			if value.draft.track(&"main").rank() < 3 or (value.wave >= 3 and value.draft.track(&"main").rank() < 6): priorities.assign([&"main", chosen_support, &"arc_aerial", &"shield"])
			elif value.wave >= 4 and value.draft.track(&"shield").rank() < 3: priorities.assign([&"shield", chosen_support, &"arc_aerial", &"main"])
			var choice: StringName = value.draft.offers[0]
			for track: StringName in priorities:
				var found: bool = false
				for id: StringName in value.draft.offers:
					var option: UpgradeDefinition = value.draft.card(id)
					if option != null and option.target_id == track:
						choice = id
						found = true
						break
				if found: break
			var card: UpgradeDefinition = value.draft.card(choice)
			if card != null and card.required_rank in [3,6]:
				var preferred: Array[String] = ["arc_aerial.storm", "arc_aerial.tight", "bass_driver.compression", "bass_driver.hard"]
				if style == "defense": preferred.assign(["arc_aerial.tap", "arc_aerial.reserve", "static_net.dead", "static_net.hum"])
				for id: String in preferred:
					if id.begins_with(String(card.target_id) + ".") and value.swap_branch(StringName(id)): choice = StringName(id)
			selections.append(String(choice))
			value.choose_upgrade(choice)
		elif value.phase == CombatSession.Phase.RECRUIT:
			value.recruit(chosen_support if value.draft.track(chosen_support) == null else &"", [chosen_support])
		else:
			if value.run.shield.current < 30 or (value.supports.reservoir == 12 and value.draft.track(&"arc_aerial").rank() == 8): value.activate_shield()
			value.advance(0.25)
		if value.is_deciding() or value.is_finished():
			var checkpoint: Dictionary = value.to_checkpoint()
			var copy: CombatSession = CombatSession.new()
			if not copy.restore_checkpoint(JSON.parse_string(JSON.stringify(checkpoint))):
				context.check(false, "M4 simulated boundary save valid")
				break
			checkpoints.append({"wave": value.wave, "phase": value.phase, "hull": value.hull})
	context.check(value.phase == CombatSession.Phase.VICTORY and value.draft.normal_count == 27, "SIMULATED Standard completion with 27 picks: " + style)
	return {"type": "AUTOMATED, not human acceptance", "build": style, "won": value.phase == CombatSession.Phase.VICTORY, "wave": value.wave, "seconds": value.elapsed, "hull": value.hull, "choices": selections, "contribution": value.supports.report.totals, "boundaries": checkpoints}
