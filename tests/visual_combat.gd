extends SceneTree
## Rendered desktop evidence, separate from human playtesting.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var scene: PackedScene = load("res://scenes/combat/combat.tscn") as PackedScene
	var screen: CombatScreen = scene.instantiate() as CombatScreen
	root.add_child(screen)
	await process_frame
	screen.session.advance(36.0)
	screen.toggle_pause()
	# Capture battlefield without overlay; simulation stays frozen for deterministic evidence.
	screen.overlay.hide()
	screen.set_process(false)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M2/desktop-combat.png")
	screen._refresh()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M2/desktop-paused.png")
	screen.manual_pause = false
	screen.session.paused = false
	screen.session.advance(180.0)
	screen._refresh()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M2/desktop-results.png")
	print("PASS: rendered combat, pause and results screenshots")
	quit()
