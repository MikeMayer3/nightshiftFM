extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var t: TestContext = TestContext.new()
	root.size = Vector2i(360,640); root.content_scale_size = Vector2i(720,1280)
	RadioPreferences.current.values.sound = false; RadioPreferences.current.values.music = false
	var path: String = "user://p4_resume_%d.json" % Time.get_ticks_usec()
	var boot: BootScreen = preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = path; root.add_child(boot); boot.show_page(BootScreen.Page.COMBAT)
	var screen: CombatScreen = boot.combat
	screen.set_process(false); screen._process(.1)
	t.check(screen.broadcast.key == "P4_M1_W1", "fresh run plays opening caption")
	var saved: Dictionary = MissionStore.new(path).load_save()
	t.check(MissionStore.valid(saved), "broadcast leaves production wave checkpoint valid")
	boot.queue_free(); await process_frame
	boot = preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = path; root.add_child(boot); await settle()
	click_at(boot.continue_button.get_global_rect().get_center()); await settle()
	screen = boot.combat
	t.check(screen != null and not screen.recovery_required and not screen.save_failed, "actual Continue restores saved mission")
	screen.set_process(false)
	for frame: int in 60: screen._process(.1)
	t.check(screen.broadcast.key.is_empty(), "Continue does not replay the opening during six resumed combat seconds")
	click_at(screen.pause_button.get_global_rect().get_center()); await settle()
	click_at(screen.restart_button.get_global_rect().get_center()); await settle()
	# Restart leaves a pause boundary: production discards its first frame delta.
	screen._process(.1); screen._process(.1)
	t.check(screen.broadcast.key == "P4_M1_W1", "actual Restart allows the new run its opening broadcast")
	boot.queue_free(); await process_frame
	print("RESULT: %d actual save/Continue/Restart checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func click_at(point: Vector2) -> void:
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event,true)
