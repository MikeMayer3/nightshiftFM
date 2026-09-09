extends RefCounted
## Dispatch native events through the viewport: direct mouse callbacks missed Android.
func run(context: TestContext, tree: SceneTree) -> bool:
	var screen: CombatScreen = load("res://scenes/combat/combat.tscn").instantiate()
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.store = MissionStore.new("user://touch_aim_test.json")
	tree.root.add_child(screen)
	await tree.process_frame
	await tree.process_frame
	screen.set_process(false)
	screen.session.advance(2.4)
	screen._refresh()
	await tree.process_frame
	var arena: CombatArena = screen.arena
	var world: Vector2 = screen.session.actors[2].position
	var target: Vector2 = arena.get_global_transform_with_canvas() * (arena.arena_offset() + world * arena.arena_stretch())
	var start: Vector2 = arena.get_global_rect().get_center()
	touch(tree, start, true, 2)
	context.check(screen.session.focus_active, "native touch down acquires battlefield aim through viewport")
	drag(tree, target, 2)
	context.check(screen.session.focus_point.is_equal_approx(world), "native drag maps viewport position to simulation aim")
	touch(tree, start, true, 3)
	drag(tree, start, 3)
	touch(tree, start, false, 3)
	context.check(screen.session.focus_active and screen.session.focus_point.is_equal_approx(world) and screen.session.active_combat.uses == 0, "second finger cannot steal aim or release the first finger's Burst")
	mouse(tree, start, true, InputEvent.DEVICE_ID_EMULATION)
	mouse(tree, start, false, InputEvent.DEVICE_ID_EMULATION)
	context.check(screen.session.focus_active and screen.session.focus_point.is_equal_approx(world) and screen.session.active_combat.uses == 0, "emulated mouse events do not duplicate or cancel native touch")
	touch(tree, target, false, 2)
	context.check(screen.session.active_combat.uses == 1 and screen.session.kills == 5 and not screen.session.focus_active, "native release fires exactly one Burst at the dragged formation")
	touch(tree, target, true, 0)
	touch(tree, target, false, 0)
	context.check(screen.session.active_combat.uses == 1, "touch cannot bypass Burst cooldown")
	screen.session.advance(6)
	world = screen.session.target().position
	target = arena.get_global_transform_with_canvas() * (world * arena.arena_stretch())
	touch(tree, target, true, 0)
	touch(tree, target, false, 0, true)
	context.check(not screen.session.focus_active and screen.session.active_combat.uses == 1, "Android canceled touch clears aim without firing")
	touch(tree, target, true, 0)
	drag(tree, Vector2(-20, -20), 0)
	touch(tree, Vector2(-20, -20), false, 0)
	context.check(not screen.session.focus_active and screen.session.active_combat.uses == 1, "release outside battlefield cancels native aim")
	touch(tree, target, true, 0)
	screen.toggle_pause()
	touch(tree, target, false, 0)
	screen.toggle_pause()
	drag(tree, target, 0)
	touch(tree, target, false, 0)
	context.check(not screen.session.focus_active and screen.session.active_combat.uses == 1, "pause clears touch ownership and stale release cannot fire")
	var overlay: Control = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(overlay)
	touch(tree, target, true, 0)
	touch(tree, target, false, 0)
	context.check(not screen.session.focus_active and screen.session.active_combat.uses == 1, "overlay intercepts new touches before arena acquisition")
	overlay.queue_free()
	await tree.process_frame
	mouse(tree, target, true)
	mouse(tree, target, false)
	context.check(screen.session.active_combat.uses == 2 and not screen.session.focus_active, "physical mouse still aims and releases through viewport")
	# A new formation keeps the button gesture test independent of prior kills.
	screen.session.start_active(42, &"run.1")
	screen.session.advance(2.4)
	screen._refresh()
	await tree.process_frame
	world = screen.session.actors[2].position
	target = arena.get_global_transform_with_canvas() * (world * arena.arena_stretch())
	var button: Vector2 = screen.ability_button.get_global_rect().get_center()
	mouse(tree, button, true, InputEvent.DEVICE_ID_EMULATION)
	touch(tree, button, true, 0)
	drag(tree, target, 0)
	context.check(screen.session.focus_active and screen.session.focus_point.is_equal_approx(world), "drag starting on Burst button aims onto the battlefield")
	mouse(tree, target, false, InputEvent.DEVICE_ID_EMULATION)
	touch(tree, target, false, 0)
	context.check(screen.session.active_combat.uses == 1 and screen.session.kills == 5 and not screen.session.focus_active, "release from Burst button drag fires once at chosen group")
	screen.session.advance(6)
	screen._refresh()
	await tree.process_frame
	touch(tree, button, true, 0)
	drag(tree, target, 0)
	drag(tree, button, 0)
	touch(tree, button, false, 0)
	mouse(tree, button, false, InputEvent.DEVICE_ID_EMULATION)
	context.check(screen.session.active_combat.uses == 1 and not screen.session.focus_active, "drag back onto Burst button cancels without automatic fallback")
	await tree.process_frame
	mouse(tree, button, true, InputEvent.DEVICE_ID_EMULATION)
	touch(tree, button, true, 0)
	mouse(tree, button, false, InputEvent.DEVICE_ID_EMULATION)
	touch(tree, button, false, 0)
	context.check(screen.session.active_combat.uses == 2, "simple Burst button tap retains automatic target with mouse bridge arriving first")
	screen.queue_free()
	await tree.process_frame
	return true

func touch(tree: SceneTree, point: Vector2, pressed: bool, index: int, canceled: bool = false) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.position = point
	event.pressed = pressed
	event.index = index
	event.canceled = canceled
	tree.root.push_input(event, true)

func drag(tree: SceneTree, point: Vector2, index: int) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.position = point
	event.index = index
	tree.root.push_input(event, true)

func mouse(tree: SceneTree, point: Vector2, pressed: bool, device: int = 0) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = pressed
	event.device = device
	tree.root.push_input(event, true)
