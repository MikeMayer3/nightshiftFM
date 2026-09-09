extends SceneTree
const SUITE: Script = preload("res://tests/unit/test_radio_presentation.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var context: TestContext = TestContext.new()
	context.check(await SUITE.new().run(context, self) == true, "M10 targeted suite completed")
	print("RESULT: %d checks; %d failures" % [context.checks, context.failures])
	quit(0 if context.failures == 0 else 1)
