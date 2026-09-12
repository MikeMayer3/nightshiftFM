extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var t: TestContext=TestContext.new()
	await preload("res://tests/integration/test_boot.gd").new().run(t,self)
	print("RESULT: %d navigation checks; %d failures"%[t.checks,t.failures])
	quit(0 if t.failures==0 else 1)
