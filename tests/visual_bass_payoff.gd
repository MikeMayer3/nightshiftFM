extends SceneTree
var t: TestContext = TestContext.new()
const FIXTURE = preload("res://tests/p5_fixture.gd")
const DIR: String = "res://docs/evidence/P5-payoff/"
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(DIR + name + ".png")
func open_saved(snapshot: Dictionary) -> BootScreen:
	var path: String = "user://p5_native_%d.json" % Time.get_ticks_usec()
	var profile: MissionProfile = MissionProfile.new(); profile.enable_m4(); profile.next_run = 2
	t.check(MissionStore.new(path).save(profile, snapshot) == OK, "write real isolated mission envelope")
	var boot: BootScreen = preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = path; root.add_child(boot)
	boot.continue_button.pressed.emit()
	boot.combat.set_process(false); boot.combat.arena.set_process(false); boot.combat.radio_audio.set_process(false)
	return boot
func run() -> void:
	var fixture: Dictionary = FIXTURE.prepare()
	t.check(not fixture.is_empty(), "legal campaign fixture prepared")
	if fixture.is_empty(): quit(1); return
	for size: Vector2i in [Vector2i(360,640), Vector2i(450,1000), Vector2i(1024,768)]:
		root.size = size; root.content_scale_size = Vector2i(720,1280)
		var prefs: RadioPreferences = RadioPreferences.current
		prefs.coach_seen.assign(RadioPreferences.COACH_IDS)
		prefs.values.large_text = true
		var boot: BootScreen = open_saved(fixture.decision)
		var screen: CombatScreen = boot.combat
		var s: CombatSession = screen.session
		t.check(not screen.save_failed and not screen.recovery_required and s.is_deciding(), "production Continue restores pending Wideband choice")
		screen._refresh(); await capture("choice-%dx%d" % [size.x,size.y])
		var index: int = s.draft.offers.find(BassPayoff.BRANCH)
		t.check(index >= 0 and not BassPayoff.active(s), "unaccepted offer does not change hardware")
		if index < 0: quit(1); return
		screen.draft_panel.cards[index].pressed.emit(); screen._refresh()
		t.check(BassPayoff.active(s) and not screen.save_failed, "real card equips and saves Wideband")
		var disk: Dictionary = screen.store.load_save()
		t.check(MissionStore.valid(disk), "accepted choice remains a valid production save")
		for mode: String in ["normal", "mute", "low"]:
			prefs.values.sound = mode == "normal"; prefs.values.music = mode == "normal"
			prefs.values.low_effects = mode == "low"; prefs.values.reduced_flash = mode == "low"
			prefs.changed.emit()
			# Advance actual combat until an actual Bass shot; no staged hit geometry.
			for step: int in 1200:
				if s.is_deciding(): s.choose_upgrade(FIXTURE.choice(s))
				if s.run.shield.current < 20: s.activate_shield()
				screen.arena._process(CombatSession.STEP); screen._process(CombatSession.STEP)
				if screen.arena.pulses.any(func(p: Dictionary) -> bool: return p.source == &"bass_driver" and float(p.left) <= .35 and float(p.left) >= .2): break
			t.check(screen.arena.pulses.any(func(p: Dictionary) -> bool: return p.get("wideband",false)), "real Wideband shot retains twin-front presentation in " + mode)
			screen.arena.queue_redraw(); await capture("wideband-%s-%dx%d" % [mode,size.x,size.y])
			t.check(screen.shield_bar.get_global_rect().end.y <= screen.size.y, "large text controls fit")
			t.check(BassPayoff.texture(s) == BassPayoff.CABINET, "cabinet remains recognizable without sound/effects")
		# Start from the accepted disk save again, then exercise the real audio node.
		boot.queue_free(); await process_frame
		boot = open_saved(disk.run); screen = boot.combat; s = screen.session
		var sound: RadioAudio = screen.radio_audio
		prefs.values.sound = true; prefs.values.music = true; prefs.changed.emit()
		sound._process(.01)
		t.check(BassPayoff.active(s) and sound.build_layer.playing, "actual Continue restores cabinet and music layer")
		await create_timer(.15).timeout
		var position: float = sound.build_layer.get_playback_position()
		var voice: int = sound.build_layer.get_instance_id()
		for tick: int in 100: sound._process(.01)
		t.check(sound.build_layer.get_instance_id() == voice and sound.get_child_count() == 7, "repeated refresh uses exactly one build music voice")
		t.check(position > 0 and sound.build_layer.get_playback_position() >= position, "refresh does not restart the musical phrase")
		screen.pause_button.pressed.emit(); sound._process(.01)
		t.check(sound.build_layer.stream_paused, "Pause freezes build music")
		screen.resume_button.pressed.emit(); sound._process(.01)
		t.check(not sound.build_layer.stream_paused, "Resume unfreezes build music")
		screen.open_mixer(); sound._process(.01)
		t.check(sound.build_layer.stream_paused, "Mixer freezes build music")
		screen.close_mixer(); sound._process(.01)
		screen._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED); sound._process(.01)
		t.check(sound.build_layer.stream_paused, "OS background freezes build music")
		screen._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED); sound._process(.01)
		t.check(not sound.build_layer.stream_paused, "OS foreground restores build music")
		sound.broadcast_cue("warning"); sound._process(.01)
		t.check(sound.build_layer.volume_db == -18 and sound.music.volume_db == -6, "boss sting ducks both music voices")
		prefs.values.music = false; prefs.changed.emit()
		t.check(not sound.build_layer.playing and not sound.music.playing, "music off immediately stops both voices")
		prefs.values.music = true; prefs.values.sound = false; prefs.changed.emit(); sound._process(.01)
		t.check(sound.build_layer.playing and not sound.broadcast_player.playing, "music follows its own control while effects are muted")
		screen.pause_button.pressed.emit(); screen.restart_button.pressed.emit(); sound._process(.01)
		t.check(not BassPayoff.active(s) and not sound.build_layer.playing and screen.arena.pulses.is_empty(), "real Restart clears upgraded presentation and music")
		s.restore_checkpoint(fixture.after); sound._process(.01)
		s.phase = CombatSession.Phase.DRAFT; sound._process(.01)
		t.check(sound.build_layer.stream_paused, "upgrade decisions freeze music")
		s.phase = CombatSession.Phase.DEFEAT; sound._process(.01)
		t.check(not sound.build_layer.playing, "results stop build music")
		boot.queue_free(); await process_frame
	FileAccess.open(DIR + "native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":t.checks,"failures":t.failures,"scope":"desktop native UI/audio and actual isolated save/Continue/Restart; human and phone acceptance NOT RUN"},"\t"))
	print("RESULT: %d P5 native checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)
