extends RefCounted

const PROBE: PackedScene = preload("res://scenes/ui/mobile_probe.tscn")

func run(context: TestContext, tree: SceneTree) -> bool:
	var canvas: Rect2 = Rect2(0, 0, 720, 1280)
	var screen_transform: Transform2D = Transform2D(Vector2(2, 0), Vector2(0, 2), Vector2(100, 200))
	context.check(SafeArea.to_canvas(Rect2(100, 300, 1440, 2360), screen_transform, canvas) == Rect2(0, 50, 720, 1180), "safe area converts pixels through scale and letterbox offset")
	context.check(SafeArea.to_canvas(Rect2(0, 0, 2000, 3000), screen_transform, canvas) == canvas, "safe area clamps extra display space to fixed canvas")
	context.check(SafeArea.to_canvas(Rect2(), screen_transform, canvas) == canvas, "unavailable safe-area measurement uses full canvas")
	var path: String = "user://m1_test_%d.json" % Time.get_ticks_usec()
	var store: ProbeStore = ProbeStore.new(path)
	context.check(store.load_checkpoint().is_empty() and store.last_error == OK, "first launch has no checkpoint")
	context.check(store.save_checkpoint(3, 2.5) == OK, "probe checkpoint commits")
	context.check(store.save_checkpoint(4, 3.5) == OK, "second checkpoint rotates backup")
	context.check(store.load_checkpoint().taps == 4, "latest checkpoint loads")
	var broken: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	broken.store_string('{"schema":1,"taps":')
	broken.close()
	var recovered: Dictionary = store.load_checkpoint()
	context.check(recovered.taps == 3 and store.recovered_backup, "truncated checkpoint recovers validated backup")
	context.check(store.save_checkpoint(5, 4.5) == OK, "save after recovery repairs primary")
	context.check(store.load_checkpoint().taps == 5, "repaired primary loads")
	context.check(store.save_checkpoint(-1, 0.0) == ERR_INVALID_DATA, "negative tap count rejected")
	context.check(store.save_checkpoint(1, NAN) == ERR_INVALID_DATA, "nonfinite clock rejected")
	context.check(not ProbeStore.valid({"schema": 2, "taps": 1, "active_seconds": 0}), "unsupported checkpoint version rejected")
	context.check(not ProbeStore.valid({"schema": 1, "taps": 1.5, "active_seconds": 0}), "fractional tap count rejected")
	context.check(not ProbeStore.valid({"schema": 1, "taps": "1", "active_seconds": 0}), "string counter rejected")
	context.check(not ProbeStore.valid({"schema": 1, "taps": 1, "active_seconds": 0, "extra": true}), "unexpected checkpoint fields rejected")
	var invalid_directory: ProbeStore = ProbeStore.new(path + "/missing/file.json")
	context.check(invalid_directory.save_checkpoint(0, 0) != OK, "write failure reported honestly")

	var probe: MobileProbe = PROBE.instantiate() as MobileProbe
	probe.store = store
	tree.root.add_child(probe)
	probe.set_enabled(true)
	context.check(probe.taps == 5, "new probe instance restores saved taps")
	# A slow first frame can exhaust a wall timer while the resume guard skips it.
	# Observe multiple actual process frames before asserting progress.
	for frame: int in 4: await tree.process_frame
	context.check(probe.clock.active_seconds > 4.5, "actual process node advances while active")
	for cycle: int in 20:
		probe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		probe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		probe.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		var frozen: float = probe.clock.active_seconds
		await tree.process_frame
		await tree.process_frame
		context.check(tree.paused and probe.clock.active_seconds == frozen, "cycle %d freezes actual scene processing" % (cycle + 1))
		probe.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		context.check(tree.paused, "resume waits for focus in cycle %d" % (cycle + 1))
		probe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		probe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		context.check(not tree.paused, "cycle %d resumes" % (cycle + 1))
		await tree.process_frame
	context.check(probe.pause_count == 20 and probe.resume_count == 20, "duplicate notifications counted once over 20 cycles")
	context.check(probe.paused_drift_count == 0, "20 synthetic cycles record no paused clock drift")
	context.check(tree.get_nodes_in_group("m1_probe").size() == 1, "lifecycle transitions retain one probe instance")
	(probe.get_node("SafeMargin/Column/Pause") as Button).pressed.emit()
	context.check(tree.paused, "manual pause suspends tree")
	probe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	probe.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	context.check(tree.paused, "focus regain preserves manual pause")
	(probe.get_node("SafeMargin/Column/Pause") as Button).pressed.emit()
	var before_tap: int = probe.taps
	(probe.get_node("SafeMargin/Column/Tap") as Button).pressed.emit()
	context.check(probe.taps == before_tap + 1 and store.load_checkpoint().taps == probe.taps, "one button activation commits exactly one tap")
	probe.queue_free()
	await tree.process_frame
	context.check(not tree.paused, "probe removal releases pause ownership")
	var replacement: MobileProbe = PROBE.instantiate() as MobileProbe
	replacement.store = ProbeStore.new(path)
	tree.root.add_child(replacement)
	context.check(replacement.taps == before_tap + 1, "replacement instance restores committed tap")
	replacement.queue_free()
	await tree.process_frame
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
	return true
