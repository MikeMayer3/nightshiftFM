extends RefCounted
func run(t: TestContext) -> bool:
	t.check(not BassPayoff.active(null), "absent session has no build payoff")
	var empty: CombatSession = CombatSession.new()
	t.check(not BassPayoff.active(empty), "absent equipment has no build payoff")
	for branch: StringName in [&"m5.bass_driver.b1", &"m5.bass_driver.b2", &"m5.bass_driver.b3"]:
		var s: CombatSession = CombatSession.new()
		s.start_arsenal(42, &"run.1", {"main":"pulse","shield":"capacitor","support":"bass_driver"})
		var track: UpgradeTrack = s.draft.track(&"bass_driver")
		t.check(not BassPayoff.active(s), "rank one uses original cabinet")
		t.check(track.accept(track.eligible([])[0].id, []), "legal rank two")
		t.check(not BassPayoff.active(s), "rank two retains original cabinet")
		t.check(track.accept(branch, []), "legal rank three branch")
		t.check(BassPayoff.active(s) == (branch == BassPayoff.BRANCH), "only Wideband fits twin cabinet")
		while track.rank() < 8: track.accept(track.eligible([])[0].id, [])
		t.check(BassPayoff.active(s) == (branch == BassPayoff.BRANCH), "later ranks retain correct branch presentation")
	var fixtures: Dictionary = preload("res://tests/p5_fixture.gd").prepare()
	t.check(not fixtures.is_empty(), "real offered campaign choices reach Wideband")
	if fixtures.is_empty(): return false
	for key: String in ["before", "decision", "after"]:
		var restored: CombatSession = CombatSession.new()
		t.check(restored.restore_checkpoint(JSON.parse_string(JSON.stringify(fixtures[key], "", true, true))), "legal JSON checkpoint restores " + key)
		t.check(BassPayoff.active(restored) == (key == "after"), "restored hardware follows actual accepted branch " + key)
		if key == "decision":
			t.check(restored.choose_upgrade(BassPayoff.BRANCH) and BassPayoff.active(restored), "pending decision equips payoff only after acceptance")
		if key == "after":
			var arena: CombatArena = CombatArena.new(); arena.session = restored
			arena.show_support(&"bass_driver", Vector2(320,300),Vector2(100,100))
			t.check(arena.pulses[-1].wideband, "actual support cue records branch at emission")
			restored.start_arsenal(42, &"run.2", ArsenalContent.DEFAULT)
			t.check(not BassPayoff.active(restored) and arena.pulses[-1].wideband, "fresh gear resets hardware without relabeling an already emitted pulse")
			arena.free()
	var observed: CombatSession = CombatSession.new()
	var control: CombatSession = CombatSession.new()
	observed.restore_checkpoint(fixtures.after); control.restore_checkpoint(fixtures.after)
	for step: int in 1500:
		for s: CombatSession in [observed,control]:
			if s.is_deciding(): s.choose_upgrade(preload("res://tests/p5_fixture.gd").choice(s))
			if s.is_wiring(): s.launch_wave()
			s.advance(CombatSession.STEP)
		BassPayoff.active(observed); BassPayoff.texture(observed)
	t.check(observed.to_checkpoint() == control.to_checkpoint(), "1500 matched steps preserve damage, actors, choices and RNG")
	return true
