extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var t: TestContext=TestContext.new()
	var prefs: RadioPreferences=RadioPreferences.current
	prefs.values.sound=true; prefs.values.music=true
	var boot: BootScreen=preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path="user://p3_audio_%d.json"%Time.get_ticks_usec()
	root.add_child(boot);boot.show_page(BootScreen.Page.COMBAT)
	var screen: CombatScreen=boot.combat
	screen.set_process(false); screen.session.advance(.1)
	var sound: RadioAudio=screen.radio_audio
	sound.set_process(false);sound._process(.1);sound.cue(RadioAudio.SHIELD)
	await process_frame;await process_frame
	t.check(sound.music.playing and not sound.music.stream_paused,"native audio bed starts in live combat")
	t.check(sound.effects.any(func(player: AudioStreamPlayer) -> bool:return player.playing),"native effect voice starts while enabled")
	screen._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED);sound._process(.1)
	t.check(sound.music.stream_paused,"background pauses native music playback")
	t.check(sound.effects.all(func(player: AudioStreamPlayer) -> bool:return not player.playing or player.stream_paused),"background leaves no playing unpaused effect voices")
	screen._notification(MainLoop.NOTIFICATION_APPLICATION_RESUMED);sound._process(.1)
	t.check(not sound.music.stream_paused,"foreground releases music pause")
	prefs.values.sound=false;prefs.values.music=false;prefs.changed.emit()
	t.check(not sound.music.playing and sound.effects.all(func(player: AudioStreamPlayer) -> bool:return not player.playing),"muting stops active native voices")
	boot.queue_free();await process_frame
	print("RESULT: %d native audio lifecycle checks; %d failures"%[t.checks,t.failures])
	quit(0 if t.failures==0 else 1)
