extends RefCounted
func run(t: TestContext) -> bool:
	for id: StringName in CampaignContent.MODULES:
		t.check(CampaignContent.MODULES[id].validate().is_empty(), "bounded module authored: " + String(id))
	for mission: MissionDefinition in CampaignContent.MISSIONS:
		t.check(not mission.prototype and mission.wave_ids.size() == 10, "campaign has twelve authored ten-wave missions: " + String(mission.id))
	var profile: MissionProfile = MissionProfile.new()
	for cleared: int in range(13):
		var supports: Array = CampaignContent.options(cleared, "support")
		t.check(("echo_deck" in supports) == (cleared >= 2) and ("reverb_well" in supports) == (cleared >= 3) and ("needle_swarm" in supports) == (cleared >= 4), "exact support unlock schedule after clear %d" % cleared)
		t.check(("relay" in CampaignContent.options(cleared, "shield")) == (cleared >= 3) and ("feedback" in CampaignContent.options(cleared, "shield")) == (cleared >= 8), "shield unlock schedule %d" % cleared)
		t.check(("sweep" in CampaignContent.options(cleared, "main")) == (cleared >= 4) and ("burst" in CampaignContent.options(cleared, "main")) == (cleared >= 6), "main unlock schedule %d" % cleared)
	var starter: CombatSession = CombatSession.new()
	t.check(starter.start_campaign(11, &"run.1", ArsenalContent.DEFAULT, {"mission": 1, "cleared": 0, "modules": []}), "first campaign mission starts")
	t.check(not starter.is_wiring() and starter.patchboard.slots == [&"", &""], "patchboard waits until mission 2 is cleared")
	for index: int in 100:
		starter.draft.begin()
		for id: StringName in starter.draft.offers:
			if SignalDraft.is_new(id): t.check(String(starter.draft.card(id).target_id) in CampaignContent.options(0, "support"), "locked family cannot enter recruitment draft")
	starter.draft.offers.clear()
	starter.draft.screen_tracks.clear()
	var invalid: CombatSession = CombatSession.new()
	t.check(not invalid.start_campaign(11, &"run.1", {"main": "sweep", "shield": "capacitor", "support": "arc_aerial"}, {"mission": 1, "cleared": 0, "modules": []}), "locked main rejected at runtime")
	t.check(not invalid.start_campaign(11, &"run.1", ArsenalContent.DEFAULT, {"mission": 2, "cleared": 0, "modules": []}), "locked mission rejected at runtime")
	for ids: Array in [["hot_tubes", "hot_tubes"], ["unknown"], ["hot_tubes", "heavy_battery", "long_mast"]]:
		t.check(not CampaignContent.valid_modules(ids), "duplicate, removed, or excessive active modules rejected")
	t.check(CampaignContent.valid_modules(["hot_tubes"], 0) and CampaignContent.options(0, "modules").size() == 12, "all twelve module sidegrades available before the first mission")
	# Reward fixtures target the commit boundary; they are not simulated victories.
	for mission: int in range(1, 13):
		var s: CombatSession = CombatSession.new()
		var identity: StringName = StringName("run.%d" % profile.next_run)
		profile.next_run += 1
		s.start_campaign(11, identity, ArsenalContent.DEFAULT, {"mission": mission, "cleared": mission - 1, "modules": []})
		s.wave = 10
		s.phase = CombatSession.Phase.VICTORY
		s.elapsed = 650
		profile.commit_reward(identity, s)
		var first: Dictionary = profile.to_data()
		profile.commit_reward(identity, s)
		t.check(profile.campaign.cleared == mission and profile.to_data() == first, "first clear unlock and replay-safe commit %d" % mission)
	t.check(CampaignContent.options(profile.campaign.cleared, "modules").size() == 12, "all twelve modules unlock through first clears")
	profile.campaign.save_preset(0, {"main": "sweep", "shield": "relay", "support": "reverb_well"}, [&"heavy_battery", &"fast_fuse"])
	var restored: MissionProfile = MissionProfile.new()
	t.check(restored.restore(JSON.parse_string(JSON.stringify(profile.to_data()))) and json_data(restored.to_data()) == json_data(profile.to_data()), "campaign records and presets survive JSON save migration fixture")
	var stale: Dictionary = profile.to_data()
	stale.campaign.presets[0].modules = ["retired_module"]
	stale.campaign.presets[0].loadout.main = "m2.pulse"
	var migrated: MissionProfile = MissionProfile.new()
	t.check(migrated.restore(stale) and migrated.campaign.presets[0].modules.is_empty() and migrated.campaign.presets[0].loadout.main == "pulse" and migrated.campaign.cleared == 12, "removed preset module and renamed equipment migrate without losing campaign records")
	for schema: int in [1, 2]:
		var legacy: Dictionary = MissionProfile.new().to_data()
		legacy.erase("campaign")
		legacy.erase("achievements")
		legacy.erase("broadcast")
		legacy.schema = schema
		if schema == 1: legacy.erase("discovered")
		t.check(MissionProfile.new().restore(legacy), "legacy profile schema %d remains readable" % schema)
	_modules(t)
	_snapshots(t, profile)
	_mastery(t)
	_high_rank_modules(t)
	return true

func session(ids: Array[StringName], support: String = "arc_aerial") -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(11, &"run.1", {"main": "pulse", "shield": "capacitor", "support": support}, {"mission": 1, "cleared": 12, "modules": Array(ids)})
	return s

func _modules(t: TestContext) -> void:
	var baseline: CombatSession = session([])
	var base_shield: Dictionary = baseline.arsenal.shield_parameters(baseline)
	var hot: CombatSession = session([&"hot_tubes"])
	t.check(ArsenalStats.parameters(hot.draft.track(&"main")).interval < .6 and hot.shield_stat(&"recharge", 0) < baseline.shield_stat(&"recharge", 0), "Hot Tubes speeds actual fire timer and slows shield recharge")
	var mast: CombatSession = session([&"long_mast"])
	for s: CombatSession in [baseline, mast]:
		s.phase = CombatSession.Phase.COMBAT
		s.spawn_enemy(CombatContent.SWARMER, 320).position = Vector2(320, 50)
		s.arsenal.fire_main(s, s.actors[0])
	t.check(baseline.actors[0].health == baseline.actors[0].max_health and mast.actors[0].health < mast.actors[0].max_health and mast.hull == 90, "Long Mast hits beyond ordinary acquisition range at a hull cost")
	var battery: CombatSession = session([&"heavy_battery"])
	t.check(is_equal_approx(battery.run.shield.current, 81.25) and is_equal_approx(battery.shield_stat(&"recharge", 0), 5.6), "Heavy Battery applies capacity gain and recharge cost at spawn")
	var fuse: CombatSession = session([&"fast_fuse"])
	fuse.patchboard.awaiting = false
	fuse.activate_shield()
	t.check(is_equal_approx(fuse.ability_wait, 11.9) and is_equal_approx(fuse.run.shield.capacity, 55.25), "Fast Fuse changes real activation cooldown and shield capacity")
	var booster: CombatSession = session([&"signal_booster"])
	booster.hit_station(10, &"M2_SWARMER_NAME")
	t.check(is_equal_approx(booster.recharge_time, 5) and is_equal_approx(ArsenalStats.parameters(booster.draft.track(&"main")).damage, 13.8), "Signal Booster adds damage and delays real recharge")
	var quiet: CombatSession = session([&"quiet_room"], "bass_driver")
	t.check(ArsenalStats.parameters(quiet.draft.track(&"bass_driver")).interval > 2.4 and quiet.shield_stat(&"recharge", 0) > base_shield.recharge, "Quiet Room delays support activation in exchange for recharge")
	for pair: Array in [[&"wideband_module", 132.0, 10.2], [&"narrowband_module", 93.5, 14.4]]:
		var s: CombatSession = session([pair[0]])
		t.check(is_equal_approx(s.active_combat.radius_for(s), pair[1]) and is_equal_approx(ArsenalStats.parameters(s.draft.track(&"main")).damage, pair[2]), "area/direct module affects actual Burst radius and direct projectile damage")
	var weight: CombatSession = session([&"counterweight"], "reverb_well")
	weight.draft.equip(&"needle_swarm")
	weight.apply_ranks()
	t.check(is_equal_approx(ArsenalStats.parameters(weight.draft.track(&"reverb_well")).pull, 40) and is_equal_approx(ArsenalStats.parameters(weight.draft.track(&"needle_swarm")).speed, 450), "Counterweight modifies displacement and projectile travel parameters")
	var thin: CombatSession = session([&"thin_wire"])
	thin.phase = CombatSession.Phase.COMBAT
	var actor: CombatActor = thin.spawn_enemy(CombatContent.CARRIER, 320)
	thin.arsenal._arc(thin, actor, ArsenalStats.parameters(thin.draft.track(&"arc_aerial")), 1)
	t.check(is_equal_approx(actor.status.charge_left, 3.9) and is_equal_approx(thin.run.shield.capacity, 58.5), "Thin Wire extends applied Charged status and reduces capacity")
	var ledger: CombatSession = session([&"night_ledger"])
	ledger.draft.begin()
	t.check(ledger.draft.reroll() and ledger.draft.reroll() and ledger.draft.reroll() and not ledger.draft.reroll() and is_equal_approx(ArsenalStats.parameters(ledger.draft.track(&"main")).damage, 10.8), "Night Ledger grants exactly one extra usable reroll with main damage cost")
	var ledger_copy: CombatSession = session([&"night_ledger"])
	t.check(ledger_copy.draft.restore(json_data(ledger.draft.to_data())) and ledger_copy.draft.rerolls == 0 and not ledger_copy.draft.reroll(), "spent bonus reroll cannot return after draft restoration")
	var glass: CombatSession = session([&"glass_tower"])
	t.check(is_equal_approx(ArsenalStats.parameters(glass.draft.track(&"main")).crit, .1) and glass.hull == 85, "Glass Tower raises the main hit critical parameter and lowers hull")
	var combined: CombatSession = session([&"heavy_battery", &"fast_fuse"])
	t.check(is_equal_approx(combined.run.shield.capacity, 71.5), "module percentages combine additively before baseline multiplication")
	combined.start_campaign(12, &"run.2", ArsenalContent.DEFAULT, {"mission": 1, "cleared": 12, "modules": []})
	t.check(combined.hull == 100 and combined.run.shield.current == 65 and combined.draft.track(&"main").rank() == 1 and combined.draft.rerolls == 2, "new mission removes every module and temporary upgrade from previous run")
	t.check(ArsenalContent.DEFINITIONS.capacitor.baseline.capacity == 65, "module experiments never mutate shared resources")

func _snapshots(t: TestContext, profile: MissionProfile) -> void:
	var ids: Array = CampaignContent.MODULES.keys()
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			var s: CombatSession = session([ids[i], ids[j]], "needle_swarm")
			s.launch_wave()
			s.advance(2.4)
			var copy: CombatSession = CombatSession.new()
			var data: Dictionary = JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))
			t.check(copy.restore_checkpoint(data) and json_data(copy.to_checkpoint()) == data, "module pair reconstructs active actors/effects and baseline: %s / %s" % [ids[i], ids[j]])
	var saved: CombatSession = session([&"night_ledger", &"quiet_room"], "echo_deck")
	saved.launch_wave()
	saved.advance(2.4)
	var store: MissionStore = MissionStore.new("user://campaign_unit.json")
	t.check(store.save(profile, saved.to_checkpoint()) == OK, "real atomic store accepts module run with its campaign profile")
	var invalid: Dictionary = saved.to_checkpoint()
	invalid.campaign.modules = ["retired_module"]
	t.check(not CombatSession.new().restore_checkpoint(invalid), "removed active module cannot silently change a continued run")

func _mastery(t: TestContext) -> void:
	var p: MissionProfile = MissionProfile.new()
	var s: CombatSession = session([], "arc_aerial")
	var owned: UpgradeTrack = s.draft.track(&"arc_aerial")
	while owned.rank() < 8: owned.accept(owned.eligible([])[0].id, [])
	s.campaign.cleared = 0
	s.phase = CombatSession.Phase.VICTORY
	s.wave = 10
	p.next_run = 2
	p.commit_reward(&"run.1", s)
	var before: Dictionary = p.to_data()
	p.commit_reward(&"run.1", s)
	t.check(p.to_data() == before and p.campaign.cosmetic_available(&"arc_aerial") and p.campaign.mastery.arc_aerial.size() == 1, "committed capstone unlocks one cosmetic without duplicate mastery")

	for branch: int in [2,3]:
		var other: CombatSession = session([], "arc_aerial")
		var track: UpgradeTrack = other.draft.track(&"arc_aerial")
		while track.rank() < 8:
			var options: Array[UpgradeDefinition] = track.eligible([])
			var choice: StringName = options[0].id
			if track.rank() == 2: choice = StringName("m5.arc_aerial.b%d" % branch)
			track.accept(choice, [])
		other.campaign.cleared = 0
		other.phase = CombatSession.Phase.VICTORY
		other.wave = 10
		var identity: StringName = StringName("run.%d" % p.next_run)
		p.next_run += 1
		p.commit_reward(identity, other)
	t.check(p.campaign.mastery.arc_aerial.size() == 3, "three distinct committed capstones earn the Full Range cosmetic title")
	p.campaign.cosmetic = &"arc_aerial"
	t.check(MissionProfile.new().restore(JSON.parse_string(JSON.stringify(p.to_data()))), "cosmetic selection survives a provided-save migration")

func json_data(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value, "", true, true))

func _high_rank_modules(t: TestContext) -> void:
	var ids: Array = CampaignContent.MODULES.keys()
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			for chassis: String in ArsenalContent.MAINS + ArsenalContent.FAMILIES:
				for branch: int in 3:
					var owned: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[chassis])
					owned.modules.assign([ids[i], ids[j]])
					while owned.rank() < 8:
						var eligible: Array[UpgradeDefinition] = owned.eligible([])
						if eligible.is_empty(): break
						owned.accept(eligible[mini(branch, eligible.size() - 1)].id, [])
					t.check(owned.rank() == 8 and ArsenalRuntime.parameters(ArsenalStats.parameters(owned)), "rank-8 effect envelope accepts %s path %d with %s / %s" % [chassis, branch, ids[i], ids[j]])
