extends RefCounted
func session() -> CombatSession:
	var value: CombatSession = CombatSession.new()
	value.start_active(42, &"run.1")
	return value
func run(context: TestContext) -> bool:
	var value: CombatSession = session()
	context.check(value.active_combat != null and value.signal_progress.threshold() == 6, "active mission starts fresh burst and kill thresholds")
	value.advance(2.1)
	context.check(value.actors.size() == 5 and value.spawn_index == 5, "active wave spawns a five-enemy formation")
	context.check(value.actors[0].max_health == CombatContent.SWARMER.health * 2, "active threats survive isolated automatic hits")
	value.auto_fire = false
	var center: Vector2 = value.actors[2].position
	context.check(not value.active_combat.burst(value, Vector2(-1, 0)) and not value.active_combat.burst(value, Vector2(320, 600)), "outside/empty bursts cost no cooldown")
	context.check(value.active_combat.burst(value, center) and value.kills == 5 and value.signal_progress.earned == 5, "aimed burst damages a cluster and gives one signal per kill")
	context.check(not value.active_combat.burst(value, center) and value.active_combat.uses == 1, "held input cannot spam bursts during cooldown")
	value.advance(CombatSession.STEP)
	var data: Dictionary = value.to_checkpoint()
	var restored: CombatSession = CombatSession.new()
	context.check(restored.restore_checkpoint(JSON.parse_string(JSON.stringify(data, "", true, true))) and restored.active_combat.to_data() == value.active_combat.to_data(), "burst cooldown and usage survive mid-combat JSON recovery")
	value.paused = true
	var before: float = value.active_combat.cooldown
	value.advance(20)
	context.check(value.active_combat.cooldown == before and not value.active_combat.burst(value, center), "pause freezes cooldown and blocks burst")
	value.paused = false
	value.advance(6)
	context.check(value.active_combat.cooldown == 0, "burst recharges with active simulation time")
	value.active_combat.burst(value, value.actors[2].position)
	value.advance(CombatSession.STEP)
	context.check(value.phase == CombatSession.Phase.DRAFT and value.kills == 10, "multi-kill completes before the choice pauses the fight")
	context.check(not value.active_combat.burst(value, center), "draft blocks active combat input")
	value.choose_upgrade(value.draft.offers[0])
	context.check(value.signal_progress.progress() == 4 and value.signal_progress.threshold() == 9, "active flow retains overflow with its own escalating costs")
	var saved: Dictionary = value.to_checkpoint()
	context.check(CombatSession.new().restore_checkpoint(JSON.parse_string(JSON.stringify(saved, "", true, true))), "active decision purchase restores with original actors and burst cooldown")
	saved.active.cooldown = -1
	context.check(not CombatSession.new().restore_checkpoint(saved), "invalid burst cooldown is rejected")
	value = session()
	value.wave = 1
	value.phase = CombatSession.Phase.COMBAT
	var plated: CombatActor = value.spawn_enemy(M4Content.PLATED, 320)
	plated.position.y = 350
	context.check(value.active_combat.burst(value, plated.position) and plated.status.jam_left > 0 and plated.health < plated.max_health, "burst penetrates armor and interrupts a ranged attacker")
	value.active_combat.cooldown = 0
	for index: int in 10:
		var actor: CombatActor = value.spawn_enemy(CombatContent.SWARMER, 320)
		actor.position.y = 350
	value.active_combat.burst(value, Vector2(320,350))
	context.check(value.actors.filter(func(a: CombatActor) -> bool: return a.resolved).size() == 8, "burst caps each activation at eight distinct targets")
	value.start_signal(42, &"run.1")
	context.check(value.active_combat == null and value.signal_progress.threshold() == 5, "legacy Signal runs retain their original behavior")
	value.start_active(42, &"run.2")
	context.check(value.active_combat.uses == 0 and value.active_combat.cooldown == 0 and value.signal_progress.earned == 0, "new run resets temporary combat power")
	context.check(value.active_combat.burst_damage(20) == 110, "new burst scaling gives mixed builds a small late-game damage increase")
	value.wave = 8
	context.check(value.wave_definition().enemy_ids.count(&"m4.elite") == 2 and value.wave_definition().enemy_ids.size() == 40 and value.wave_definition().validate().is_empty(), "first elite wave introduces two Overseers with unchanged formation count")
	value.active_combat.content_version = ActiveCombat.LEGACY_VERSION
	context.check(value.wave_definition().enemy_ids.count(&"m4.elite") == 4, "legacy active run preserves the original four-elite wave")
	value.wave = 10
	context.check(value.wave_definition().enemy_ids.count(&"m4.elite") == 4, "finale keeps four Overseers")
	value.wave = 0
	var legacy: CombatSession = CombatSession.new()
	context.check(legacy.restore_checkpoint(value.to_checkpoint()) and legacy.active_combat.burst_damage(20) == 105 and legacy.to_checkpoint().content == ActiveCombat.LEGACY_VERSION, "legacy active saves retain their burst balance after load and re-save")
	var owned: UpgradeTrack = value.draft.track(&"arc_aerial")
	context.check(value.supports.recharge_fraction(owned) == 1, "support starts ready even without a target")
	value.advance(2.1)
	context.check(value.supports.recharge_fraction(owned) < 0.1, "support bar empties when the weapon fires")
	value.auto_fire = false
	value.supports.timers["arc_aerial"] = SupportCombat.attack_interval(owned) * 0.5
	context.check(is_equal_approx(value.supports.recharge_fraction(owned), 0.5), "support bar represents half of the actual firing cooldown")
	value.paused = true
	value.advance(2)
	context.check(is_equal_approx(value.supports.recharge_fraction(owned), 0.5), "pause freezes support bars with combat")
	value.paused = false
	var resumed: CombatSession = CombatSession.new()
	context.check(resumed.restore_checkpoint(value.to_checkpoint()) and is_equal_approx(resumed.supports.recharge_fraction(resumed.draft.track(&"arc_aerial")), 0.5), "mid-wave recovery preserves support cooldown progress")
	value.advance(2)
	context.check(value.supports.recharge_fraction(owned) == 1, "support bar fills on recharge")
	for definition: TrackDefinition in [SignalContent.ARC, SignalContent.BASS, SignalContent.NET]:
		var modified: UpgradeTrack = UpgradeTrack.new(definition)
		modified.stats[&"mode"] = 3 if definition.id == &"arc_aerial" else (2 if definition.id == &"bass_driver" else 1)
		modified.stats[&"modifier"] = 2 if definition.id == &"arc_aerial" else 1
		var expected: float = float(modified.stats[&"interval"]) * (1.5 if definition.id == &"arc_aerial" else 1.25)
		context.check(is_equal_approx(SupportCombat.attack_interval(modified), expected), "support cooldown includes branch modifiers: " + String(definition.id))
	for definition: WaveDefinition in ActiveContent.WAVES:
		context.check(definition.validate().is_empty(), "active wave definition validates")
	return true
