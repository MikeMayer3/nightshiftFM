extends Node
## QA-only observer in an isolated export. The host drives real Android touch input.
## No combat advance, damage, cooldown, time-scale or upgrade mutations here.
var screen: CombatScreen
var policy: RandomNumberGenerator = RandomNumberGenerator.new()
var next_sample: float = 0
var decision_key: int = -1
var decision_index: int = -1
var seed_value: int = 1

func _ready() -> void:
	var seed_file: String = "user://qa_seed.txt"
	if FileAccess.file_exists(seed_file): seed_value = int(FileAccess.get_file_as_string(seed_file))
	policy.seed = seed_value + 10000
	screen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.arsenal_enabled = true
	screen.store = MissionStore.new("user://qa_mission.json")
	add_child(screen)
	var chosen: Dictionary = ArsenalContent.DEFAULT.duplicate()
	if FileAccess.file_exists("user://qa_loadout.json"):
		var provided: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://qa_loadout.json"))
		if ArsenalContent.valid_loadout(provided): chosen = provided
	screen.loadout = chosen
	screen.session.start_arsenal(seed_value, &"run.1", chosen)
	screen._save_checkpoint()
	screen._refresh_decision()

func aim_point(value: CombatSession) -> Vector2:
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
	return best.position if best != null and (count >= 3 or urgent) else Vector2.INF

func physical(point: Vector2) -> Array[float]:
	# Android's game surface excludes system-bar insets. ADB coordinates are
	# screen-relative, so include the actual window origin as well as its scale.
	var mapped: Vector2 = Vector2(DisplayServer.window_get_position()) + point * Vector2(DisplayServer.window_get_size()) / screen.get_viewport_rect().size
	return [mapped.x, mapped.y]

func _process(delta: float) -> void:
	next_sample -= delta
	if next_sample > 0: return
	next_sample = 0.25
	var value: CombatSession = screen.session
	var row: Dictionary = {"seed": seed_value, "phase": value.phase, "wave": value.wave, "seconds": value.elapsed, "hull": value.hull, "kills": value.kills, "bursts": value.active_combat.uses, "cooldown": value.active_combat.cooldown, "choices": value.signal_progress.choices, "paused": value.paused, "save_failed": screen.save_failed, "fps": Engine.get_frames_per_second(), "finished": value.is_finished(), "victory": value.phase == CombatSession.Phase.VICTORY, "decisions": value.draft.accepted, "support_timers": value.supports.timers, "equipped": screen.arena.equipped_supports(), "loadout": (value.draft as ArsenalDraft).loadout, "shield": value.run.shield.current, "shield_wait": value.ability_wait, "pending": value.arsenal.peak_pending}
	row["coordinates"] = {"window": str(DisplayServer.window_get_size()), "origin": str(DisplayServer.window_get_position()), "viewport": str(screen.get_viewport_rect()), "arena": str(screen.arena.get_global_rect()), "canvas": str(screen.arena.get_global_transform_with_canvas()), "stretch": str(get_viewport().get_stretch_transform()), "safe": str(DisplayServer.get_display_safe_area())}
	if value.is_deciding() and screen.draft_panel.visible and not screen.draft_panel.cards.is_empty():
		if decision_key != value.signal_progress.choices:
			decision_key = value.signal_progress.choices
			decision_index = policy.randi_range(0, value.draft.offers.size() - 1)
		row["action"] = "upgrade"
		row["index"] = decision_index
		row["offers"] = value.draft.offers
		row["point"] = physical(screen.draft_panel.cards[decision_index].get_global_rect().get_center())
	elif value.phase == CombatSession.Phase.COMBAT and value.run.shield.current < value.run.shield.capacity * .3 and value.ability_wait == 0 and not value.paused:
		row["action"] = "shield"
		row["point"] = physical(screen.shield_button.get_global_rect().get_center())
	elif value.phase == CombatSession.Phase.COMBAT and value.active_combat.cooldown <= 0 and not value.paused:
		var point: Vector2 = aim_point(value)
		if point.is_finite():
			row["action"] = "burst"
			row["point"] = physical(screen.arena.get_global_transform_with_canvas() * (screen.arena.arena_offset() + point * screen.arena.arena_stretch()))
	var temporary: String = "user://qa_telemetry.tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	file.store_string(JSON.stringify(row, "", true, true))
	file.close()
	DirAccess.rename_absolute(temporary, "user://qa_telemetry.json")
