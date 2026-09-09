extends Node
## QA-only observer in an isolated export. The host drives real Android touch input.
## No combat advance, damage, cooldown, time-scale or upgrade mutations here.
var screen: CombatScreen
var policy: RandomNumberGenerator = RandomNumberGenerator.new()
var next_sample: float = 0
var decision_key: int = -1
var decision_index: int = -1
var seed_value: int = 11
var build_name: String = "charge_control"
var desired_recipes: Array[StringName] = []
var desired_supports: Array[StringName] = []

func _ready() -> void:
	var seed_file: String = "user://qa_seed.txt"
	if FileAccess.file_exists(seed_file): seed_value = int(FileAccess.get_file_as_string(seed_file))
	policy.seed = seed_value + 10000
	screen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.arsenal_enabled = true
	screen.patchboard_enabled = true
	screen.campaign_enabled = FileAccess.file_exists("user://qa_campaign")
	screen.store = MissionStore.new("user://qa_mission.json")
	screen.resume_existing = FileAccess.file_exists("user://qa_resume")
	add_child(screen)
	var chosen: Dictionary = ArsenalContent.DEFAULT.duplicate()
	if FileAccess.file_exists("user://qa_loadout.json"):
		var provided: Variant = JSON.parse_string(FileAccess.get_file_as_string("user://qa_loadout.json"))
		if ArsenalContent.valid_loadout(provided): chosen = provided
	screen.loadout = chosen
	if FileAccess.file_exists("user://qa_build.txt"): build_name = FileAccess.get_file_as_string("user://qa_build.txt").strip_edges()
	var builds: Dictionary = {"charge_control": [&"live_wire", &"ball_lightning"], "group_repeats": [&"pressure_drop", &"double_drop"], "marked_replays": [&"b_side", &"needle_thread"]}
	desired_recipes.assign(builds[build_name])
	for id: StringName in desired_recipes:
		for endpoint: StringName in (PatchboardContent.RECIPES[id] as SynergyDefinition).endpoint_ids:
			if endpoint not in desired_supports: desired_supports.append(endpoint)
	if not screen.resume_existing:
		if screen.campaign_enabled: screen.session.start_campaign(seed_value, &"run.1", chosen, {"mission": 1, "cleared": 0, "modules": []})
		else: screen.session.start_patchboard(seed_value, &"run.1", chosen)
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
	row["campaign"] = screen.profile.campaign.to_data()
	row["build"] = build_name
	row["connections"] = value.patchboard.to_data()
	row["report"] = value.supports.report.totals
	if value.is_wiring():
		var panel: PatchboardPanel = screen.patchboard_panel
		var action_button: Button = panel.launch_button
		for index: int in 2:
			var id: StringName = desired_recipes[index]
			if value.patchboard.slots[index] != id and PatchboardState.eligible(value, id):
				action_button = panel.slot_buttons[index] if panel.selected_slot != index else panel.recipe_buttons[id]
				break
		control_action(row, action_button, "wire")
	elif value.is_deciding() and screen.draft_panel.visible:
		var panel: DraftPanel = screen.draft_panel
		var selected: int = 0
		var best: int = -1000
		for index: int in value.draft.offers.size():
			var id: StringName = value.draft.offers[index]
			var card: UpgradeDefinition = value.draft.card(id)
			var score: int = 0
			if card != null:
				if card.target_id in desired_supports: score += 20
				if String(id).begins_with("recruit."): score += 100 if card.target_id in desired_supports else -100
				if card.target_id == &"main": score += 10
				if id == &"m5.needle_swarm.b3": score += 150
				if build_name == "marked_replays" and card.target_id == &"needle_swarm" and value.draft.track(&"needle_swarm").rank() < 3: score += 50
			if screen.campaign_enabled and card != null: score = 100 if SignalDraft.is_new(id) else 20 if card.target_id == &"arc_aerial" else 15 if card.target_id == &"main" else 10
			if score > best: best = score; selected = index
		row["offers"] = value.draft.offers
		row["index"] = selected
		var needle: UpgradeTrack = value.draft.track(&"needle_swarm")
		if build_name == "marked_replays" and needle != null and needle.rank() == 2 and &"m5.needle_swarm.b3" not in value.draft.offers:
			if not panel.cards.is_empty():
				for index: int in value.draft.offers.size():
					var card: UpgradeDefinition = value.draft.card(value.draft.offers[index])
					if card != null and card.target_id == &"needle_swarm" and card.required_rank == 3:
						control_action(row, panel.info_buttons[index], "branch_info")
			else:
				var caption: String = tr("M4_SWAP_BRANCH") % tr(value.draft.card(&"m5.needle_swarm.b3").name_key)
				for node: Node in panel.column.get_children():
					if node is Button and node.text == caption: control_action(row, node, "branch_swap")
		if not row.has("action") and not panel.cards.is_empty(): control_action(row, panel.cards[selected], "upgrade")
	elif value.phase == CombatSession.Phase.COMBAT and value.run.shield.current < value.run.shield.capacity * .3 and value.ability_wait == 0 and not value.paused:
		control_action(row, screen.shield_button, "shield")
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

func control_action(row: Dictionary, control: Control, action: String) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			var bounds: Rect2 = ancestor.get_global_rect().grow(-20)
			if not bounds.has_point(point):
				row["action"] = "scroll"
				row["point"] = physical(bounds.get_center())
				row["end"] = physical(bounds.get_center() + Vector2(0, -bounds.size.y * .45 if point.y > bounds.end.y else bounds.size.y * .45))
				return
		ancestor = ancestor.get_parent()
	row["action"] = action
	row["point"] = physical(point)
	row["caption"] = control.text if control is Button else ""
