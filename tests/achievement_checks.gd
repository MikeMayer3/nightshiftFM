extends SceneTree
func _initialize() -> void:
 var checks: TestContext = TestContext.new()
 checks.check(preload("res://tests/unit/test_achievements.gd").new().run(checks) == true, "M9 suite completed")
 print("RESULT: %d checks; %d failures" % [checks.checks, checks.failures])
 quit(0 if checks.failures == 0 else 1)
