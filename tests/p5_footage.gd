extends SceneTree
## Real authored play replayed from a legal capture point, at 30 simulation FPS.
## No fabricated actors, ranks, hits or outcomes. Record with --resolution 450x800
## as well as --write-movie; the writer fixes its canvas before this script runs.
const FIXTURE = preload("res://tests/p5_fixture.gd")
var t: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(450,800); root.content_scale_size = Vector2i(720,1280)
	RadioPreferences.current.coach_seen.assign(RadioPreferences.COACH_IDS)
	var fixture: Dictionary = FIXTURE.prepare()
	var path: String = "user://p5_footage_%d.json" % Time.get_ticks_usec()
	var profile: MissionProfile = MissionProfile.new(); profile.enable_m4(); profile.next_run = 2
	t.check(MissionStore.new(path).save(profile, fixture.before) == OK, "isolated capture point validates")
	var boot: BootScreen = preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = path; root.add_child(boot); boot.continue_button.pressed.emit()
	var screen: CombatScreen = boot.combat
	screen.set_process(false); screen.arena.set_process(false); screen.radio_audio.set_process(false)
	var s: CombatSession = screen.session
	var hold: int = 0
	var after: int = 0
	var accepted: bool = false
	var captures: Dictionary = {}
	for frame: int in 1800:
		if s.is_deciding():
			var id: StringName = FIXTURE.choice(s)
			screen._refresh()
			if id == BassPayoff.BRANCH and hold < 60:
				hold += 1
			else:
				var index: int = s.draft.offers.find(id)
				screen.draft_panel.cards[index].pressed.emit()
				if id == BassPayoff.BRANCH:
					accepted = true
					t.check(BassPayoff.active(s), "visible legal upgrade button equips Wideband")
		if s.run.shield.current < 20: screen.use_shield()
		screen.arena._process(1.0/30); screen._process(1.0/30); screen.radio_audio._process(1.0/30)
		await process_frame; await RenderingServer.frame_post_draw
		var label: String = "after" if accepted else "before"
		if not captures.has(label) and screen.arena.pulses.any(func(p: Dictionary) -> bool: return p.source == &"bass_driver" and p.get("wideband", false) == accepted and float(p.left) <= .35 and float(p.left) >= .2):
			captures[label] = {"seconds":s.elapsed,"rank":s.draft.track(&"bass_driver").rank(),"wave":s.wave}
			root.get_texture().get_image().save_png("res://docs/evidence/P5-payoff/" + "gameplay-" + label + ".png")
		if accepted:
			after += 1
			if after >= 360: break
	t.check(accepted and captures.has("before") and captures.has("after"), "real before and after attacks captured")
	FileAccess.open("res://docs/evidence/P5-payoff/footage.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":42,"mission":1,"simulation_fps":30,"decision_hold_seconds":2,"captures":captures,"checks":t.checks,"failures":t.failures,"scope":"real authored gameplay; automated inputs and isolated legal checkpoint capture, not human play"},"\t"))
	boot.queue_free(); await process_frame
	print("RESULT: %d footage checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures == 0 else 1)
