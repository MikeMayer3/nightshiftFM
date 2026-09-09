extends RefCounted
## Explicit synthetic eligibility fixtures, isolated from the player's profile.
func data(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value, "", true, true))

func session() -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(11, &"run.1", ArsenalContent.DEFAULT, {"mission": 1, "cleared": 12, "modules": []})
	s.patchboard.awaiting = false
	s.wave = 10
	s.phase = CombatSession.Phase.COMBAT
	return s

func capstone(s: CombatSession, family: StringName, branch: int = 1) -> void:
	if s.draft.track(family) == null: s.draft.equip(family)
	var owned: UpgradeTrack = s.draft.track(family)
	for _step: int in 7:
		if owned.rank() == 8: break
		var eligible: Array[UpgradeDefinition] = owned.eligible([])
		if eligible.is_empty(): return
		var pick: StringName = eligible[0].id
		var chassis: String = (s.draft as ArsenalDraft).loadout[String(family)] if family in [&"main", &"shield"] else String(family)
		if owned.rank() == 2: pick = StringName("m5.%s.b%d" % [chassis, branch])
		if not owned.accept(pick, []): return
	s.apply_ranks()

func fixture(id: StringName, positive: bool) -> AchievementProfile:
	if id not in preload("res://tests/unit/test_broadcast_achievements.gd").LEGACY and AchievementCatalog.ALL[id].category != "Weapon mastery": return preload("res://tests/unit/test_broadcast_achievements.gd").fixture(id, positive)
	var p: AchievementProfile = AchievementProfile.new()
	var s: CombatSession = session()
	s.achievement_run.eligible = true # Labeled evaluator fixture, never production provenance.
	var definition: AchievementDefinition = AchievementCatalog.ALL[id]
	if definition.category == "Weapon mastery":
		var family: StringName = definition.condition_parameters[&"family"]
		if definition.threshold == 3:
			p.include(String(family), "m5.%s.b1cap" % family)
			p.include(String(family), "m5.%s.b2cap" % family)
			if positive: capstone(s, family, 3)
		elif positive: capstone(s, family)
	else:
		match id:
			&"first_broadcast": s.achievement_run.eligible = positive
			&"patch_cable": s.patchboard.totals.live_wire.triggers = 1 if positive else 0
			&"sound_engineer":
				for recipe: StringName in PatchboardContent.RECIPES:
					if positive or recipe != &"live_wire": p.include("recipes", String(recipe))
			&"stereo":
				s.patchboard.slots = [&"live_wire", &"dead_zone"]
				s.patchboard.totals.live_wire.triggers = 10
				s.patchboard.totals.dead_zone.triggers = 10 if positive else 9
			&"minimalist": s.achievement_run.max_supports = 2 if positive else 3
			&"all_hands":
				for family: StringName in [&"bass_driver", &"static_net", &"echo_deck", &"needle_swarm"]: s.draft.equip(family)
				s.apply_ranks()
				for owned: UpgradeTrack in s.draft.tracks:
					if owned.definition.support: s.supports.report.add(owned.definition.id, &"slow_seconds", 1)
				if not positive: s.supports.report.totals.needle_swarm.slow_seconds = 0
			&"soloist_duet":
				capstone(s, &"arc_aerial")
				if positive: capstone(s, &"bass_driver")
			&"variety_show":
				for family: String in ArsenalContent.FAMILIES:
					if positive or family != "echo_deck": p.include("supports", family)
			&"deep_focus":
				capstone(s, &"main")
				if positive: capstone(s, &"shield")
			&"no_scratches": s.achievement_run.hull_damage = 0 if positive else 1
			&"unbroken": s.achievement_run.broken = not positive
			&"second_wind":
				s.achievement_run.broken = true
				s.achievement_run.recovered = positive
				if not positive: s.run.shield.current -= 1
			&"close_call": s.hull = 10 if positive else 10.01
	s._finish(true)
	p.record_victory(s)
	return p

func run(t: TestContext) -> bool:
	var available: int = 0
	var rewards: Array[StringName] = []
	t.check(AchievementCatalog.ALL.size() == 48, "all 48 approved achievement identities exist")
	for id: StringName in AchievementCatalog.ALL:
		var definition: AchievementDefinition = AchievementCatalog.ALL[id]
		t.check(definition.validate().is_empty() and definition.reward_id not in rewards, "valid unique cosmetic reward: " + String(id))
		rewards.append(definition.reward_id)
		if definition.available:
			available += 1
			t.check(fixture(id, true).earned(id), "positive evaluator fixture: " + String(id))
			t.check(not fixture(id, false).earned(id), "negative evaluator fixture: " + String(id))
		else:
			var p: AchievementProfile = AchievementProfile.new()
			t.check(not p.track(id) and not p.earned(id), "pending content cannot award or track: " + String(id))
			var corrupt: Dictionary = p.to_data()
			corrupt.progress[String(id)] = definition.threshold
			t.check(not p.restore(corrupt), "pending achievement cannot be injected by migration: " + String(id))
	t.check(available == 48, "all 48 conditions have positive and negative evaluator fixtures")
	_history(t)
	_profile(t)
	_report(t)
	t.check(not AchievementPlatform.new().available() and AchievementPlatform.new().submit(&"first_broadcast", 1) == ERR_UNAVAILABLE, "native adapter explicitly unavailable while local achievements work offline")
	return true

func _history(t: TestContext) -> void:
	var s: CombatSession = session()
	t.check(not s.achievement_run.eligible, "editor/debug campaign launch is ineligible by default")
	s.run.shield.current = 5
	s.hit_station(15, &"M2_SWARMER_NAME")
	var hull_loss: float = 100 - s.hull
	t.check(is_equal_approx(s.achievement_run.hull_damage, hull_loss) and hull_loss > 0 and hull_loss < 15 and s.achievement_run.broken, "shield-first hit records only hull overflow and a true break")
	s.hull = 100
	s.supports.heal(s, s.run.shield.capacity, &"shield")
	s.hit_station(1, &"M2_SWARMER_NAME")
	t.check(s.achievement_run.recovered and s.run.shield.current < s.run.shield.capacity and is_equal_approx(s.achievement_run.hull_damage, hull_loss), "full recovery survives a same-step follow-up hit; healing never erases hull damage")
	for _pick: int in 2:
		s.signal_progress.earned = s.signal_progress.spent + s.signal_progress.cost(s.signal_progress.choices)
		s.kills = s.signal_progress.earned
		s._open_signal_choice()
		for id: StringName in s.draft.offers:
			if SignalDraft.is_new(id):
				s.choose_upgrade(id)
				break
	var snapshot: Dictionary = data(s.to_checkpoint())
	var copy: CombatSession = CombatSession.new()
	t.check(copy.restore_checkpoint(snapshot) and data(copy.to_checkpoint()) == snapshot and copy.achievement_run.max_supports == 3, "checkpoint round-trip preserves peak support and damage history")
	s.hit_station(100, &"M2_SWARMER_NAME")
	t.check(copy.achievement_run != null and is_equal_approx(copy.achievement_run.hull_damage, hull_loss), "rollback restores history without counting discarded partial-wave damage")
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy.schema = 2
	legacy.erase("achievements")
	var old: CombatSession = CombatSession.new()
	t.check(old.restore_checkpoint(legacy) and old.achievement_run == null, "legacy run continues without inventing achievement history")
	var forged: Dictionary = snapshot.duplicate(true)
	forged.achievements.max_supports = 1
	t.check(not CombatSession.new().restore_checkpoint(forged), "peak support count cannot be lower than equipped inventory")
	forged = snapshot.duplicate(true)
	forged.achievements.hull_damage = -1
	t.check(not CombatSession.new().restore_checkpoint(forged), "negative damage history rejected")
	forged = snapshot.duplicate(true)
	forged.achievements.completed = true
	t.check(not CombatSession.new().restore_checkpoint(forged), "unfinished checkpoint cannot claim completed achievement provenance")
	var ended: CombatSession = session()
	ended.achievement_run.eligible = true
	ended._finish(false)
	var goals: AchievementProfile = AchievementProfile.new()
	goals.record_victory(ended)
	t.check(goals.progress.is_empty(), "defeat never awards victory achievements")
	ended.start_campaign(11, &"run.2", ArsenalContent.DEFAULT, {"mission": 4, "cleared": 12, "modules": []})
	ended.wave = 10
	ended.achievement_run.eligible = true
	ended._finish(true)
	goals.record_victory(ended)
	t.check(goals.progress.is_empty(), "prototype mission cannot qualify even with an eligible flag")

func _profile(t: TestContext) -> void:
	var p: MissionProfile = MissionProfile.new()
	var s: CombatSession = session()
	s.campaign.cleared = 0
	s.achievement_run.eligible = true
	s._finish(true)
	p.next_run = 2
	p.commit_reward(s.run_id, s)
	var before: Dictionary = data(p.to_data())
	p.commit_reward(s.run_id, s)
	t.check(p.achievements.earned(&"first_broadcast") and data(p.to_data()) == before, "achievement and cosmetic reward commit once with mission reward")
	t.check(p.achievements.select_title(&"first_broadcast") and not p.achievements.select_title(&"endless_60"), "only earned cosmetic titles may be equipped")
	for id: StringName in [&"sound_engineer", &"variety_show", &"arc_aerial_three_capstones"]: t.check(p.achievements.track(id), "track one of three distinct goals")
	t.check(not p.achievements.track(&"second_wind"), "fourth goal rejected")
	var restored: MissionProfile = MissionProfile.new()
	t.check(restored.restore(data(p.to_data())) and data(restored.to_data()) == data(p.to_data()), "earned progress, rewards, title and tracked goals survive provided-save migration")
	var store: MissionStore = MissionStore.new("user://m9_unit_achievements.json")
	t.check(store.save(p, s.to_checkpoint()) == OK and MissionStore.valid(store.load_save()), "atomic envelope persists run and achievement rewards together")
	for schema: int in [1, 2, 3]:
		var legacy: Dictionary = p.to_data()
		legacy.schema = schema
		legacy.erase("achievements")
		legacy.erase("broadcast")
		if schema < 3: legacy.erase("campaign")
		if schema < 2: legacy.erase("discovered")
		var migrated: MissionProfile = MissionProfile.new()
		t.check(migrated.restore(legacy) and migrated.achievements.progress.is_empty() and migrated.completed == p.completed, "legacy profile migrates without retroactive achievement rewards: %d" % schema)
	var bad: Dictionary = p.to_data()
	bad.achievements.collections.arc_aerial = ["m5.arc_aerial.b1cap", "m5.arc_aerial.b1cap"]
	t.check(not MissionProfile.new().restore(bad), "duplicate capstone IDs cannot masquerade as distinct mastery")
	var repeated: AchievementProfile = fixture(&"arc_aerial_first_capstone", true)
	var first: Dictionary = data(repeated.to_data())
	var same: CombatSession = session()
	same.achievement_run.eligible = true
	capstone(same, &"arc_aerial")
	same._finish(true)
	repeated.record_victory(same)
	t.check(data(repeated.to_data()) == first, "repeating one capstone never advances distinct-branch mastery")

func _report(t: TestContext) -> void:
	var s: CombatSession = session()
	var target: CombatActor = s.spawn_enemy(CombatContent.CARRIER, 320)
	target.health = 1000
	s.damage_actor(target, 40, &"main")
	s.damage_actor(target, 30, &"echo_deck")
	s.damage_actor(target, 20, &"ball_lightning")
	s.supports.report.add(&"bass_driver", &"exposure_bonus", 200)
	s.patchboard.add(&"live_wire", "assisted_damage", 300)
	s.active_combat.damage = 40
	t.check(PostRunAnalysis.effective_damage(s) == 90, "damage counts main, echo and recipe once; Burst and assistance are not added twice")
