extends RefCounted
func make(cleared: int = 0, main: String = "pulse", support: String = "arc_aerial") -> CombatSession:
	var s: CombatSession = CombatSession.new()
	var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
	loadout.main = main
	loadout.support = support
	s.start_campaign(42, &"run.1", loadout, {"mission": 1, "cleared": cleared, "modules": [], "mode": "campaign", "difficulty": 0, "contract": ""})
	return s

func run(t: TestContext) -> bool:
	for cleared: int in [0, 3, 4, 11, 12]:
		var s: CombatSession = make(cleared)
		var mix: MixerState = s.patchboard.mixer
		var budget: int = MixerState.budget(cleared)
		t.check(budget == (3 if cleared < 4 else 5 if cleared < 12 else 7), "point budget follows actual difficulty unlocks")
		t.check(not s.is_wiring(), "new broadcasts do not force the connection tutorial")
		t.check(not mix.adjust(s, 0, 1), "mix changes require frozen simulation")
		s.paused = true
		t.check(mix.adjust(s, 0, mini(4, budget)), "spend available points")
		t.check(not mix.adjust(s, 0, 5), "per-fader cap enforced")
		t.check(mix.adjust(s, 1, budget - mix.spent()), "remaining points can go to area")
		var before: Array[int] = mix.levels.duplicate()
		t.check(not mix.adjust(s, 2, 1) and mix.levels == before, "over-budget adjustment rejected atomically")
		t.check(not mix.adjust(s, -1, 0) and not mix.adjust(s, 3, 0) and not mix.adjust(s, 0, -1), "invalid fader and negative point rejected")
		t.check(mix.adjust(s, 0, before[0] - 1) and mix.adjust(s, 2, 1), "lowering a fader refunds a point")
		for json: bool in [false, true]:
			var saved: Dictionary = s.to_checkpoint()
			if json: saved = JSON.parse_string(JSON.stringify(saved, "", true, true))
			var restored: CombatSession = CombatSession.new()
			t.check(restored.restore_checkpoint(saved), "native and JSON mixer checkpoint accepted")
			t.check(restored.patchboard.mixer.levels == mix.levels and restored.draft.track(&"main").mixer == restored.patchboard.mixer, "restored stats share only this run's mixer")
		for bad: Variant in [[4, 4, 4], [1.5, 0, 0], [true, 0, 0], [-1, 0, 0], [0, 0], [0, 0, "1"], [NAN, 0, 0]]:
			var broken: Dictionary = s.to_checkpoint()
			broken.patchboard.mixer.levels = bad
			t.check(not CombatSession.new().restore_checkpoint(broken), "malformed mixer allocation rejected")
		var legacy: Dictionary = s.to_checkpoint()
		legacy.patchboard.erase("mixer")
		var migrated: CombatSession = CombatSession.new()
		t.check(migrated.restore_checkpoint(legacy) and migrated.patchboard.mixer.spent() == 0, "old broadcast checkpoint gains a neutral mixer")
	var direct: CombatSession = make()
	var baseline: Dictionary = ArsenalStats.parameters(direct.draft.track(&"main"))
	direct.paused = true
	direct.patchboard.mixer.adjust(direct, 0, 3)
	t.check(is_equal_approx(ArsenalStats.parameters(direct.draft.track(&"main")).damage, baseline.damage * 1.3), "three Direct points increase real shot damage by thirty percent")
	t.check(is_equal_approx(ArsenalStats.parameters(make().draft.track(&"main")).damage, baseline.damage), "mixer cannot mutate another run or content resources")
	direct.paused = false
	direct.auto_fire = false
	direct.advance(2.1)
	var victim: CombatActor = direct.actors[0]
	victim.position = Vector2(320, 300)
	victim.health = 100
	direct.arsenal.fire_main(direct, victim)
	t.check(is_equal_approx(100 - victim.health, baseline.damage * 1.3), "boost reaches actual enemy health")
	var area: CombatSession = make(12, "sweep", "static_net")
	area.paused = true
	area.apply_ranks()
	var net: UpgradeTrack = area.draft.track(&"static_net")
	var base_net: Dictionary = ArsenalStats.parameters(net)
	area.patchboard.mixer.adjust(area, 1, 4)
	area.patchboard.mixer.adjust(area, 2, 3)
	var p: Dictionary = ArsenalStats.parameters(net)
	t.check(is_equal_approx(p.damage, base_net.damage * 1.32) and is_equal_approx(p.radius, base_net.radius * 1.24), "AOE increases damage and field radius")
	t.check(is_equal_approx(p.slow, base_net.slow * 1.36), "Control strengthens existing slow")
	t.check(is_equal_approx(ArsenalStats.parameters(area.draft.track(&"main")).width, 18 * 1.24), "AOE widens sweep chassis")
	area.paused = false
	area.auto_fire = false
	area.advance(2.1)
	var target: CombatActor = area.actors[0]
	target.position = Vector2(320, 280)
	area.attack_serial += 1
	area.arsenal._deploy(area, target.position, &"static_net", p, area.attack_serial)
	var effects: Dictionary = area.arsenal.to_data().duplicate(true)
	var rng: Dictionary = area.random.to_data()
	var health: float = area.hull
	var shield: float = area.run.shield.current
	area.paused = true
	area.patchboard.mixer.adjust(area, 1, 0)
	area.patchboard.mixer.adjust(area, 0, 4)
	area.advance(60)
	t.check(area.arsenal.to_data() == effects and area.random.to_data() == rng, "respec freezes time and preserves existing fields, cooldowns and RNG")
	t.check(area.hull == health and area.run.shield.current == shield, "respec never repairs or refills the station")
	var restored: CombatSession = CombatSession.new()
	t.check(restored.restore_checkpoint(JSON.parse_string(JSON.stringify(area.to_checkpoint(), "", true, true))), "mid-wave respec with an old-mix field survives JSON restore")
	t.check(restored.arsenal.zones[0].p == JSON.parse_string(JSON.stringify(p)), "existing field retains captured mix after reload")
	area.phase = CombatSession.Phase.VICTORY
	t.check(not area.patchboard.mixer.adjust(area, 0, 0), "finished run cannot change mix")
	return true
