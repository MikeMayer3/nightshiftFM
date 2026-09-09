extends RefCounted
func make(mode: String = "campaign", mission: int = 4, contract: String = "", difficulty: int = 0) -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, {"mission": mission, "cleared": 12, "modules": [], "mode": mode, "difficulty": difficulty, "contract": contract})
	s.launch_wave()
	return s
func roundtrip(s: CombatSession) -> bool:
	var copy: CombatSession = CombatSession.new()
	return copy.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true)))
func run(t: TestContext) -> bool:
	var definitions: Array[ContentDefinition] = [CombatContent.SWARMER, CombatContent.DIVER, CombatContent.CARRIER]
	definitions.append_array(EncounterContent.ELITES)
	definitions.append_array(BroadcastContent.ENEMIES)
	for mission: int in range(1, 13):
		var waves: Array = BroadcastWaves.MISSIONS[mission]
		definitions.append(CampaignContent.MISSIONS[mission - 1])
		t.check(waves.size() == 10 and not CampaignContent.MISSIONS[mission - 1].prototype, "expanded mission %d has ten authored waves" % mission)
		var seen: Array[StringName] = []
		for wave: int in 10:
			var definition: WaveDefinition = waves[wave]
			definitions.append(definition)
			t.check(definition.enemy_ids.size() <= 80 and definition.enemy_ids.size() > 0, "bounded mission %d wave %d" % [mission, wave + 1])
			for id: StringName in definition.enemy_ids:
				if wave == 9: t.check(id in seen, "finale enemy was introduced: " + String(id))
			if wave < 9: seen.append_array(definition.enemy_ids)
		t.check(roundtrip(make("campaign", mission)), "expanded mission %d JSON start" % mission)
	t.check(ContentValidator.validate(definitions).is_empty(), "all expanded content references resolve")
	for contract: String in BroadcastRules.CONTRACTS:
		var s: CombatSession = make("contract", 1, contract)
		t.check(roundtrip(s), "contract start and restricted loadout restore: " + contract)
		if contract == "bare_antenna": t.check(s.draft.support_count() == 0 and not s.draft.equip(&"arc_aerial"), "bare antenna has no starter or recruitment support")
		if contract == "two_channel":
			s.draft.equip(&"bass_driver")
			t.check(not s.draft.equip(&"static_net"), "two-channel cap enforced independently of UI")
		if contract == "fragile_broadcast": t.check(is_equal_approx(s.maximum_hull(), 55) and s.run.shield.capacity == 65, "fragile contract changes Station Health but not shield")
	var normal: CombatSession = make()
	var hard: CombatSession = make("campaign", 4, "", 1)
	normal.advance(2.1); hard.advance(2.1)
	t.check(hard.actors[0].max_health > normal.actors[0].max_health and roundtrip(hard), "Hard overrides reach real actors and survive saves")
	var core: CombatSession = make("campaign", 8)
	core.phase = CombatSession.Phase.COMBAT; core.wave = 8
	var boss: CombatActor = core.spawn_enemy(BroadcastContent.enemy(&"m8.core"), 320)
	EncounterDirector.prepare(core, boss)
	t.check(EncounterDirector.satellites(core, boss).size() == 2 and core.target().role == EnemyDefinition.Role.AERIAL, "core spawns two ordinary-targetable weak points")
	for part: CombatActor in EncounterDirector.satellites(core, boss): core.damage_actor(part, 10000)
	t.check(EncounterDirector.exposed(core, boss) and EncounterDirector.protection(core, boss) == 1, "destroying both satellites exposes core")
	var jam: CombatActor = core.spawn_enemy(BroadcastContent.enemy(&"m8.jammer"), 180)
	jam.ability_time = jam.ability_interval - .5
	t.check(EncounterDirector.jammed_support(core) == &"arc_aerial", "jam channels against one support")
	jam.status.jam(1, false, false)
	t.check(EncounterDirector.jammed_support(core) == &"", "interrupt breaks an enemy mute channel")
	var mortar: CombatActor = core.spawn_enemy(BroadcastContent.enemy(&"m8.mortar"), 100)
	mortar.position.y = 180; mortar.advance(1)
	t.check(mortar.position.y == 180, "mortar holds its firing position")
	EncounterDirector.ability(core, mortar)
	t.check(core.actors.any(func(a: CombatActor) -> bool: return a.projectile), "mortar emits destructible packets")
	var endless: CombatSession = make("endless", 1)
	t.check(BroadcastDraft.endless_credits(10) == 34 and BroadcastDraft.endless_credits(16) == 42, "Endless schedule includes three early drafts and bounded recruitment windows")
	endless.phase = CombatSession.Phase.INTERMISSION
	endless.patchboard.awaiting = true
	endless.wave = 1
	endless.achievement_run.cleared_waves = 1
	endless.signal_progress.earned = BroadcastDraft.endless_credits(1)
	endless.spawn_index = endless.wave_definition().enemy_ids.size()
	endless.finish_endless()
	t.check(roundtrip(endless), "ending Endless from intermission clears wiring and restores results")
	var goals: AchievementProfile = AchievementProfile.new()
	endless.achievement_run.eligible = true
	endless.achievement_run.reflected = 3
	goals.record_waves(endless); goals.record_waves(endless)
	t.check(goals.count(&"bouncer") == 3, "repeated wave commits never duplicate reflected projectile progress")
	endless.achievement_run.reflected = 2
	goals.record_waves(endless)
	t.check(goals.count(&"bouncer") == 3, "rollback cannot subtract or replay committed reflection progress")
	var native: Dictionary = goals.to_data()
	t.check(AchievementProfile.new().restore(native) and AchievementProfile.new().restore(JSON.parse_string(JSON.stringify(native))), "expanded achievement watermarks survive native and JSON migration")

	for mission: int in [4, 8, 12]:
		for contract: String in ["long_distance", "overcrowded_frequency"]:
			var context: CampaignRun = make("contract", mission, contract).campaign
			for wave: int in [8, 10]:
				var source: WaveDefinition = BroadcastWaves.MISSIONS[mission][wave - 1]
				for id: StringName in source.enemy_ids:
					if BroadcastContent.enemy(id).role >= EnemyDefinition.Role.CALLER:
						t.check(id in BroadcastRules.wave_for(context, wave).enemy_ids, "contract preserves authored boss: " + contract)
	var relay: CombatSession = CombatSession.new()
	relay.start_campaign(42, &"run.1", {"main": "pulse", "shield": "relay", "support": "arc_aerial"}, normal.campaign.to_data())
	relay.launch_wave()
	relay.phase = CombatSession.Phase.COMBAT
	relay.activate_shield()
	for serial: int in range(1, 4): relay.hit_station(1, &"COMBAT_SWARMER", &"COMBAT_BREACH_HIT", &"m2.swarmer", serial, serial)
	t.check(relay.achievement_run.best_activation == 0, "passive mitigation during Relay activation cannot earn Hold the Line")
	var capacitor: CombatSession = make()
	capacitor.phase = CombatSession.Phase.COMBAT
	capacitor.activate_shield()
	for serial: int in range(1, 4): capacitor.hit_station(1, &"COMBAT_SWARMER", &"COMBAT_BREACH_HIT", &"m2.swarmer", serial, serial)
	t.check(capacitor.achievement_run.best_activation == 3, "three distinct hits absorbed by temporary Capacitor reserve count")
	return true
