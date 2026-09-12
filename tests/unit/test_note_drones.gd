extends RefCounted
const FIXTURE: Script = preload("res://tests/unit/test_arsenal.gd")

func run(t: TestContext, tree: SceneTree) -> bool:
	var s: CombatSession = FIXTURE.new().fixture("pulse", "capacitor", "needle_swarm")
	var actor: CombatActor = s.actors[0]
	s.actors = [actor]; actor.armor = 0
	var p: Dictionary = ArsenalStats.parameters(s.draft.track(&"needle_swarm"))
	p.projectiles = 1
	var root: int = s.arsenal._root(s, &"needle_swarm", actor.serial)
	var hits: Array[CombatEvent] = []
	s.combat_event.connect(func(e: CombatEvent) -> void:
		if e.kind == CombatEvent.Kind.DAMAGE: hits.append(e))
	s.arsenal._needles(s, actor, p, root)
	s.arsenal._tick_needles(s, .05)
	t.check(hits.is_empty() and not s.arsenal.needles[0].orbiting, "notes fly to a target before firing")
	for tick: int in 30:
		s.arsenal._tick_needles(s, .025)
		if not hits.is_empty(): break
	t.check(hits.size() == 1 and s.arsenal.needles[0].orbiting, "arrived drone orbits and fires at its assigned enemy")
	var n: Dictionary = s.arsenal.needles[0]
	t.check(absf(Vector2(n.x,n.y).distance_to(actor.position) - actor.radius - 22) < 5, "note stays on an orbit near its target")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(s.arsenal.to_data(), "", true, true))
	t.check(ArsenalRuntime.valid(saved), "active drone state validates after JSON round trip")
	var restored: CombatSession = FIXTURE.new().fixture("pulse", "capacitor", "needle_swarm")
	var twin: CombatActor = restored.actors[0]; restored.actors = [twin]
	twin.health = actor.health; twin.armor = 0
	t.check(restored.arsenal.restore(saved), "orbit angle, remaining shots and firing delay restore")
	for tick: int in 100:
		s.arsenal._tick_needles(s, .025); restored.arsenal._tick_needles(restored, .025)
	t.check(hits.size() == 3 and s.arsenal.needles.is_empty(), "base drone fires exactly three hits then despawns")
	t.check(is_equal_approx(actor.health,twin.health) and s.arsenal.to_data() == restored.arsenal.to_data(), "restored drone delivers identical remaining damage and expires identically")
	t.check(hits.all(func(e: CombatEvent) -> bool: return e.source_id == &"needle_swarm" and e.root_attack_id == root and not (e.eligible_triggers & CombatEvent.CAN_ECHO)), "drone shots retain source and root without creating echo chains")
	var legacy: Dictionary = saved.duplicate(true)
	for key: String in ["angle","wait","remaining","orbiting"]: legacy.needles[0].erase(key)
	t.check(ArsenalRuntime.valid(legacy) and restored.arsenal.restore(legacy) and ArsenalRuntime.valid(restored.arsenal.to_data()), "older traveling-note saves migrate to finite drones")
	var bad: Dictionary = saved.duplicate(true); bad.needles[0].remaining = 99
	t.check(not ArsenalRuntime.valid(bad), "unbounded shot counts are rejected")
	bad = saved.duplicate(true); bad.needles[0].angle = "bad"
	t.check(not ArsenalRuntime.valid(bad), "invalid orbit data is rejected")
	s.arsenal._needles(s, actor, p, root)
	var before: Dictionary = s.arsenal.to_data()
	s.paused = true; s.arsenal._tick_needles(s, 2)
	t.check(before == s.arsenal.to_data(), "paused drones do not move or fire")
	s.paused = false; s.phase = CombatSession.Phase.DRAFT; s.arsenal._tick_needles(s, 2)
	t.check(before == s.arsenal.to_data(), "upgrade choices freeze drones")
	s.phase = CombatSession.Phase.COMBAT
	actor.resolved = true
	var next: CombatActor = s.spawn_enemy(CombatContent.CARRIER,320); next.position.y = 450; next.health = 1000
	s.arsenal._tick_needles(s,.05)
	t.check(s.arsenal.needles[0].target == next.serial, "drone seeks a nearby replacement when its target dies")
	next.resolved = true; s.arsenal._tick_needles(s,.05)
	t.check(s.arsenal.needles.is_empty(), "orphan drones despawn when no valid target remains")
	var pursuit: CombatSession = FIXTURE.new().fixture("pulse", "capacitor", "needle_swarm")
	var large: CombatActor = pursuit.actors[0]; pursuit.actors = [large]
	large.position = Vector2(320,560); large.radius = 70
	var slow_note: Dictionary = p.duplicate(true); slow_note.speed = 100; slow_note.steering = 20
	pursuit.arsenal._needles(pursuit,large,slow_note,1)
	for tick: int in 120:
		large.position.x += .1
		pursuit.arsenal._tick_needles(pursuit,.025)
	t.check(pursuit.arsenal.report.totals.needle_swarm.damage > 0, "slow traveling notes acquire large moving enemies even with fast orbit upgrades")
	var prefs: RadioPreferences = RadioPreferences.current
	var seen: Array = prefs.coach_seen.duplicate()
	prefs.remember_coach("mixer")
	var campaign: CombatSession = CombatSession.new()
	campaign.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	campaign.elapsed = 12; campaign.phase = CombatSession.Phase.COMBAT
	var coach: CombatCoach = CombatCoach.new(); tree.root.add_child(coach)
	coach.refresh(campaign)
	t.check(coach.visible and coach.current_hint == "mixer" and coach.caption.text.contains("Mixer"), "each run reminds existing players to use the Mixer")
	coach._process(11); coach.refresh(campaign)
	t.check(not coach.visible, "Mixer reminder expires without occupying the combat screen indefinitely")
	prefs.coach_seen.assign(seen); prefs.save_preferences()
	coach.queue_free(); await tree.process_frame
	return true
