extends SceneTree
var screen: CombatScreen
func _initialize() -> void:
	_run.call_deferred()
func capture(name: String) -> void:
	screen._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M4-active/"+name+".png")
func _run() -> void:
	screen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.store = MissionStore.new("user://active_visual_fixture.json")
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.session.start_active(42, &"run.1")
	screen.session.advance(2.4)
	screen.arena._process(1)
	await capture("desktop-field")
	var point: Vector2 = screen.session.actors[2].position
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = point * screen.arena.arena_stretch()
	screen.arena._gui_input(press)
	await capture("desktop-aim")
	press.pressed = false
	press.position = screen.arena.get_global_transform_with_canvas() * (point * screen.arena.arena_stretch())
	screen.arena._input(press)
	await capture("desktop-burst")
	root.size = Vector2i(360,640)
	await capture("desktop-small-field")
	root.size = Vector2i(450,950)
	await capture("desktop-tall-field")
	print("PASS: expanded field/aim/burst at standard, small and tall sizes; bursts=",screen.session.active_combat.uses," save_failed=",screen.save_failed)
	quit(0 if screen.session.active_combat.uses==1 and not screen.save_failed else 1)
