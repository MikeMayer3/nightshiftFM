extends RefCounted
const PREFS: Script = preload("res://scripts/ui/radio_preferences.gd")
const FIXTURE: Script = preload("res://tests/unit/test_arsenal.gd")
const COMBAT: PackedScene = preload("res://scenes/combat/combat.tscn")

func run(t: TestContext, tree: SceneTree) -> bool:
	var original: Dictionary = RadioPreferences.current.values.duplicate()
	var prefs: Node = PREFS.new()
	prefs.path = "user://m10_unit_preferences.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(prefs.path + suffix): DirAccess.remove_absolute(prefs.path + suffix)
	prefs.values.large_text = true
	t.check(prefs.save_preferences() == OK, "M10 settings save separately from mission data")
	prefs.values.left_handed = true
	t.check(prefs.save_preferences() == OK, "M10 preferences rotate a validated backup")
	prefs.values = prefs.DEFAULTS.duplicate()
	prefs.load_preferences()
	t.check(prefs.enabled("large_text") and prefs.enabled("left_handed"), "M10 settings survive reload")
	FileAccess.open(prefs.path, FileAccess.WRITE).store_string("{truncated")
	prefs.load_preferences()
	t.check(prefs.enabled("large_text") and not prefs.enabled("left_handed"), "M10 corrupt preference primary recovers last valid backup")
	var invalid: Dictionary = {"schema": 1, "options": prefs.DEFAULTS.duplicate()}
	invalid.options.large_text = "yes"
	t.check(not PREFS.valid(invalid), "M10 rejects wrong preference types")
	prefs.free()
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 28)
	tree.root.add_child(label)
	RadioPreferences.current.values.large_text = true
	RadioPreferences.current.apply_fonts(label)
	RadioPreferences.current.apply_fonts(label)
	t.check(label.get_theme_font_size("font_size") == 32, "M10 large font scaling is idempotent")
	RadioPreferences.current.values.large_text = false
	RadioPreferences.current.apply_fonts(label)
	t.check(label.get_theme_font_size("font_size") == 28, "M10 restores the original font size exactly")
	label.queue_free()
	var a: CombatSession = FIXTURE.new().fixture()
	var b: CombatSession = FIXTURE.new().fixture()
	var arena: CombatArena = CombatArena.new()
	arena.session = b
	tree.root.add_child(arena)
	for tick: int in 120:
		a.advance(CombatSession.STEP)
		RadioPreferences.current.values.low_effects = true
		RadioPreferences.current.values.reduced_flash = true
		b.advance(CombatSession.STEP)
		arena._process(CombatSession.STEP)
	t.check(SignalSnapshot.capture(a) == SignalSnapshot.capture(b), "M10 reduced visuals do not change combat, RNG or checkpoints")
	for era_index: int in 3:
		for actor: CombatActor in b.actors:
			t.check(RadioArt.enemy(actor, era_index) != null, "M10 role texture exists for era %d" % era_index)
	arena.queue_free()
	var effects: CombatArena = CombatArena.new()
	effects.session = b
	tree.root.add_child(effects)
	effects.set_process(false)
	effects.show_chain(PackedVector2Array([Vector2(320,680), Vector2(320,300)]), false)
	effects.show_support(&"bass_driver", Vector2(320,300), Vector2(90,90))
	var actor: CombatActor = b.spawn_enemy(CombatContent.SWARMER, 320)
	var event: CombatEvent = CombatEvent.new(1, 1, &"main", CombatEvent.Kind.KILL, actor.serial, 1)
	for index: int in 40: effects.show_event(event)
	t.check(effects.fragments.size() == 32, "kill fragments remain bounded during dense fights")
	var visual_before: Array = [effects.chains.duplicate(true), effects.pulses.duplicate(true), effects.fragments.duplicate(true), effects.waveform_time]
	var phase_before: CombatSession.Phase = b.phase
	for stopped_phase: CombatSession.Phase in [CombatSession.Phase.COMBAT, CombatSession.Phase.DRAFT, CombatSession.Phase.RECRUIT]:
		b.phase = stopped_phase
		b.paused = stopped_phase == CombatSession.Phase.COMBAT
		effects._process(.5)
		t.check(visual_before == [effects.chains, effects.pulses, effects.fragments, effects.waveform_time], "pause and upgrade choices freeze every transient combat effect")
	b.paused = false; b.phase = CombatSession.Phase.COMBAT
	var snapshot: Dictionary = SignalSnapshot.capture(b)
	effects._process(.6)
	t.check(effects.chains.is_empty() and effects.pulses.is_empty() and effects.fragments.is_empty(), "combat effects expire after play resumes")
	t.check(SignalSnapshot.capture(b) == snapshot, "visual fragments and animation never mutate gameplay or RNG")
	b.phase = phase_before
	effects.queue_free()
	var screen: CombatScreen = COMBAT.instantiate()
	screen.m3_enabled = true
	screen.arsenal_enabled = true
	screen.active_enabled = true
	screen.store = MissionStore.new("user://m10_unit_combat.json")
	tree.root.add_child(screen)
	await tree.process_frame
	screen.set_process(false)
	t.check(screen.session.chain_fired.is_connected(screen.radio_audio.chain), "actual arsenal attacks reach the bounded shot audio cue")
	t.check(screen.session.combat_event.is_connected(screen.arena.show_event), "actual kills reach the visual fragment effect")
	t.check(not screen.ability_button.visible, "M10 cooldown attack removed from the combat UI")
	var radio: CombatSession = CombatSession.new()
	radio.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, {"mission": 1, "cleared": 0, "modules": ["hot_tubes", "heavy_battery"]})
	radio.advance(2.4)
	t.check(radio.active_combat.automatic_radio and not radio.active_combat.burst(radio, Vector2(320, 300)), "new campaign uses automatic combat and rejects Burst calls")
	var copy: CombatSession = CombatSession.new()
	t.check(copy.restore_checkpoint(JSON.parse_string(JSON.stringify(radio.to_checkpoint()))) and copy.active_combat.automatic_radio, "automatic combat rules survive a JSON checkpoint")
	var legacy_data: Dictionary = radio.to_checkpoint()
	legacy_data.active.erase("automatic_radio")
	var legacy: CombatSession = CombatSession.new()
	t.check(legacy.restore_checkpoint(legacy_data) and not legacy.active_combat.automatic_radio, "older checkpoints retain their recorded combat rules")
	var malformed: Dictionary = radio.active_combat.to_data()
	malformed.automatic_radio = "true"
	t.check(not ActiveCombat.new().restore(malformed), "automatic rules marker rejects non-boolean values")
	for count: int in range(1, 6):
		screen.session.draft.catalog = ArsenalContent.tracks(ArsenalContent.DEFAULT)
		if count > 1: screen.session.draft.equip(ArsenalContent.FAMILIES[count - 1])
		var positions: Array[float] = [screen.arena.tower_position().x]
		for id: StringName in screen.arena.equipped_supports(): positions.append(screen.arena.support_position(id).x)
		positions.sort()
		var separated: bool = true
		for index: int in range(1, positions.size()): separated = separated and positions[index] - positions[index - 1] >= 90
		t.check(separated and positions[0] >= 50 and positions[-1] <= 590, "radio instruments have distinct spaced deck slots for %d supports" % count)
		t.check(is_equal_approx(screen.arena.tower_position().x, CombatSession.ARENA.x * .5), "main tower stays centered with %d supports" % count)
		if count == 5:
			var uniform: bool = true
			for index: int in range(1, positions.size()): uniform = uniform and is_equal_approx(positions[index] - positions[index - 1], 90)
			t.check(uniform, "full instrument deck has even spacing around centered tower")
	var dial: RadioDial = RadioDial.new()
	dial.max_value = 10
	var offsets: Array[float] = []
	for tick: int in 240:
		dial._process(1.0 / 60)
		offsets.append(dial.displayed - dial.target)
	t.check(offsets.min() < -.1 and offsets.max() > .1, "radio needle hunts on both sides of its target")
	dial.value = 9
	for tick: int in 240:
		dial._process(1.0 / 60)
	t.check(absf(dial.displayed - dial.target) <= .0281, "earned signal narrows tuning search")
	dial.running = false
	var stopped: Vector2 = Vector2(dial.displayed, dial.knob_angle)
	dial._process(1)
	t.check(stopped == Vector2(dial.displayed, dial.knob_angle), "pause freezes both needle and rotary knobs")
	dial.value = 10
	dial._process(.1)
	t.check(dial.displayed == dial.target and dial.knob_angle == 0, "ready upgrade locks needle and knobs to station")
	var random_before: Dictionary = b.random.to_data()
	var prior: float = -1
	var stations: Array[float] = []
	for cycle: int in 110:
		dial.set_cycle(b.random.seed_value, cycle)
		t.check(dial.frequency >= 88.1 and dial.frequency <= 107.9 and int(round(dial.frequency * 10)) % 2 == 1, "tuner uses a decimal FM channel")
		t.check(dial.frequency != prior, "next tuning cycle changes station")
		if cycle < 100: stations.append(dial.frequency)
		prior = dial.frequency
	var restored_dial: RadioDial = RadioDial.new()
	restored_dial.set_cycle(b.random.seed_value, 109)
	t.check(restored_dial.frequency == dial.frequency and b.random.to_data() == random_before, "station survives resume without consuming gameplay RNG")
	t.check(stations.size() == 100 and SaveChecks.unique(stations), "station deck covers 100 channels before repeating")
	restored_dial.free()
	dial.free()
	screen._open_settings()
	var elapsed: float = screen.session.elapsed
	screen.session.advance(1)
	t.check(screen.session.paused and screen.session.elapsed == elapsed, "M10 opening settings freezes simulation")
	screen.toggle_pause()
	t.check(screen.session.paused, "M10 pause shortcut cannot resume behind settings")
	screen.settings_panel.back_requested.emit()
	t.check(screen.settings_panel == null and screen.session.paused, "M10 settings Back returns to paused combat")
	RadioPreferences.current.values.sound = false
	RadioPreferences.current.values.music = false
	screen.radio_audio._preferences_changed()
	screen.radio_audio.cue(RadioAudio.HIT)
	t.check(not screen.radio_audio.music.playing and screen.radio_audio.effects.all(func(p: AudioStreamPlayer) -> bool: return not p.playing), "M10 disabling audio stops music and all effect voices")
	screen.queue_free()
	await tree.process_frame
	RadioPreferences.current.values = original
	RadioPreferences.current.changed.emit()
	return true
