extends SceneTree
## Real shield activation/absorption/expiry in an isolated production-screen fixture.
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func capture(screen: CombatScreen, name: String) -> void:
	screen._refresh(); screen.arena.queue_redraw()
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10-shield-boost/"+name+".png")
	checks.check(screen.shield_bar.get_global_rect().encloses(screen.shield_caption.get_global_rect()),"boost label fits inside shield meter")
	checks.check(screen.shield_bar.get_global_rect().end.y <= root.get_visible_rect().size.y,"boost meter stays on screen")
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640),Vector2i(450,950),Vector2i(1024,768)]:
		root.size = dimensions; root.content_scale_size = Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://shield_boost_visual.json"; root.add_child(boot)
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		var s: CombatSession = screen.session
		screen.set_process(false); screen.arena.set_process(false)
		s.advance(.1)
		RadioPreferences.current.values.large_text = true
		RadioPreferences.current.apply_fonts(screen)
		var suffix: String = "-%dx%d" % [dimensions.x,dimensions.y]
		await capture(screen,"ready"+suffix)
		checks.check(screen.shield_button.text == screen.tr("POLISH_BOOST_READY"),"ready button names the boost")
		screen.shield_button.pressed.emit()
		await capture(screen,"boosted"+suffix)
		checks.check(screen.boost_visible and s.supports.overshield == 20 and screen.boost_duration_bar.visible,"real button activation exposes the actual temporary reserve")
		checks.check(screen.shield_button.text == screen.tr("POLISH_BOOST_ACTIVE") % 3,"active button shows remaining boost time instead of cooldown")
		var normal_shield: float = s.run.shield.current
		s.hit_station(10,s.actors[0].name_key)
		await capture(screen,"absorbed"+suffix)
		checks.check(s.run.shield.current == normal_shield and RadioShieldVisual.reserve(s) < 20,"incoming damage consumes the visible bonus before normal shield")
		var checkpoint: Dictionary = s.to_checkpoint()
		var copy: CombatSession = CombatSession.new()
		checks.check(copy.restore_checkpoint(JSON.parse_string(JSON.stringify(checkpoint))) and RadioShieldVisual.reserve(copy) == RadioShieldVisual.reserve(s),"checkpoint restore retains the same displayed protection")
		s.paused = true; var seconds: float = RadioShieldVisual.seconds_left(s)
		s.advance(1); screen.arena._process(1)
		checks.check(RadioShieldVisual.seconds_left(s) == seconds,"pause freezes boost duration")
		s.paused = false
		RadioPreferences.current.values.reduced_flash = true; RadioPreferences.current.values.low_effects = true
		await capture(screen,"reduced"+suffix)
		s.hit_station(100,s.actors[0].name_key)
		await capture(screen,"spent"+suffix)
		checks.check(not screen.boost_visible and not screen.boost_duration_bar.visible and not "TEMP" in screen.shield_caption.text,"depleted reserve immediately clears all boost indicators")
		screen.restart(); s.advance(.1); screen.shield_button.pressed.emit()
		s.advance(3.1)
		await capture(screen,"expired"+suffix)
		checks.check(not screen.boost_visible and RadioShieldVisual.reserve(s) == 0,"time expiry clears the boost without another press")
		RadioPreferences.current.values.large_text = false; RadioPreferences.current.values.reduced_flash = false; RadioPreferences.current.values.low_effects = false
		boot.queue_free(); await process_frame
	print("RESULT: %d shield boost rendered checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures == 0 else 1)
