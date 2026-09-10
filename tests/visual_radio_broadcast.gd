extends SceneTree
var t: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for size: Vector2i in [Vector2i(360,640),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size = size; root.content_scale_size = Vector2i(720,1280)
		var prefs: RadioPreferences = RadioPreferences.current
		prefs.values.large_text = true; prefs.values.sound = false; prefs.values.music = false
		prefs.values.low_effects = true; prefs.values.reduced_flash = true; prefs.coach_seen.clear()
		var boot: BootScreen = preload("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://p4_visual_%d.json" % Time.get_ticks_usec()
		root.add_child(boot); boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession = screen.session
		s.checkpoint_changed.disconnect(screen._save_checkpoint)
		screen._process(.1); await settle()
		var strip: BroadcastStrip = screen.broadcast_strip
		t.check(strip.visible and screen.broadcast.key == "P4_M1_W1", "new campaign opens with authored caption while muted")
		var strip_height: float = strip.size.y
		var arena_rect: Rect2 = screen.arena.get_global_rect()
		for key: String in ["P4_M1_W1","P4_M3_W7","P4_CALLER_WARNING","P4_CALLER_ARRIVED",""]:
			screen.broadcast.key = key; screen._refresh(); await settle()
			t.check(strip.size.y == strip_height and screen.arena.get_global_rect() == arena_rect, "caption changes never move or shrink the battlefield")
			t.check(strip.caption.get_minimum_size().y <= strip.caption.size.y and strip.caption.get_line_count() <= 3, "large captions fit without clipping")
		s.campaign.mission = 4; s.wave = 10; s.spawn_index = 12; s.spawn_time = 4
		s.actors.clear()
		screen.broadcast.attach(s); screen.broadcast.update(s)
		var actor: CombatActor = s.spawn_enemy(CombatContent.SWARMER,320); actor.position.y = 420
		screen._refresh(); await settle()
		t.check(strip.visible and screen.coach.visible, "warning and contextual shield help can coexist")
		t.check(not strip.get_global_rect().intersects(screen.arena.get_global_rect()), "caption sits entirely outside enemy field")
		t.check(not strip.get_global_rect().intersects(screen.shield_button.get_global_rect()), "caption never covers action controls")
		t.check(screen.shield_bar.get_global_rect().end.y <= screen.size.y and screen.arena.size.y >= 520, "large-text controls and meaningful battlefield fit at all tested sizes")
		capture("caller-warning",size)
		var before: float = screen.broadcast.left
		click_at(screen.pause_button.get_global_rect().get_center()); await settle()
		screen._process(5)
		t.check(s.paused and screen.broadcast.left == before, "real pause button freezes broadcast timing")
		click_at(screen.resume_button.get_global_rect().get_center()); await settle()
		t.check(not s.paused and screen.broadcast.left == before, "real resume button retains remaining caption time")
		screen.open_mixer(); await settle(); screen._process(5)
		t.check(s.paused and screen.patchboard_panel.visible and screen.broadcast.left == before, "Mixer freezes broadcasts beneath its modal")
		capture("mixer",size)
		screen.close_mixer(); await settle()
		s.phase = CombatSession.Phase.DRAFT; screen._refresh(); await settle()
		t.check(screen.draft_panel.visible and screen.draft_panel.get_index() > screen.get_node("Safe").get_index(), "upgrade choices render above broadcast and combat")
		s.phase = CombatSession.Phase.COMBAT
		prefs.values.sound = true; prefs.values.music = true
		var sound: RadioAudio = screen.radio_audio
		sound.set_process(false); sound.broadcast_cue("station"); sound._process(.01)
		t.check(sound.broadcast_player.playing and sound.music.volume_db == -6, "original sting starts and ducks station music")
		sound.cue(RadioAudio.TUNE)
		t.check(sound.effects.all(func(player: AudioStreamPlayer) -> bool: return not player.playing or player.stream != RadioAudio.TUNE), "routine tuning cue cannot overlap broadcast sting")
		sound.broadcast_cue("warning")
		t.check(sound.broadcast_player.stream == RadioAudio.STINGS.warning, "boss sting replaces ambient sting using one voice")
		screen._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED); sound._process(.01)
		t.check(sound.broadcast_player.stream_paused, "OS background pauses sting")
		screen._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED); sound._process(.01)
		t.check(not sound.broadcast_player.stream_paused, "OS foreground resumes sting")
		prefs.values.sound = false; prefs.changed.emit()
		t.check(not sound.broadcast_player.playing, "mute immediately stops sting")
		prefs.values.sound = true; prefs.changed.emit(); sound._process(.01)
		t.check(not sound.broadcast_player.playing, "unmute does not replay a consumed sting")
		sound.broadcast_cue("caller"); s.phase = CombatSession.Phase.DEFEAT; sound._process(.01)
		t.check(not sound.broadcast_player.playing, "results stop sting")
		boot.queue_free(); await process_frame
	print("RESULT: %d P4 native UI/audio checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func capture(label: String, size: Vector2i) -> void:
	var name: String = "%s-%dx%d.png" % [label,size.x,size.y]
	root.get_texture().get_image().save_png("res://docs/evidence/P4-radio/" + name)
func click_at(point: Vector2) -> void:
	for pressed: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		root.push_input(event,true)
