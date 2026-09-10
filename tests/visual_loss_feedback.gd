extends SceneTree
## Native rendered/input fixtures; these are not unfamiliar-player sessions.
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640),Vector2i(450,950),Vector2i(1024,768)]:
		root.size=dimensions; root.content_scale_size=Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path="user://p2_visual_%d.json" % Time.get_ticks_usec()
		root.add_child(boot)
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen=boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession=screen.session
		s.checkpoint_changed.disconnect(screen._save_checkpoint)
		s.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
		s.advance(.1)
		s.arsenal.report.add(&"main",&"damage",240)
		s.arsenal.report.add(&"arc_aerial",&"damage",80)
		s.hit_station(90,&"COMBAT_PROJECTILE",&"COMBAT_PROJECTILE_HIT")
		s.breaches = 3
		s.hit_station(300,&"M2_SWARMER_NAME")
		screen._refresh()
		RadioPreferences.current.values.large_text=true
		RadioPreferences.current.apply_fonts(screen)
		await settle()
		capture("defeat",dimensions)
		checks.check(screen.details.text.contains(TranslationServer.translate(&"P2_LOSS_BREACH")),"defeat shows evidence-based reason")
		checks.check(screen.restart_button.get_global_rect().end.y<=screen.size.y,"retry fits viewport with large text")
		click_at(screen.report_button.get_global_rect().get_center())
		await settle()
		RadioPreferences.current.apply_fonts(screen.draft_panel)
		await settle()
		capture("report",dimensions)
		checks.check(screen.report_open and screen.draft_panel.visible,"real report button opens breakdown")
		var scroll: ScrollContainer = screen.draft_panel.column.get_parent()
		checks.check(scroll.get_h_scroll_bar().max_value<=scroll.size.x+1,"graphical report fits width")
		checks.check(screen.draft_panel.column.find_children("*","ProgressBar",true,false).size()>=6,"report displays damage and equipment bars")
		scroll.scroll_vertical = 390
		await settle()
		capture("equipment",dimensions)
		scroll.scroll_vertical = 0
		await settle()
		var back: Button = screen.draft_panel.column.get_child(1)
		click_at(back.get_global_rect().get_center())
		await settle()
		checks.check(not screen.report_open,"back at top returns without scrolling")
		click_at(screen.restart_button.get_global_rect().get_center())
		await settle()
		checks.check(not s.is_finished() and s.hull==s.maximum_hull(),"one tap retry starts fresh run")
		checks.check(s.achievement_run.hull_damage==0 and s.supports.overshield==0 and s.ability_left==0 and not s.focus_active,"retry clears damage history and temporary effects")
		checks.check(not screen.report_open and not screen.mixer_open,"retry closes report and mixer")
		RadioPreferences.current.values.large_text=false
		boot.queue_free(); await process_frame
	print("RESULT: %d rendered loss checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures==0 else 1)
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func capture(label: String, dimensions: Vector2i) -> void:
	var file_name: String = "%s-%dx%d.png" % [label,dimensions.x,dimensions.y]
	root.get_texture().get_image().save_png("res://docs/evidence/P2-losses/"+file_name)
func click_at(point: Vector2) -> void:
	for down: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true)
