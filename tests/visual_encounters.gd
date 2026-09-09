extends SceneTree
const FIXTURE: Script = preload("res://tests/integration/test_campaign_screen.gd")
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
var checks: TestContext = TestContext.new()
var boot: BootScreen
func _initialize() -> void: _run.call_deferred()
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M8/" + name + ".png")
func click(button: BaseButton) -> void:
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await process_frame
	await process_frame
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
func width_check(control: Control, label: String) -> void:
	var scroll: ScrollContainer = control.get_child(0).get_child(0) as ScrollContainer
	checks.check(scroll.get_child(0).size.x <= scroll.size.x + 1, label + " has no horizontal overflow")
func _run() -> void:
	var path: String = "user://m8_visual_test.json"
	for size: Vector2i in [Vector2i(360,640), Vector2i(450,800), Vector2i(450,950)]:
		root.size = size
		for cleared: int in [0,1,2,3]:
			MissionStore.new(path).save(FIXTURE.new().profile_at(cleared), {})
			boot = BOOT.instantiate() as BootScreen
			boot.save_path = path
			root.add_child(boot)
			await process_frame
			await click(boot.menu.get_node("Start"))
			await capture("campaign-%d-%dx%d" % [cleared,size.x,size.y])
			width_check(boot.campaign_panel, "campaign %d %s" % [cleared,size])
			await click(boot.campaign_panel.launch_button)
			await capture("equipment-%d-%dx%d" % [cleared,size.x,size.y])
			width_check(boot.picker, "equipment %d %s" % [cleared,size])
			if cleared >= 4:
				await click(boot.picker.module_buttons.hot_tubes)
				await click(boot.picker.module_buttons.heavy_battery)
				checks.check(boot.picker.modules.size() == 2, "viewport clicks select two modules")
				await capture("modules-%d-%dx%d" % [cleared,size.x,size.y])
			await click(boot.picker.launch_button)
			checks.check(boot.combat != null and not boot.combat.save_failed, "viewport clicks launch valid mission")
			boot.combat.set_process(false)
			await capture("launch-%d-%dx%d" % [cleared,size.x,size.y])
			boot.queue_free()
			await process_frame
	print("RESULT: %d campaign visual checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures == 0 else 1)
