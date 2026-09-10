extends SceneTree
var t: TestContext=TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(360,640); root.content_scale_size=Vector2i(720,1280)
	var prefs: RadioPreferences=RadioPreferences.current
	prefs.path="user://p3_first_options_%d.json"%Time.get_ticks_usec()
	prefs.values.large_text=true; prefs.values.sound=false; prefs.values.music=false
	prefs.coach_seen.clear()
	var path: String="user://p3_first_mission_%d.json"%Time.get_ticks_usec()
	var boot: BootScreen=preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path=path; root.add_child(boot); await settle()
	click(boot.menu.get_node("Start")); await settle()
	t.check(boot.current_page==BootScreen.Page.CAMPAIGN,"fresh menu opens station route through real input")
	t.check(boot.campaign_panel.selected_mission==1 and boot.campaign_panel.station_buttons[1].disabled,"first station selected and later stations locked")
	var scroll: ScrollContainer=boot.campaign_panel.column.get_parent()
	scroll.ensure_control_visible(boot.campaign_panel.launch_button); await settle()
	click(boot.campaign_panel.launch_button); await settle()
	t.check(boot.picker!=null,"route advances to equipment selection")
	capture("first-equipment")
	click(boot.picker.launch_button); await settle()
	var screen: CombatScreen=boot.combat
	t.check(screen!=null and not screen.save_failed and not screen.recovery_required,"starter loadout enters valid fresh mission")
	screen.set_process(false)
	var s: CombatSession=screen.session
	var shown: Array[String]=[]
	for step: int in 1200:
		if s.is_finished(): break
		if s.is_deciding():
			await settle()
			click(screen.draft_panel.cards[0])
		else: s.advance(.2)
		screen._refresh(); await settle()
		var hint: String=screen.coach.current_hint
		if not hint.is_empty() and hint not in shown:
			shown.append(hint); capture("first-"+hint)
			if hint=="shield": click(screen.shield_button)
			else: click(screen.coach.dismiss)
		if shown.size()==3: break
	t.check("mixer" in shown,"legal first-run upgrade triggers contextual mixer guidance")
	t.check("shield" in shown and "boost" in shown,"real approaching enemies and shield activation teach protection")
	var seen: Array[String]=prefs.coach_seen.duplicate()
	prefs.coach_seen.clear(); prefs.load_preferences()
	t.check(prefs.coach_seen==seen,"first-run coaching survives preference reload")
	var saved: Dictionary=MissionStore.new(path).load_save()
	t.check(MissionStore.valid(saved),"coaching leaves real mission checkpoint valid")
	boot.queue_free(); await process_frame
	var resumed: BootScreen=preload("res://scenes/boot/boot.tscn").instantiate()
	resumed.save_path=path; root.add_child(resumed); await settle()
	click(resumed.continue_button); await settle()
	t.check(resumed.combat!=null and not resumed.combat.recovery_required,"actual Continue resumes first-run checkpoint")
	t.check(prefs.coach_seen==seen,"continuation retains previously shown coaching")
	capture("first-continued")
	resumed.queue_free(); await process_frame
	print("RESULT: %d fresh-flow checks; %d failures; hints=%s"%[t.checks,t.failures,shown])
	quit(0 if t.failures==0 else 1)
func settle() -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
func click(control: Control) -> void:
	for down: bool in [true,false]:
		var event: InputEventMouseButton=InputEventMouseButton.new()
		event.position=control.get_global_rect().get_center();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down
		root.push_input(event,true)
func capture(label: String) -> void:
	root.get_texture().get_image().save_png("res://docs/evidence/P3-onboarding/"+label+".png")
