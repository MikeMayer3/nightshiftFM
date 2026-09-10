extends RefCounted
func make() -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, {"mission": 1, "cleared": 12, "modules": ["long_mast"], "mode": "campaign", "difficulty": 0, "contract": ""})
	return s
func run(t: TestContext) -> bool:
	var s: CombatSession = make()
	s.advance(CombatSession.STEP)
	t.check(s.phase == CombatSession.Phase.COMBAT and s.wave == 1, "radio starts on next fixed step without countdown")
	s.advance(CombatSession.STEP)
	t.check(s.actors.size() > 0 and s.actors.all(func(a: CombatActor) -> bool: return a.position.y + a.radius * 1.7 < 0), "whole enemy silhouettes initially spawn off screen")
	var copy: CombatSession = CombatSession.new()
	t.check(copy.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))), "negative entry positions survive JSON Continue")
	t.check(JSON.parse_string(JSON.stringify(SignalSnapshot.capture(copy), "", true, true)) == JSON.parse_string(JSON.stringify(SignalSnapshot.capture(s), "", true, true)), "entry checkpoint preserves actors and RNG exactly")
	var bad: Dictionary = s.to_checkpoint().duplicate(true)
	bad.actors[0].position[1] = -10000
	t.check(not CombatSession.new().restore_checkpoint(bad), "save still rejects unbounded offscreen positions")
	var actor: CombatActor = s.actors[0]
	actor.position = Vector2(320, 60)
	var health: float = actor.health
	for id: StringName in [&"main", &"arc_aerial", &"bass_driver", &"static_net", &"needle_swarm", &"echo_deck", &"reverb_well", &"shield", &"live_wire"]:
		s.damage_actor(actor, 10000, id)
		t.check(actor.health == health and s.target(id) == null, "entry strip rejects " + String(id))
	t.check(ArsenalCombat.nearby(s, actor.position, 1000, 12).is_empty(), "splash and retarget queries exclude approach actors")
	t.check(PatchboardState.enemies(s, actor.position, 1000, 12).is_empty(), "generated connection effects exclude approach actors")
	for chassis: String in ["pulse", "sweep", "burst"]:
		var gun: CombatSession = make()
		gun.start_campaign(42, &"run.1", {"main": chassis, "shield": "capacitor", "support": "arc_aerial"}, gun.campaign.to_data())
		gun.phase = CombatSession.Phase.COMBAT; gun.wave = 1
		var target: CombatActor = gun.spawn_enemy(CombatContent.CARRIER, 320)
		target.position.y = 60
		gun.arsenal.fire_main(gun, target)
		t.check(target.health == target.max_health and gun.arsenal.packets.is_empty(), chassis + " cannot fire into Incoming Signals")
		t.check(RadioBalance.reach(gun, &"main") <= RadioBalance.MAX_REACH, chassis + " range remains capped with Long Mast")
		target.position.y = 320
		gun.arsenal.fire_main(gun, target)
		t.check(target.health < target.max_health, chassis + " can reach the stationary-enemy firing line")
	# Exercise real chain/zone/echo paths beside the protected boundary.
	var edge: CombatSession = make()
	edge.phase = CombatSession.Phase.COMBAT; edge.wave = 1
	for id: StringName in [&"arc_aerial", &"bass_driver", &"static_net", &"reverb_well", &"needle_swarm"]:
		if edge.draft.track(id) == null: edge.draft.equip(id)
	var hidden: CombatActor = edge.spawn_enemy(CombatContent.CARRIER, 320)
	hidden.position.y = 70
	var visible: CombatActor = edge.spawn_enemy(CombatContent.CARRIER, 320)
	visible.position.y = 280; visible.health = 10000
	edge.arsenal._arc(edge, visible, ArsenalStats.parameters(edge.draft.track(&"arc_aerial")), 1)
	t.check(hidden.health == hidden.max_health and hidden.status.charged == 0, "real chain cannot jump into entry or apply Charged there")
	for id: StringName in [&"bass_driver", &"static_net", &"reverb_well"]:
		var p: Dictionary = ArsenalStats.parameters(edge.draft.track(id))
		p.radius = 400
		edge.arsenal._deploy(edge, Vector2(320, 280), id, p, 2)
		edge.arsenal._tick_zones(edge, .1)
		t.check(hidden.health == hidden.max_health and hidden.position.y == 70 and hidden.status.slow == 0 and hidden.status.exposure == 0, String(id) + " cannot splash, slow or displace an incoming enemy")
	var packet: Dictionary = {"source": "echo_deck", "kind": "pulse", "root": 3, "target": hidden.serial, "x": 320, "y": 70, "left": 0.0, "p": ArsenalStats.parameters(edge.draft.track(&"main"))}
	packet.p.retarget = 1000; packet.p.copy_index = 0
	edge.arsenal._resolve_packet(edge, packet)
	t.check(hidden.health == hidden.max_health, "delayed echo retarget respects entry boundary")
	var needle: Dictionary = ArsenalStats.parameters(edge.draft.track(&"needle_swarm"))
	needle.speed = 1000; needle.steering = 0
	edge.arsenal._needles(edge, visible, needle, 4)
	edge.arsenal._tick_needles(edge, 1)
	t.check(hidden.health == hidden.max_health and edge.arsenal.needles.is_empty(), "traveling notes expire at the entry boundary")
	# Weak choices must remain dangerous; no firing is an unambiguous loss control.
	var idle: CombatSession = make()
	idle.auto_fire = false
	for tick: int in 2000:
		if idle.is_finished(): break
		idle.advance(.1)
	t.check(idle.phase == CombatSession.Phase.DEFEAT, "unopposed enemies cause real defeat")
	# Complete an empty wave and resume a legacy countdown checkpoint.
	var next: CombatSession = make()
	next.advance(CombatSession.STEP)
	next.spawn_index = next.wave_definition().enemy_ids.size()
	next.advance(CombatSession.STEP)
	t.check(next.phase == CombatSession.Phase.INTERMISSION and next.phase_time == 0, "cleared wave has no timed gap")
	next.phase_time = 2
	next.advance(CombatSession.STEP)
	t.check(next.wave == 2 and next.phase == CombatSession.Phase.COMBAT, "saved old countdown advances immediately")
	return true
