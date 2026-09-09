extends SceneTree
## Real fixed-step combat and legal upgrades. Accelerated; no human pacing claim.
const AIM: Script = preload("res://tests/active_balance.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var rows: Array[Dictionary] = []
	var valid: bool = true
	for style: String in ["arc_aerial"]:
		for seed_value: int in [11]:
			var profile: MissionProfile = MissionProfile.new()
			for mission: int in range(1, 4):
				var s: CombatSession = CombatSession.new()
				var identity: StringName = StringName("run.%d" % profile.next_run)
				profile.next_run += 1
				if not s.start_campaign(seed_value, identity, {"main": "pulse", "shield": "capacitor", "support": style}, {"mission": mission, "cleared": profile.campaign.cleared, "modules": []}):
					valid = false
					break
				# Synthetic eligible-build fixture; never the player profile.
				s.achievement_run.eligible = true
				var restored: int = 0
				var decisions: Array[Dictionary] = []
				for step: int in 3000:
					if s.is_finished(): break
					if s.is_wiring():
						for id: StringName in [&"live_wire", &"dead_zone"]:
							if PatchboardState.eligible(s, id): s.patchboard.rewire(s, 0 if id == &"live_wire" else 1, id)
						s.launch_wave()
					elif s.is_deciding():
						var copy: CombatSession = CombatSession.new()
						if not copy.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))):
							valid = false
							break
						s = copy
						restored += 1
						var selected: StringName = s.draft.offers[0]
						var best: int = -100
						for id: StringName in s.draft.offers:
							var card: UpgradeDefinition = s.draft.card(id)
							var score: int = 100 if SignalDraft.is_new(id) else 30 if card.target_id == StringName(style) else 20 if card.target_id == &"main" else 10
							if score > best: best = score; selected = id
						decisions.append({"wave": s.wave, "id": String(selected)})
						if not s.choose_upgrade(selected): valid = false; break
					else:
						AIM.aim(s)
						if s.run.shield.current < s.run.shield.capacity * .3: s.activate_shield()
						s.advance(.5)
				var won: bool = s.phase == CombatSession.Phase.VICTORY
				if won:
					profile.commit_reward(identity, s)
					valid = valid and profile.achievements.earned(&"first_broadcast")
				var saved: bool = MissionStore.new("user://m9_playthrough_fixture.json").save(profile, s.to_checkpoint()) == OK
				valid = valid and saved and s.is_finished()
				var row: Dictionary = {"mission": mission, "style": style, "seed": seed_value, "victory": won, "wave": s.wave, "seconds": s.elapsed, "hull": s.hull, "kills": s.kills, "breaches": s.breaches, "choices": decisions.size(), "restores": restored, "saved": saved, "cause": String(s.last_cause), "profile_cleared": profile.campaign.cleared, "achievement_rewards": Array(profile.achievements.reward_ids())}
				print(JSON.stringify(row))
				row["decisions"] = decisions
				rows.append(row)
				if not won: break
	var victories: int = rows.filter(func(row: Dictionary) -> bool: return row.victory).size()
	var passed: bool = valid and rows.size() == 3 and victories == 3
	FileAccess.open("res://docs/evidence/M9/playthrough.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "valid": valid, "method": "Synthetic eligibility fixture in editor; headless fixed-step combat, legal offers; restore and continue each decision checkpoint. Not human playtesting.", "runs": rows}, "\t", true, true))
	print("RESULT: %d victories / %d runs; valid=%s" % [victories, rows.size(), valid])
	quit(0 if passed else 1)
