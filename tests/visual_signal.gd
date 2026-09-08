extends SceneTree
## Actual scene rendering with its own save file; never opens player data.
var screen: CombatScreen
func _initialize() -> void:
	_run.call_deferred()
func capture(name: String) -> void:
	screen._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M4-signal/" + name + ".png")
func _run() -> void:
	screen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.signal_enabled = true
	screen.store = MissionStore.new("user://signal_visual_fixture.json")
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.session.start_signal(42, &"run.1")
	screen.session.advance(6)
	await capture("desktop-meter")
	screen.session.advance(30)
	await capture("desktop-choice")
	screen.draft_panel.info_buttons[0].pressed.emit()
	await capture("desktop-new-weapon-details")
	screen.draft_panel.show_draft(screen.session)
	root.size = Vector2i(360, 640)
	await capture("desktop-small-choice")
	screen.draft_panel.cards[0].pressed.emit()
	screen.session.advance(3)
	await capture("desktop-small-meter")
	print("PASS: signal meter, choice, new weapon details, and 360x640 combat rendered; save_failed=", screen.save_failed)
	quit(1 if screen.save_failed else 0)
