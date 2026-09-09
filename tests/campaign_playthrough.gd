extends SceneTree
const AIM: Script = preload("res://tests/active_balance.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var profile: MissionProfile = MissionProfile.new()
	var rows: Array[Dictionary] = []
	var passed: bool = true
	for mission: int in range(1, 5):
		var s: CombatSession = CombatSession.new()
		var identity: StringName = StringName("run.%d" % profile.next_run)
		profile.next_run += 1
		var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
		if mission >= 3: loadout.support = "echo_deck"
		if mission >= 4: loadout.support = "reverb_well"; loadout.shield = "relay"
		if not s.start_campaign(11, identity, loadout, {"mission": mission, "cleared": profile.campaign.cleared, "modules": []}):
			passed = false
			break
		var checkpoints: int = 0
		for step: int in 3000:
			if s.is_finished(): break
			if s.is_wiring():
				for id: StringName in [&"live_wire", &"dead_zone"]:
					if PatchboardState.eligible(s,id): s.patchboard.rewire(s, 0 if id == &"live_wire" else 1, id)
				s.launch_wave()
			elif s.is_deciding():
				var serialized: Dictionary = JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))
				if not CombatSession.new().restore_checkpoint(serialized): passed = false
				checkpoints += 1
				var selected: StringName = s.draft.offers[0]
				var best: int = -100
				for id: StringName in s.draft.offers:
					var card: UpgradeDefinition = s.draft.card(id)
					var score: int = 100 if SignalDraft.is_new(id) else 20 if card.target_id == &"arc_aerial" else 15 if card.target_id == &"main" else 10
					if score > best: best = score; selected = id
				s.choose_upgrade(selected)
			else:
				AIM.aim(s)
				if s.run.shield.current < s.run.shield.capacity * .3: s.activate_shield()
				s.advance(.5)
		if s.phase == CombatSession.Phase.VICTORY: profile.commit_reward(identity, s)
		else: passed = false
		var store: MissionStore = MissionStore.new("user://campaign_playthrough.json")
		var valid: bool = store.save(profile, s.to_checkpoint()) == OK
		passed = passed and valid
		var row: Dictionary = {"mission": mission, "victory": s.phase == CombatSession.Phase.VICTORY, "wave": s.wave, "seconds": s.elapsed, "hull": s.hull, "choices": s.draft.normal_count, "checkpoint_checks": checkpoints, "saved": valid, "profile_cleared": profile.campaign.cleared, "unlocked_supports": CampaignContent.options(profile.campaign.cleared, "support")}
		rows.append(row)
		print(JSON.stringify(row))
		if not passed: break
	var file: FileAccess = FileAccess.open("res://docs/evidence/M7/first-four-simulation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "runs": rows, "method": "Headless fixed-step simulation; real choices and first-clear commits, accelerated wall clock; not human pacing evidence"}, "\t", true, true))
	file.close()
	print("RESULT: %d campaign simulations; passed=%s" % [rows.size(), passed])
	quit(0 if passed else 1)
