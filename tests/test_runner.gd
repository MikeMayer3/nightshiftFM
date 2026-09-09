extends SceneTree
## No plugins. Explicit suites, counters, and process exit codes, even in release mode.

const PATCHBOARD_TEST: Script = preload("res://tests/unit/test_patchboard.gd")
const ARSENAL_SCREEN: Script = preload("res://tests/integration/test_arsenal_screen.gd")
const ARSENAL_TEST: Script = preload("res://tests/unit/test_arsenal.gd")
const FOUNDATIONS: Script = preload("res://tests/unit/test_foundations.gd")
const BOOT_TEST: Script = preload("res://tests/integration/test_boot.gd")
const MOBILE_TEST: Script = preload("res://tests/integration/test_mobile_probe.gd")
const COMBAT_TEST: Script = preload("res://tests/unit/test_combat.gd")
const COMBAT_SCREEN_TEST: Script = preload("res://tests/integration/test_combat_screen.gd")
const M3_SCREEN_TEST: Script = preload("res://tests/integration/test_m3_screen.gd")
const M4_SCREEN_TEST: Script = preload("res://tests/integration/test_m4_screen.gd")
const SIGNAL_SCREEN_TEST: Script = preload("res://tests/integration/test_signal_screen.gd")
const ACTIVE_SCREEN: Script = preload("res://tests/integration/test_active_screen.gd")
const ACTIVE_TEST: Script = preload("res://tests/unit/test_active.gd")
const SIGNAL_TEST: Script = preload("res://tests/unit/test_signal.gd")
const M4_TEST: Script = preload("res://tests/unit/test_m4.gd")
const M3_TEST: Script = preload("res://tests/unit/test_m3.gd")
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
var _finished: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	create_timer(45.0).timeout.connect(_timeout)
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
	context.check(M3_TEST.new().run(context) == true, "M3 suite completed")
	context.check(await M3_SCREEN_TEST.new().run(context, self) == true, "M3 screen suite completed")
	context.check(M4_TEST.new().run(context) == true, "M4 suite completed")
	context.check(await M4_SCREEN_TEST.new().run(context, self) == true, "M4 screen suite completed")
	context.check(SIGNAL_TEST.new().run(context) == true, "signal suite completed")
	context.check(await SIGNAL_SCREEN_TEST.new().run(context, self) == true, "signal screen suite completed")
	context.check(ACTIVE_TEST.new().run(context) == true, "active combat suite completed")
	context.check(await ACTIVE_SCREEN.new().run(context, self) == true, "active screen suite completed")
	context.check(await ARSENAL_SCREEN.new().run(context, self) == true, "M5 screen suite completed")
	context.check(ARSENAL_TEST.new().run(context) == true, "M5 arsenal suite completed")
	context.check(PATCHBOARD_TEST.new().run(context) == true, "M6 patchboard selection suite completed")
	if "--intentional-failure" in OS.get_cmdline_user_args():
		context.check(false, "intentional failure proves nonzero exit")
	_finished = true
	print("RESULT: %d checks; %d failures" % [context.checks, context.failures])
	quit(0 if context.failures == 0 and context.checks > 0 else 1)

func _timeout() -> void:
	if not _finished:
		printerr("FAIL: test runner exceeded 45 seconds")
		quit(1)
