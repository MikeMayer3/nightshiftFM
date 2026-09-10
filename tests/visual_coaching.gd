extends SceneTree
var t: TestContext=TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for size: Vector2i in [Vector2i(360,640),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size=size; root.content_scale_size=Vector2i(720,1280)
		var prefs: RadioPreferences=RadioPreferences.current
		prefs.values.large_text=true; prefs.values.sound=false; prefs.values.music=false
		prefs.values.low_effects=true; prefs.values.reduced_flash=true; prefs.coach_seen.clear()
		var boot: BootScreen=preload("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path="user://p3_visual_%d.json"%Time.get_ticks_usec()
		root.add_child(boot); boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen=boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession=screen.session
		s.checkpoint_changed.disconnect(screen._save_checkpoint)
		s.advance(.1)
		var actor: CombatActor=CombatActor.from_definition(CombatContent.SWARMER,999,Vector2(320,420))
		s.actors.append(actor)
		var before: Dictionary=s.to_checkpoint()
		screen._refresh(); await settle()
		t.check(screen.coach.visible and screen.coach.current_hint=="shield","contextual shield hint appears beside live controls")
		t.check(s.to_checkpoint()==before,"coaching does not alter combat, RNG or checkpoint")
		t.check(not screen.coach.get_global_rect().intersects(screen.arena.get_global_rect()),"hint is outside battlefield")
		t.check(screen.shield_bar.get_global_rect().end.y<=screen.size.y,"large-text coaching and meters fit viewport")
		capture("shield-hint",size)
		click_at(screen.shield_button.get_global_rect().get_center()); await settle()
		t.check(screen.coach.current_hint=="boost" and screen.boost_visible,"actual shield tap teaches the real visible reserve")
		capture("boost-hint",size)
		click_at(screen.coach.dismiss.get_global_rect().get_center()); await settle()
		t.check(not screen.coach.visible,"dismiss removes hint without pausing combat")
		screen._refresh(); await settle()
		t.check(not screen.coach.visible,"dismissed hint does not reappear")
		s.draft.normal_count=1; screen._refresh(); await settle()
		t.check(screen.coach.current_hint=="mixer","mixer guidance begins after equipment choice")
		capture("mixer-hint",size)
		click_at(screen.mixer_button.get_global_rect().get_center()); await settle()
		t.check(screen.mixer_open and s.paused and not screen.coach.visible,"real mixer tap pauses fight and hides coaching")
		screen.close_mixer(); await settle()
		for left: bool in [true,false]:
			prefs.values.left_handed=left; prefs.changed.emit(); await settle()
			t.check((screen.shield_button.position.x<screen.mixer_button.position.x)==left,"handedness moves the visible shield control")
		screen._open_settings(); await settle()
		var settings: RadioSettingsPanel=screen.settings_panel
		t.check(settings.toggles.has("left_handed"),"handedness exposed in settings")
		var replay: Button=settings.find_child("ReplayHints",true,false)
		replay.get_parent().show(); await settle()
		var scroll: ScrollContainer=settings.column.get_parent()
		scroll.ensure_control_visible(replay); await settle()
		click_at(replay.get_global_rect().get_center()); await settle()
		t.check(prefs.coach_seen.is_empty(),"real Help replay control resets coaching")
		t.check(not prefs.enabled("sound") and prefs.enabled("low_effects"),"replay preserves accessibility options")
		settings.back_requested.emit(); screen.toggle_pause(); await settle()
		t.check(screen.coach.visible,"replayed coaching resumes when context is relevant")
		prefs.remember_coach("shield"); prefs.remember_coach("boost"); prefs.remember_coach("mixer")
		screen.restart(); screen.set_process(false); s.advance(.1); s.actors.append(actor)
		screen._refresh(); await settle()
		t.check(not screen.coach.visible,"new run does not repeat previously shown coaching")
		var elapsed: float=s.elapsed
		screen._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
		screen._process(5)
		t.check(s.elapsed==elapsed and s.paused,"background freezes simulation")
		screen._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED)
		screen._process(5)
		t.check(s.elapsed==elapsed,"resume discards interruption delta")
		boot.queue_free(); await process_frame
	print("RESULT: %d coaching input/layout checks; %d failures"%[t.checks,t.failures])
	quit(0 if t.failures==0 else 1)
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func capture(label: String,size: Vector2i) -> void:
	var name: String="%s-%dx%d.png"%[label,size.x,size.y]
	root.get_texture().get_image().save_png("res://docs/evidence/P3-onboarding/"+name)
func click_at(point: Vector2) -> void:
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton=InputEventMouseButton.new()
		event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=pressed
		root.push_input(event,true)
