extends RefCounted
const M5: Script = preload("res://tests/unit/test_arsenal.gd")
const AIM: Script = preload("res://tests/active_balance.gd")

func fixture(id: StringName, connected: bool = true, main: String = "pulse", shield: String = "capacitor") -> CombatSession:
	var r: SynergyDefinition = PatchboardContent.RECIPES[id]
	var s: CombatSession = M5.new().fixture(main, shield)
	s.patchboard = PatchboardState.new()
	s.patchboard.awaiting = false
	s.active_combat.content_version = PatchboardContent.VERSION
	for endpoint: StringName in r.endpoint_ids:
		if endpoint not in [&"main", &"shield"]: s.draft.equip(endpoint)
	if r.capability == &"marked":
		var owned: UpgradeTrack = s.draft.track(&"needle_swarm")
		s.draft.tracks[s.draft.tracks.find(owned)] = M5.new().path(owned.definition, 3, 1, 0, 3)
	if connected: s.patchboard.slots[0] = id
	return s

func deploy(s: CombatSession, id: StringName, center: Vector2) -> void:
	s.arsenal._deploy(s, center, id, ArsenalStats.parameters(s.draft.track(id)), s.arsenal._root(s, id, 1))

func packet(s: CombatSession, source: String, target: CombatActor) -> Dictionary:
	var p: Dictionary = ArsenalStats.parameters(s.draft.track(&"main"))
	if source == "echo_deck":
		p[&"retarget"] = 700
		p[&"distinct"] = 0
		p[&"priority"] = 0
		p[&"copy_index"] = 0
	return {"source": source, "kind": (s.draft as ArsenalDraft).loadout.main, "root": s.arsenal._root(s, StringName(source), target.serial), "target": target.serial, "x": target.position.x, "y": target.position.y, "left": 0.0, "p": p}

func exercise(s: CombatSession, id: StringName) -> void:
	var actor: CombatActor = s.actors[0]
	match id:
		&"ball_lightning":
			deploy(s, &"reverb_well", actor.position)
			for target: CombatActor in s.actors: target.status.charge()
			for index: int in 3:
				s.arsenal._arc(s, actor, ArsenalStats.parameters(s.draft.track(&"arc_aerial")), s.arsenal._root(s, &"arc_aerial", actor.serial))
		&"dead_zone":
			for target: CombatActor in s.actors: target.status.apply_slow(.3, false)
			deploy(s, &"bass_driver", actor.position)
			s.arsenal._tick_zones(s, .01)
		&"b_side":
			s.arsenal.marks.append({"target": s.actors[3].serial, "strength": .2, "left": 3.0})
			s.arsenal._resolve_packet(s, packet(s, "echo_deck", actor))
		&"live_wire":
			deploy(s, &"static_net", actor.position)
			s.arsenal._tick_zones(s, .01)
		&"pressure_drop":
			deploy(s, &"reverb_well", actor.position)
			deploy(s, &"reverb_well", actor.position)
			deploy(s, &"bass_driver", actor.position)
		&"double_drop":
			for index: int in 3: deploy(s, &"bass_driver", actor.position)
		&"needle_thread":
			s.arsenal.marks.append({"target": actor.serial, "strength": .2, "left": 3.0})
			s.arsenal.fire_main(s, actor)
		&"feedback_loop":
			s.run.shield.current = 1
			s.hit_station(2, &"M2_SWARMER_NAME")

func run(t: TestContext) -> bool:
	for id: StringName in PatchboardContent.RECIPES:
		var r: SynergyDefinition = PatchboardContent.RECIPES[id]
		t.check(r.validate().is_empty(), "M6 validated recipe " + String(id))
		var active: CombatSession = fixture(id)
		var inactive: CombatSession = fixture(id, false)
		var events: Array[CombatEvent] = []
		active.combat_event.connect(func(e: CombatEvent) -> void:
			if e.source_id == id: events.append(e))
		exercise(active, id)
		exercise(inactive, id)
		t.check(active.patchboard.totals[String(id)].triggers > 0, String(id) + " triggers from actual combat hooks")
		t.check(inactive.patchboard.totals[String(id)].triggers == 0, String(id) + " inactive recipe has no output")
		t.check(id in active.patchboard.discovered(), String(id) + " discovered only on first trigger")
		t.check(events.all(func(e: CombatEvent) -> bool: return e.generation_depth == 1 and e.eligible_triggers == 0 and e.root_attack_id > 0), String(id) + " generated events cannot echo, reflect or trigger recipes")
		var before: Dictionary = active.patchboard.to_data()
		active.paused = true
		active.advance(10)
		t.check(active.patchboard.to_data() == before, String(id) + " cooldowns and counters freeze during pause")
		active.paused = false
		# Detaching either real endpoint disables an already connected recipe.
		var endpoint: StringName = r.endpoint_ids[1]
		active.draft.tracks.erase(active.draft.track(endpoint))
		t.check(not active.patchboard.connected(active, id), String(id) + " missing endpoint prevents stale activation")
	_eligibility(t)
	_contracts(t)
	_saves(t)
	_live_mission(t)
	return true

func _eligibility(t: TestContext) -> void:
	var s: CombatSession = CombatSession.new()
	s.start_patchboard(7, &"run.1")
	t.check(s.is_wiring(), "new run starts at interactive patchboard")
	s.advance(10)
	t.check(s.elapsed == 0 and s.wave == 0, "wiring never auto-starts or advances gameplay")
	t.check(s.patchboard.rewire(s, 0, &"feedback_loop"), "ready recipe connects")
	t.check(not s.patchboard.rewire(s, 1, &"feedback_loop"), "duplicate recipe rejected")
	t.check(not s.patchboard.rewire(s, 1, &"ball_lightning"), "missing Well blocks Ball Lightning")
	s.draft.equip(&"reverb_well")
	t.check(s.patchboard.rewire(s, 1, &"ball_lightning"), "two connections can share Arc endpoint")
	t.check(not s.patchboard.rewire(s, 2, &"live_wire"), "third slot rejected")
	t.check(s.draft.support_count() == 2, "patchboard does not consume support slots")
	s.draft.equip(&"needle_swarm")
	t.check(not PatchboardState.eligible(s, &"needle_thread"), "Marking Pins capability required beyond equipment")
	s.patchboard.cooldowns.feedback_loop = 12
	s.patchboard.rewire(s, 0, &"")
	s.patchboard.rewire(s, 0, &"feedback_loop")
	t.check(s.patchboard.cooldowns.feedback_loop == 12, "rewiring cannot reset an internal cooldown")
	t.check(s.launch_wave() and not s.is_wiring(), "Go live releases intermission hold")
	s.advance(2.1)
	t.check(not s.patchboard.rewire(s, 0, &""), "combat rewiring rejected")
	s.phase = CombatSession.Phase.DRAFT
	t.check(not s.patchboard.rewire(s, 0, &""), "mid-wave Signal upgrade cannot rewire")

func _contracts(t: TestContext) -> void:
	var drop: CombatSession = fixture(&"double_drop")
	for index: int in 2: deploy(drop, &"bass_driver", drop.actors[0].position)
	t.check(drop.patchboard.totals.double_drop.triggers == 0 and drop.patchboard.counters.double_drop == 2, "Double Drop waits for the third direct Bass activation")
	deploy(drop, &"bass_driver", drop.actors[0].position)
	for index: int in 100: drop.damage_actor(drop.actors[0], 1, &"double_drop", 1)
	t.check(drop.patchboard.totals.double_drop.triggers == 1 and drop.patchboard.counters.double_drop == 0, "generated repeats never increment their own trigger counter")
	var pressure: CombatSession = fixture(&"pressure_drop")
	var pressure_hits: Array[int] = []
	pressure.combat_event.connect(func(e: CombatEvent) -> void:
		if e.source_id == &"pressure_drop" and e.kind == CombatEvent.Kind.DAMAGE: pressure_hits.append(e.target_id))
	exercise(pressure, &"pressure_drop")
	t.check(pressure_hits.size() > 0 and pressure_hits.size() <= 6 and SaveChecks.unique(pressure_hits), "overlapping wells count each grouped target once per Bass activation")
	var ball: CombatSession = fixture(&"ball_lightning")
	var actor: CombatActor = ball.actors[0]
	for index: int in 20: ball.patchboard.arc_hit(ball, actor, 1)
	t.check(ball.patchboard.counters.ball_lightning == 0, "untrapped/uncharged hits cannot advance Ball Lightning")
	exercise(ball, &"ball_lightning")
	var count: float = ball.patchboard.totals.ball_lightning.triggers
	for index: int in 1000: ball.patchboard.arc_hit(ball, actor, 1)
	t.check(ball.patchboard.totals.ball_lightning.triggers == count, "Ball Lightning has shared cooldown under proc storm")
	var net: CombatSession = fixture(&"live_wire")
	var net_events: Array[CombatEvent] = []
	net.combat_event.connect(func(e: CombatEvent) -> void: net_events.append(e))
	exercise(net, &"live_wire")
	for index: int in 100: net.arsenal._tick_zones(net, .01)
	t.check(net.patchboard.totals.live_wire.triggers == 1, "rapid Net ticks respect one-second charge rate")
	t.check(net.actors.all(func(a: CombatActor) -> bool: return a.status.charged <= 3), "Charged remains capped")
	t.check(not net_events.any(func(e: CombatEvent) -> bool: return e.source_id == &"arc_aerial"), "Live Wire creates no synthetic Arc attacks")
	var dead: CombatSession = fixture(&"dead_zone")
	var elite: CombatActor = dead.spawn_enemy(M4Content.enemy(&"m4.elite"), 240)
	elite.position.y = 420
	elite.status.apply_slow(.3, true)
	dead.patchboard.bass_pulse(dead, [elite], 1)
	t.check(elite.status.jam_left <= .2 and elite.status.fallback_left > 0, "elite interruption is capped and resistance retains slowdown")
	elite.status.advance(.5)
	dead.patchboard.advance(.5)
	dead.patchboard.bass_pulse(dead, [elite], 1)
	t.check(elite.status.jam_left == 0 and elite.status.ability_rate() == .8, "elite cannot be permanently jammed; fallback slows ability")
	var feedback: CombatSession = fixture(&"feedback_loop")
	exercise(feedback, &"feedback_loop")
	var after: float = feedback.run.shield.current
	for index: int in 50: feedback.patchboard.shield_break(feedback, 1)
	t.check(after == 0 and feedback.run.shield.current == 0, "retaliation never heals originating shield")
	t.check(feedback.patchboard.totals.feedback_loop.triggers == 1, "shield-break feedback terminates at long cooldown")
	for chassis: String in ArsenalContent.MAINS:
		var b: CombatSession = fixture(&"b_side", true, chassis)
		var damaged: Array[int] = []
		b.combat_event.connect(func(e: CombatEvent) -> void:
			if e.kind == CombatEvent.Kind.DAMAGE and e.source_id == &"echo_deck": damaged.append(e.target_id))
		exercise(b, &"b_side")
		t.check(not damaged.is_empty() and damaged[0] == b.actors[3].serial, chassis + " B-Side replay adapts to a marked target")
		var threaded: CombatSession = fixture(&"needle_thread", true, chassis)
		var ordinary: CombatSession = fixture(&"needle_thread", false, chassis)
		# Align enemies so precision's additional penetration has a valid second target.
		for state: CombatSession in [threaded, ordinary]:
			for index: int in state.actors.size(): state.actors[index].position = Vector2(320, 400 - index * 20)
		exercise(threaded, &"needle_thread")
		exercise(ordinary, &"needle_thread")
		t.check(threaded.arsenal.report.totals.main.damage > ordinary.arsenal.report.totals.main.damage, chassis + " Needle Thread uses a compatible gameplay benefit")
		var p: Dictionary = ArsenalStats.parameters(threaded.draft.track(&"main"))
		t.check(p == ArsenalStats.parameters(ordinary.draft.track(&"main")), "connection benefit never mutates base track or recorded packet")
	# Repeated old listeners cannot survive because there are no recipe subscriptions.
	var s: CombatSession = fixture(&"live_wire")
	var listeners: int = s.combat_event.get_connections().size()
	s.phase = CombatSession.Phase.INTERMISSION
	s.patchboard.awaiting = true
	for index: int in 100:
		s.patchboard.rewire(s, 0, &"")
		s.patchboard.rewire(s, 0, &"live_wire")
	t.check(s.combat_event.get_connections().size() == listeners, "100 rewires leave no added event listeners")
	s.patchboard.rewire(s, 0, &"")
	s.phase = CombatSession.Phase.COMBAT
	exercise(s, &"live_wire")
	t.check(s.patchboard.totals.live_wire.triggers == 0, "removed connection cannot trigger from existing fields")

func _saves(t: TestContext) -> void:
	var s: CombatSession = CombatSession.new()
	s.start_patchboard(8, &"run.1")
	s.patchboard.rewire(s, 0, &"feedback_loop")
	var data: Dictionary = JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))
	var restored: CombatSession = CombatSession.new()
	t.check(restored.restore_checkpoint(data) and restored.is_wiring(), "JSON recovery preserves initial wiring screen and selected slots")
	for bad: Variant in [["feedback_loop", "feedback_loop"], ["feedback_loop", "ball_lightning"], ["unknown", ""], ["", "", ""]]:
		var corrupt: Dictionary = data.duplicate(true)
		corrupt.patchboard.slots = bad
		t.check(not CombatSession.new().restore_checkpoint(corrupt), "malformed or ineligible saved connection rejected")
	var corrupt: Dictionary = data.duplicate(true)
	corrupt.patchboard.cooldowns.feedback_loop = 999
	t.check(not CombatSession.new().restore_checkpoint(corrupt), "out-of-range saved cooldown rejected")
	var profile: MissionProfile = MissionProfile.new()
	var old: Dictionary = profile.to_data()
	old.erase("discovered")
	old.erase("campaign")
	old.erase("achievements")
	old.schema = 1
	t.check(profile.restore(old) and profile.discovered.is_empty(), "schema-1 profile migrates with no invented discoveries")
	profile.discovered.append(&"feedback_loop")
	t.check(MissionProfile.new().restore(JSON.parse_string(JSON.stringify(profile.to_data()))), "schema-3 discoveries survive JSON numeric schema conversion")
	s.start_patchboard(9, &"run.2")
	t.check(s.patchboard.slots == [&"", &""] and s.patchboard.discovered().is_empty(), "new run clears all connections, counters and contributions")
	var legacy: CombatSession = CombatSession.new()
	legacy.start_arsenal(8, &"run.1")
	t.check(restored.restore_checkpoint(legacy.to_checkpoint()) and restored.patchboard == null, "M5 Continue retains original timed intermissions")

func _live_mission(t: TestContext) -> void:
	var s: CombatSession = CombatSession.new()
	s.start_patchboard(1, &"run.1")
	var checkpoints: int = 0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 35
	for tick: int in 9000:
		if s.is_finished(): break
		if s.is_wiring():
			if s.patchboard.slots[0] == &"": s.patchboard.rewire(s, 0, &"feedback_loop")
			for id: StringName in PatchboardContent.RECIPES:
				if id not in s.patchboard.slots and PatchboardState.eligible(s, id):
					s.patchboard.rewire(s, 1, id)
					break
		if s.is_wiring() or s.is_deciding():
			var data: Dictionary = JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))
			var copy: CombatSession = CombatSession.new()
			var valid: bool = copy.restore_checkpoint(data)
			t.check(valid, "live M6 wiring/upgrade checkpoint validates actors, effects, RNG, contributions")
			if not valid: return
			t.check(M5.new().close(s.to_checkpoint(), copy.to_checkpoint()), "live M6 checkpoint reconstructs identically")
			checkpoints += 1
			if s.is_wiring(): s.launch_wave()
			else: s.choose_upgrade(s.draft.offers[rng.randi_range(0, s.draft.offers.size() - 1)])
		else:
			AIM.aim(s)
			s.advance(.1)
	t.check(s.is_finished() and checkpoints > 10, "M6 live mission reaches results through real decisions and intermissions")
