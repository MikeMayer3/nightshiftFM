extends SceneTree
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10-balance-modules/" + name + ".png")
func click(button: BaseButton) -> void:
	var parent: Node = button.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await process_frame; await process_frame
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.position = button.get_global_rect().get_center(); event.pressed = pressed
		root.push_input(event, true); await process_frame
func widths(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		checks.check(node.get_global_rect().end.x <= root.get_visible_rect().size.x + 1, "module UI fits width: " + str(node.name))
	for child: Node in node.get_children(): widths(child)
func run() -> void:
	root.size = Vector2i(1120, 860); root.content_scale_size = root.size
	var gallery: PanelContainer = PanelContainer.new(); gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); RadioUI.skin(gallery); root.add_child(gallery)
	var grid: GridContainer = GridContainer.new(); grid.columns = 4; grid.add_theme_constant_override("h_separation", 12); grid.add_theme_constant_override("v_separation", 12); gallery.add_child(grid)
	for id: StringName in CampaignContent.MODULES:
		var card: ModuleCard = ModuleCard.new(); card.configure(id); grid.add_child(card)
	await capture("module-gallery")
	gallery.queue_free(); await process_frame
	for dimensions: Vector2i in [Vector2i(360,640), Vector2i(450,950)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		var picker: ArsenalPicker = ArsenalPicker.new(); picker.campaign_profile = CampaignProfile.new(); picker.campaign_profile.cleared = 12; root.add_child(picker)
		await process_frame
		await click(picker.modules_body.get_parent().get_child(picker.modules_body.get_index() - 1))
		await click(picker.module_buttons.hot_tubes)
		await click(picker.module_buttons.long_mast)
		checks.check(picker.modules.size() == 2 and picker.module_buttons.heavy_battery.disabled, "whole cards select two modules and lock third")
		await capture("modules-%dx%d" % [dimensions.x, dimensions.y])
		widths(picker.modules_body)
		await click(picker.module_buttons.hot_tubes)
		await click(picker.module_buttons.glass_tower)
		checks.check(picker.modules == [&"long_mast", &"glass_tower"], "scrolling and replacing a module works through viewport input")
		await capture("modules-bottom-%dx%d" % [dimensions.x, dimensions.y])
		picker.queue_free(); await process_frame
		var screen: CombatScreen = load("res://scenes/combat/combat.tscn").instantiate()
		screen.campaign_enabled = true; screen.active_enabled = true; screen.arsenal_enabled = true; screen.m3_enabled = true
		screen.store = MissionStore.new("user://radio_balance_visual.json"); root.add_child(screen); await process_frame
		screen.set_process(false)
		var s: CombatSession = screen.session
		s.auto_fire = false
		s.advance(.1); screen._refresh_decision()
		await capture("entry-offscreen-%dx%d" % [dimensions.x, dimensions.y])
		s.advance(2.5); screen._refresh_decision()
		await capture("entry-visible-%dx%d" % [dimensions.x, dimensions.y])
		s.auto_fire = true
		s.advance(1); screen._refresh_decision()
		await capture("entry-combat-%dx%d" % [dimensions.x, dimensions.y])
		screen.queue_free(); await process_frame
	print("RESULT: %d module visual/input checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
