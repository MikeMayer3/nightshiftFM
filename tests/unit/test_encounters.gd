extends RefCounted

func json_data(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value, "", true, true))

func start(mission: int) -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(11, &"run.1", ArsenalContent.DEFAULT, {"mission": mission, "cleared": 12, "modules": []})
	s.patchboard.awaiting = false
	return s

func run(t: TestContext) -> bool:
	t.check(EncounterContent.validate().is_empty(), "M8 content references, budgets, and finale introductions validate")
	for mission: int in range(1, 4):
		var s: CombatSession = start(mission)
		t.check(EncounterContent.authored(s), "new opening campaign run uses M8 encounters")
		for wave: int in range(1, 11):
			s.wave = wave
			var definition: WaveDefinition = s.wave_definition()
			t.check(definition.id == CampaignContent.MISSIONS[mission - 1].wave_ids[wave - 1], "selected mission resolves its authored wave in order")
			var bounded: bool = true
			for group: int in 12:
				for member: int in definition.group_size:
					var x: float = EncounterContent.spawn_x(definition, group, member, 320)
					bounded = bounded and x >= CombatSession.SPAWN_BAND.position.x and x <= CombatSession.SPAWN_BAND.end.x
			t.check(bounded, "all formation groups stay inside top spawn band")
			s.phase = CombatSession.Phase.COMBAT
			s.spawn_index = 0
			s.spawn_time = 0
			s.actors.clear()
			s.auto_fire = false
			s.advance(CombatSession.STEP)
			t.check(s.spawn_index == definition.group_size, "runtime consumes exactly one authored group")
			t.check(s.actors.size() == definition.group_size, "runtime group has no hidden extra enemies")
			var copy: CombatSession = CombatSession.new()
			var checkpoint: Dictionary = json_data(s.to_checkpoint())
			t.check(copy.restore_checkpoint(checkpoint) and json_data(copy.to_checkpoint()) == checkpoint, "every authored wave restores actors and formation cursor exactly")
		# Pause must freeze formation cadence and elite timers.
		var before: Dictionary = json_data(s.to_checkpoint())
		s.paused = true
		s.advance(10)
		t.check(json_data(s.to_checkpoint()) == before, "M8 pause freezes encounter and actors")
		var legacy: CombatSession = start(mission)
		legacy.active_combat.content_version = CampaignContent.VERSION
		legacy.wave = 8
		legacy.phase = CombatSession.Phase.COMBAT
		legacy.advance(.2)
		var data: Dictionary = json_data(legacy.to_checkpoint())
		var resumed: CombatSession = CombatSession.new()
		t.check(resumed.restore_checkpoint(data) and not EncounterContent.authored(resumed) and resumed.wave_definition() == ActiveContent.FIRST_ELITES, "M7 continuation retains original wave 8 and content rules")
		resumed.advance(.5)
		legacy.advance(.5)
		t.check(json_data(resumed.to_checkpoint()) == json_data(legacy.to_checkpoint()), "legacy continuation preserves deterministic future state")
	for mission: int in range(4, 13):
		t.check(not EncounterContent.authored(start(mission)), "unfinished mission keeps labeled prototype rules")
	var elite: CombatSession = start(2)
	elite.phase = CombatSession.Phase.COMBAT
	elite.wave = 6
	elite.spawn_index = elite.wave_definition().enemy_ids.size()
	elite.auto_fire = false
	var carrier: CombatActor = elite.spawn_enemy(EncounterContent.ELITES[1], 320)
	var bolt: CombatActor = elite.spawn_projectile(carrier)
	carrier.projectiles_fired = 1
	elite.last_cause = carrier.name_key
	var saved: Dictionary = json_data(elite.to_checkpoint())
	var restored: CombatSession = CombatSession.new()
	t.check(restored.restore_checkpoint(saved) and restored.actors[1].source_id == bolt.source_id, "elite source attribution and projectile survive checkpoint")
	saved.content = CampaignContent.VERSION
	t.check(not CombatSession.new().restore_checkpoint(saved), "legacy content cannot load new enemy identities")
	var invalid: WaveDefinition = WaveDefinition.new()
	invalid.group_size = 6
	t.check(not invalid.validate().is_empty(), "oversized formation definition is rejected")
	# Carrier production remains bounded even when its timer crosses many intervals.
	for step: int in 24: elite.advance(.5)
	t.check(carrier.children_spawned <= 3 and carrier.projectiles_fired <= 3, "elite carrier cannot produce unbounded adds or bolts")
	return true
