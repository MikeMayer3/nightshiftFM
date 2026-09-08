extends SceneTree
## No plugins. Explicit suites, counters, and process exit codes, even in release mode.

const FOUNDATIONS: Script = preload("res://tests/unit/test_foundations.gd")
const BOOT_TEST: Script = preload("res://tests/integration/test_boot.gd")
const MOBILE_TEST: Script = preload("res://tests/integration/test_mobile_probe.gd")
const COMBAT_TEST: Script = preload("res://tests/unit/test_combat.gd")
const COMBAT_SCREEN_TEST: Script = preload("res://tests/integration/test_combat_screen.gd")
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
var _finished: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(15.0).timeout.connect(_timeout)
	if "--quit-smoke" in OS.get_cmdline_user_args():
		var boot: BootScreen = BOOT.instantiate() as BootScreen
		root.add_child(boot)
		await process_frame
		print("QUIT SMOKE: emitting the menu Quit button; expected process exit 0")
		(boot.menu.get_node("Quit") as Button).pressed.emit()
		await create_timer(0.5).timeout
		printerr("FAIL: Quit button did not terminate the process")
		quit(1)
		return
	var context: TestContext = TestContext.new()
	# A script error can abort a suite early; require an explicit completion value.
	var foundations_completed: Variant = FOUNDATIONS.new().run(context)
	context.check(foundations_completed == true, "foundation suite completed")
	var boot_completed: Variant = await BOOT_TEST.new().run(context, self)
	context.check(boot_completed == true, "boot suite completed")
	var mobile_completed: Variant = await MOBILE_TEST.new().run(context, self)
	context.check(mobile_completed == true, "mobile probe suite completed")
	context.check(COMBAT_TEST.new().run(context) == true, "combat unit suite completed")
	context.check(await COMBAT_SCREEN_TEST.new().run(context, self) == true, "combat screen suite completed")
	if "--intentional-failure" in OS.get_cmdline_user_args():
		context.check(false, "intentional failure proves nonzero exit")
	_finished = true
	print("RESULT: %d checks; %d failures" % [context.checks, context.failures])
	quit(0 if context.failures == 0 and context.checks > 0 else 1)

func _timeout() -> void:
	if not _finished:
		printerr("FAIL: test runner exceeded 15 seconds")
		quit(1)
