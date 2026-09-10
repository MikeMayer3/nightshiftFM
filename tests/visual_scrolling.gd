extends SceneTree
var t: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(450, 800); root.content_scale_size = Vector2i(720, 1280)
	var completed: bool = await preload("res://tests/integration/test_page_scroll.gd").new().run(t, self)
	t.check(completed, "scroll gesture suite completes")
	if "--gestures-only" in OS.get_cmdline_user_args():
		print("RESULT: %d gesture checks; %d failures" % [t.checks,t.failures])
		quit(0 if t.failures == 0 else 1); return
	var pages: RefCounted = preload("res://tests/scroll_pages.gd").new()
	t.check(await pages.run(t,self), "production page sweep completes")
	DirAccess.make_dir_recursive_absolute("res://docs/evidence/scrolling/")
	FileAccess.open("res://docs/evidence/scrolling/" + ("baseline.json" if pages.baseline else "native.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks":t.checks,"failures":t.failures,"pages":pages.rows}, "\t"))
	print("RESULT: %d scrolling checks; %d failures" % [t.checks, t.failures])
	quit(0 if t.failures == 0 else 1)
