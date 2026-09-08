extends RefCounted
const AIM: Script = preload("res://tests/active_balance.gd")

func path(definition: TrackDefinition, branch: int, modifier: int, tuning: int = 0, rank: int = 8) -> UpgradeTrack:
	var owned: UpgradeTrack = UpgradeTrack.new(definition)
	for next: int in range(2, rank + 1):
		var eligible: Array[UpgradeDefinition] = owned.eligible([])
		var choice: UpgradeDefinition = eligible[0]
		if next == 3: choice = eligible[branch - 1]
		elif next == 6: choice = eligible[modifier - 1]
		elif next not in [8]:
			for candidate: UpgradeDefinition in eligible:
				if candidate.id == definition.options[tuning].id: choice = candidate
		owned.accept(choice.id, [])
	return owned

func fixture(main: String = "pulse", shield: String = "capacitor", support: String = "arc_aerial") -> CombatSession:
	var value: CombatSession = CombatSession.new()
	value.start_arsenal(42, &"run.1", {"main": main, "shield": shield, "support": support})
	value.wave = 1
	value.phase = CombatSession.Phase.COMBAT
	value.spawn_index = 50
	for index: int in 8:
		var actor: CombatActor = value.spawn_enemy(M4Content.enemy(&"m4.plated"), 220 + index * 25)
		actor.position.y = 420 + (index % 3) * 45
		actor.health = 10000
		actor.max_health = 10000
	return value

func run(t: TestContext) -> bool:
	var count: int = 0
	for key: String in ArsenalContent.DEFINITIONS:
		var definition: TrackDefinition = ArsenalContent.DEFINITIONS[key]
		t.check(definition.options.size() == 18, key + " has six tunings and three complete paths")
		for card: UpgradeDefinition in definition.options:
			t.check(card.validate().is_empty(), "valid M5 option " + String(card.id))
			count += 1
		for branch: int in range(1, 4):
			for modifier: int in [1, 2]:
				var owned: UpgradeTrack = path(definition, branch, modifier)
				t.check(owned.rank() == 8 and owned.eligible([]).is_empty(), "%s path %d/%d reaches rank 8 legitimately" % [key, branch, modifier])
				var reconstructed: UpgradeTrack = UpgradeTrack.new(definition)
				for id: StringName in owned.choices: reconstructed.accept(id, [])
				t.check(owned.stats == reconstructed.stats, "rank 8 parameters reconstruct exactly")
				for tuning: int in 6:
					var base: UpgradeTrack = path(definition, branch, modifier, tuning, 1)
					var before: Dictionary = ArsenalStats.parameters(base)
					t.check(base.accept(definition.options[tuning].id, []) and ArsenalStats.parameters(base) != before, key + " tuning changes bounded parameters")
	_save_paths(t)
	_contracts(t)
	t.check(count == 216, "M5 catalog totals 108 support and 108 chassis options")
	var state: CombatSession = CombatSession.new()
	state.start_arsenal(17, &"run.1", {"main": "sweep", "shield": "relay", "support": "echo_deck"})
	t.check(state.run.shield.current == 40 and state.run.main_weapon.rank == 1, "selected chassis starts at rank 1 with its own capacity")
	for id: StringName in ArsenalContent.FAMILIES: state.draft.equip(id)
	t.check(state.draft.support_count() == 5 and not state.draft.equip(&"echo_deck"), "five supports maximum and no duplicate")
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 123
	# Full live mission, random choices, every decision saved and reconstructed.
	state.start_arsenal(1, &"run.1", {"main": "burst", "shield": "feedback", "support": "needle_swarm"})
	var snapshots: int = 0
	for index: int in 8000:
		if state.is_finished(): break
		if state.is_deciding():
			var json: Variant = JSON.parse_string(JSON.stringify(state.to_checkpoint(), "", true, true))
			var restored: CombatSession = CombatSession.new()
			t.check(restored.restore_checkpoint(json), "M5 mid-wave actors and effect queues survive JSON checkpoint")
			if not restored.restore_checkpoint(json): return false
			t.check(close(restored.to_checkpoint(), state.to_checkpoint()), "restored checkpoint equals live state")
			snapshots += 1
			state.choose_upgrade(state.draft.offers[random.randi_range(0, state.draft.offers.size() - 1)])
		else:
			AIM.aim(state)
			state.advance(.1)
	t.check(state.is_finished() and snapshots >= 5, "random mission reaches a result with repeated real draft checkpoints")
	# Mechanism fixtures isolate effects from balance and use large stationary targets.
	for family: StringName in ArsenalContent.FAMILIES:
		for branch: int in [1, 2, 3]:
			var value: CombatSession = fixture("pulse", "capacitor", String(family))
			var owned: UpgradeTrack = path(ArsenalContent.DEFINITIONS[String(family)], branch, 1)
			value.draft.tracks[value.draft.tracks.find(value.draft.track(family))] = owned
			for tick: int in 360:
				if tick % 48 == 0: value.arsenal.fire_main(value, value.target())
				value.arsenal.advance(value, 1.0 / 60)
			var row: Dictionary = value.arsenal.report.totals[String(family)]
			t.check(float(row.damage) > 0, "%s branch %d produces real damage" % [family, branch])
			t.check(value.arsenal.peak_pending < 128, "generated work remains bounded")
	var echo: CombatSession = fixture("sweep", "feedback", "echo_deck")
	var generated: Array[CombatEvent] = []
	echo.combat_event.connect(func(event: CombatEvent) -> void:
		if event.source_id == &"echo_deck": generated.append(event))
	for index: int in 30: echo.arsenal.fire_main(echo, echo.target())
	for index: int in 200: echo.arsenal.advance(echo, .02)
	t.check(not generated.is_empty() and generated.all(func(e: CombatEvent) -> bool: return e.generation_depth == 1 and e.eligible_triggers == 0 and e.root_attack_id > 0), "echoes carry original roots and cannot recursively echo or reflect")
	var needle: CombatSession = fixture("pulse", "capacitor", "needle_swarm")
	needle.arsenal.advance(needle, .01)
	t.check(not needle.arsenal.needles.is_empty() and needle.arsenal.report.totals.needle_swarm.damage == 0, "needles must travel before hitting")
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(needle.arsenal.to_data(), "", true, true))
	t.check(ArsenalRuntime.valid(decoded), "traveling needle envelope validates")
	decoded.needles[0].root = "bad"
	t.check(not ArsenalRuntime.valid(decoded), "malformed generated root rejected")
	var net: CombatSession = fixture("pulse", "capacitor", "static_net")
	var elite: CombatActor = net.spawn_enemy(M4Content.enemy(&"m4.elite"), 320)
	elite.position.y = 450
	net.arsenal.advance(net, 1.0 / 60)
	t.check(elite.status.slow <= .25, "M5 retains elite control resistance")
	for chassis: String in ArsenalContent.SHIELDS:
		var value: CombatSession = fixture("pulse", chassis)
		value.run.shield.current = 5
		t.check(value.activate_shield(), chassis + " shield ability activates")
		if chassis == "capacitor": t.check(value.arsenal.overshield > 0, "capacitor grants finite overshield")
		elif chassis == "relay": t.check(value.run.shield.current > 5 and value.recharge_time == 0, "relay heals and restarts recharge")
		else:
			value.hit_station(15, &"COMBAT_PROJECTILE", &"COMBAT_PROJECTILE_HIT")
			t.check(value.run.shield.current == 5 and value.arsenal.report.totals.shield.damage > 0, "feedback reflects an eligible incoming projectile once")
	return true

func close(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int): return absf(float(a) - float(b)) <= 0.0000001
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not close(a[key], b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for index: int in a.size():
			if not close(a[index], b[index]): return false
		return true
	return a == b

func _save_paths(t: TestContext) -> void:
	for key: String in ArsenalContent.DEFINITIONS:
		var definition: TrackDefinition = ArsenalContent.DEFINITIONS[key]
		for branch: int in [1, 2, 3]:
			for modifier: int in [1, 2]:
				var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
				loadout["support" if definition.support else String(definition.id)] = key
				var rng: RunRandom = RunRandom.new(10)
				var draft: ArsenalDraft = ArsenalDraft.new(ArsenalContent.tracks(loadout), rng)
				draft.loadout = loadout
				for id: StringName in [&"main", &"shield", StringName(loadout.support)]: draft.equip(id)
				var desired: UpgradeTrack = path(definition, branch, modifier)
				for choice: StringName in desired.choices:
					while definition.id == &"shield" and draft.normal_count % 4 != 3:
						# Valid offensive decisions occupy intervening windows.
						var filler: StringName = draft.pool()[0]
						draft.offers.assign([filler])
						draft.choose(filler)
					draft.offers.assign([choice])
					draft.choose(choice)
				var encoded: Variant = JSON.parse_string(JSON.stringify(draft.to_data(), "", true, true))
				var restored: ArsenalDraft = ArsenalDraft.new(ArsenalContent.tracks(loadout), RunRandom.new(10))
				restored.loadout = loadout
				t.check(restored.restore(encoded) and restored.track(definition.id).stats == draft.track(definition.id).stats and restored.track(definition.id).rank() == 8, "%s %d/%d rank-8 save replays legitimate choices" % [key, branch, modifier])

func _contracts(t: TestContext) -> void:
	var value: CombatSession = fixture("pulse", "feedback", "echo_deck")
	var events: Array[CombatEvent] = []
	value.combat_event.connect(func(e: CombatEvent) -> void: events.append(e))
	value.active_combat.burst(value, value.target().position)
	t.check(value.arsenal.echo_count == 0 and events.all(func(e: CombatEvent) -> bool: return e.eligible_triggers & CombatEvent.CAN_ECHO == 0), "manual Burst is excluded from primary replay eligibility")
	events.clear()
	value.activate_shield()
	value.attack_serial += 1
	var incoming: int = value.attack_serial
	value.hit_station(10, &"COMBAT_PROJECTILE", &"COMBAT_PROJECTILE_HIT", &"m2.carrier", incoming)
	var reflected: Array[CombatEvent] = events.filter(func(e: CombatEvent) -> bool: return e.source_id == &"shield")
	t.check(not reflected.is_empty() and reflected.all(func(e: CombatEvent) -> bool: return e.root_attack_id == incoming and e.generation_depth == 1 and e.eligible_triggers == 0), "reflected damage retains incoming root and cannot generate another reflection")
	var echo: UpgradeTrack = path(ArsenalContent.DEFINITIONS.echo_deck, 2, 1, 0, 3)
	value.draft.tracks[value.draft.tracks.find(value.draft.track(&"echo_deck"))] = echo
	value.arsenal.clear_wave_effects()
	for index: int in 5: value.arsenal.fire_main(value, value.target())
	var roots: Array[int] = []
	for packet: Dictionary in value.arsenal.packets:
		if int(packet.root) not in roots: roots.append(int(packet.root))
	t.check(roots.size() >= 2, "Layered Recording replays a stored sequence of distinct original attacks")
	# Beam coverage hits aligned contacts; volley count produces separate damage contacts.
	for chassis: String in ["sweep", "burst"]:
		var combat: CombatSession = fixture(chassis)
		var attacks: Array[CombatEvent] = []
		combat.combat_event.connect(func(e: CombatEvent) -> void:
			if e.kind == CombatEvent.Kind.DAMAGE and e.source_id == &"main": attacks.append(e))
		combat.arsenal.fire_main(combat, combat.target())
		t.check(attacks.size() >= 2, chassis + " resolves its bounded multi-contact attack contract")
	var well: CombatSession = fixture("pulse", "capacitor", "reverb_well")
	var original: Vector2 = well.actors[1].position
	well.arsenal.advance(well, .1)
	t.check(well.actors[1].position != original, "well moves enemies toward its field center")
	var exposed: CombatActor = well.actors[0]
	exposed.status.expose(30, &"reverb_well")
	well.damage_actor(exposed, 10)
	t.check(well.arsenal.report.totals.reverb_well.exposure_bonus > 0 and well.arsenal.report.totals.bass_driver.exposure_bonus == 0, "Reverb exposure assistance is credited to its source")
	var marking: CombatSession = fixture("pulse", "capacitor", "needle_swarm")
	var pin: UpgradeTrack = path(ArsenalContent.DEFINITIONS.needle_swarm, 3, 1)
	marking.draft.tracks[2] = pin
	for index: int in 120: marking.arsenal.advance(marking, 1.0/60)
	t.check(not marking.arsenal.marks.is_empty(), "marking needles leave real vulnerability")
	var victim: CombatActor = ArsenalCombat.actor_by_id(marking, int(marking.arsenal.marks[0].target))
	victim.armor = 0
	var previous: float = victim.health
	marking.damage_actor(victim, 10)
	t.check(previous - victim.health > 10 and previous - victim.health <= 15.001, "mark boosts allied damage with a 50 percent cap")
