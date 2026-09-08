extends SceneTree
## Isolated screenshot/interaction fixture; the player's save is never opened.
var screen: CombatScreen
func _initialize() -> void:
	_run.call_deferred()
func capture(name: String) -> void:
	screen._refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M4/" + name + ".png")
func _run() -> void:
	screen = (load("res://scenes/combat/combat.tscn") as PackedScene).instantiate() as CombatScreen
	screen.m3_enabled = true
	screen.m4_enabled = true
	screen.store = MissionStore.new("user://m4_visual_fixture.json")
	root.add_child(screen)
	await process_frame
	screen.set_process(false)
	screen.session.advance(90)
	await capture("desktop-draft")
	if "--interactive" in OS.get_cmdline_user_args(): return
	screen.draft_panel.info_buttons[0].pressed.emit()
	await capture("desktop-details")
	screen.draft_panel.show_draft(screen.session)
	root.size = Vector2i(360, 640)
	await capture("desktop-small-draft")
	for i: int in 3: screen.session.choose_upgrade(screen.session.draft.offers[0])
	await capture("desktop-recruit")
	screen.session.recruit(&"bass_driver", screen.profile.unlocked)
	var captured_combat: bool = false
	var captured_checkpoint: bool = false
	var captured_elite: bool = false
	# Real decisions and checkpoints; seek new supports and their earliest branches.
	for step: int in 6000:
		if screen.session.is_finished(): break
		if screen.session.phase == CombatSession.Phase.DRAFT:
			var choice: StringName = screen.session.draft.offers[0]
			for id: StringName in screen.session.draft.offers:
				var option: UpgradeDefinition = screen.session.draft.card(id)
				if option != null and option.target_id == &"main" and screen.session.draft.track(&"main").rank() < 6: choice = id
			screen.session.choose_upgrade(choice)
		elif screen.session.phase == CombatSession.Phase.RECRUIT:
			screen.session.recruit(&"static_net" if screen.session.draft.track(&"static_net") == null else &"", screen.profile.unlocked)
		else:
			if not captured_checkpoint and screen.session.phase == CombatSession.Phase.INTERMISSION and screen.session.wave == 3:
				var proof: FileAccess = FileAccess.open("res://docs/evidence/M4/pixel-fixture.json", FileAccess.WRITE)
				proof.store_string(JSON.stringify({"schema": 1, "profile": screen.profile.to_data(), "run": screen.session.to_checkpoint()}))
				proof.close()
				captured_checkpoint = true
			if screen.session.run.shield.current < 30: screen.session.activate_shield()
			screen.session.advance(0.25)
			# Consume cosmetic timers instead of retaining every synthetic attack flash.
			screen.arena._process(0.25)
			if not captured_combat and screen.session.wave >= 4 and not screen.session.supports.field.is_empty():
				await capture("desktop-combat")
				captured_combat = true
			if not captured_elite and screen.session.wave == 10 and screen.session.actors.any(func(a: CombatActor) -> bool: return a.elite):
				await capture("desktop-finale")
				captured_elite = true
	await capture("desktop-results")
	screen.report_button.pressed.emit()
	await capture("desktop-report")
	print("PASS: M4 actual scene rendered draft/details/recruit/combat/finale/results/report; finale=", captured_elite)
	quit(0 if captured_combat and captured_elite else 1)
