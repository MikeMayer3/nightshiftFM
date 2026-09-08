extends SceneTree
## Compare the same upgrade preference and seed with/without manual combat input.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var results: Array[Dictionary] = []
	for style: String in ["main", "arc", "bass", "net"]:
		for seed_value: int in [11, 42, 91]:
			for mode: String in ["idle", "button", "aimed"]:
				var value: CombatSession = CombatSession.new()
				value.start_active(seed_value, &"run.1")
				var policy: RandomNumberGenerator = RandomNumberGenerator.new()
				policy.seed = seed_value
				var decisions: Array[Dictionary] = []
				var samples: int = 0
				var crowded: int = 0
				for step: int in 12000:
					if value.is_finished(): break
					if value.is_deciding():
						var id: StringName = value.draft.offers[policy.randi_range(0, value.draft.offers.size() - 1)]
						var priority: StringName = {"main": &"main", "arc": &"arc_aerial", "bass": &"bass_driver", "net": &"static_net"}[style]
						for offer: StringName in value.draft.offers:
							if value.draft.card(offer).target_id == priority: id = offer
						decisions.append({"id": String(id), "wave": value.wave, "seconds": value.elapsed})
						if not value.choose_upgrade(id): quit(1); return
					else:
						if mode == "aimed": aim(value)
						elif mode == "button" and value.target() != null: value.active_combat.burst(value, value.target().position)
						value.advance(0.1)
						samples += 1
						if value.actors.size() >= 3: crowded += 1
				var row: Dictionary = {"style": style, "seed": seed_value, "active": mode != "idle", "mode": mode, "victory": value.phase == CombatSession.Phase.VICTORY, "wave": value.wave, "seconds": value.elapsed, "hull": value.hull, "damage_taken": value.damage_taken, "kills": value.kills, "bursts": value.active_combat.uses, "burst_damage": value.active_combat.damage, "crowded_fraction": float(crowded)/maxi(1,samples), "decisions": decisions}
				results.append(row)
				print(JSON.stringify(row.merged({"decisions": decisions.size()}, true)))
	FileAccess.open("res://docs/evidence/M4-active/balance.json", FileAccess.WRITE).store_string(JSON.stringify(results, "\t"))
	quit(0)

static func aim(value: CombatSession) -> void:
	if value.phase != CombatSession.Phase.COMBAT or value.active_combat.cooldown > 0: return
	var best: CombatActor
	var best_score: float = -1
	var urgent: bool = false
	var count: int = 0
	for actor: CombatActor in value.actors:
		if actor.resolved: continue
		var score: float = 0
		var nearby: int = 0
		var danger: bool = false
		for neighbor: CombatActor in value.actors:
			if neighbor.resolved or neighbor.position.distance_to(actor.position) > ActiveCombat.RADIUS: continue
			nearby += 1
			score += minf(neighbor.health, 45 + value.signal_progress.choices * 3) + (20 if neighbor.projectile else 0) + maxf(0, neighbor.position.y - 400) * 0.1
			danger = danger or neighbor.position.y > 440 or (neighbor.projectile_limit > neighbor.projectiles_fired and neighbor.ability_interval - neighbor.ability_time < 0.9)
		if score > best_score:
			best_score = score
			best = actor
			count = nearby
			urgent = danger
	if best != null and (count >= 3 or urgent): value.active_combat.burst(value, best.position)
