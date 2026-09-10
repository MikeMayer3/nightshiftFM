extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var t: TestContext = TestContext.new()
	var rows: Array[Dictionary] = []
	for mission: int in range(1,5):
		for seed_value: int in [42,73]:
			var s: CombatSession = CombatSession.new()
			s.start_campaign(seed_value,&"run.1",ArsenalContent.DEFAULT,{"mission":mission,"cleared":mission-1,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
			var b: RadioBroadcast = RadioBroadcast.new(); b.attach(s)
			var events: Array[Dictionary] = []
			var record: Callable = func(kind: String) -> void: events.append({"key":b.key,"kind":kind,"wave":s.wave,"seconds":s.elapsed,"spawn_index":s.spawn_index})
			b.cue_started.connect(record)
			var choices: int = 0
			for frame: int in 15000:
				if s.is_finished(): break
				if s.is_wiring(): s.launch_wave()
				if s.is_deciding():
					var id: StringName = s.draft.offers[0]
					for offer: StringName in s.draft.offers:
						if SignalDraft.is_new(offer): id = offer; break
					t.check(s.choose_upgrade(id), "legal offered upgrade accepted")
					choices += 1
				if s.ability_wait <= 0 and s.run.shield.current < 30: s.activate_shield()
				s.advance(.1); b.update(s)
				if frame % 100 == 0:
					var before: Dictionary = s.to_checkpoint(); b.update(s)
					t.check(s.to_checkpoint() == before, "live broadcast refresh preserves checkpoint")
			t.check(s.is_finished(), "full authored campaign reaches real result")
			t.check(events.size() <= (5 if mission == 4 else 3), "bounded authored cue count per complete run")
			var unique: Dictionary = {}
			for event: Dictionary in events: unique[event.key] = true
			t.check(unique.size() == events.size(), "no duplicate broadcast in complete run")
			b.cue_started.disconnect(record)
			rows.append({"mission":mission,"seed":seed_value,"wave":s.wave,"victory":s.phase == CombatSession.Phase.VICTORY,"seconds":s.elapsed,"choices":choices,"broadcasts":events})
	FileAccess.open("res://docs/evidence/P4-radio/runs.json",FileAccess.WRITE).store_string(JSON.stringify({"runs":rows,"checks":t.checks,"failures":t.failures},"\t"))
	print("RESULT: %d full-run checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)
