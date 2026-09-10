extends SceneTree
## Legal drafts, independent policy RNG, no injected damage or stat bonuses.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var rows: Array[Dictionary] = []
	var valid: bool = true
	var equipped: bool = "equipped" in OS.get_cmdline_user_args()
	for mission: int in ([4, 8, 12] if equipped else [1, 4, 8, 12]):
		for policy: String in ["random", "recruit_first", "tower_first"]:
			for seed_value: int in ([11, 42] if equipped else [11, 42, 91, 137, 205]):
				var s: CombatSession = CombatSession.new()
				var rng: RandomNumberGenerator = RandomNumberGenerator.new(); rng.seed = seed_value + 9000
				var option: int = ["random", "recruit_first", "tower_first"].find(policy)
				var loadout: Dictionary = {"main": ["pulse", "sweep", "burst"][option], "shield": ["capacitor", "relay", "feedback"][option], "support": ["arc_aerial", "bass_driver", "needle_swarm"][option]} if equipped else ArsenalContent.DEFAULT
				valid = s.start_campaign(seed_value, &"run.1", loadout, {"mission": mission, "cleared": 12 if equipped else mission - 1, "modules": ["hot_tubes", "signal_booster"] if equipped else [], "mode": "campaign", "difficulty": 0, "contract": ""}) and valid
				var restores: int = 0
				if equipped:
					s.paused = true
					valid = s.patchboard.mixer.adjust(s, 0, 4) and s.patchboard.mixer.adjust(s, 1, 3) and valid
					s.paused = false
				for step: int in 2400:
					if s.is_finished(): break
					if s.is_wiring(): s.launch_wave()
					elif s.is_deciding():
						if equipped:
							var copy: CombatSession = CombatSession.new()
							if not copy.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(), "", true, true))): valid = false; break
							s = copy; restores += 1
						var choice: StringName = s.draft.offers[rng.randi_range(0, s.draft.offers.size() - 1)]
						if policy != "random":
							var best: int = -999
							for id: StringName in s.draft.offers:
								var card: UpgradeDefinition = s.draft.card(id)
								var score: int = 0
								if card != null:
									score = (100 if SignalDraft.is_new(id) else 70 if card.target_id == &"main" else 20 if card.target_id != &"shield" else 0) if policy == "recruit_first" else (100 if card.target_id == &"shield" else 10 if card.target_id == &"main" else 0)
								if score > best: best = score; choice = id
						valid = s.choose_upgrade(choice) and valid
					else:
						if s.run.shield.current < s.run.shield.capacity * .3: s.activate_shield()
						s.advance(.5)
				valid = s.is_finished() and valid
				var row: Dictionary = {"mission": mission, "policy": policy, "seed": seed_value, "equipped": equipped, "loadout": loadout, "restores": restores, "victory": s.phase == CombatSession.Phase.VICTORY, "finished": s.is_finished(), "wave": s.wave, "hull": s.hull, "breaches": s.breaches, "seconds": s.elapsed}
				rows.append(row); print(JSON.stringify(row))
	var name: String = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "after"
	FileAccess.open("res://docs/evidence/M10-balance-modules/" + name + ".json", FileAccess.WRITE).store_string(JSON.stringify({"valid": valid, "runs": rows}, "\t"))
	print("RESULT: %d wins / %d; valid=%s" % [rows.filter(func(r: Dictionary) -> bool: return r.victory).size(), rows.size(), valid])
	quit(0 if valid else 1)
