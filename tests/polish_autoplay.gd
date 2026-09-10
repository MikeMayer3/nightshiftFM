extends SceneTree
## Accelerated rendered missions through production scenes and legal draft buttons.
## Isolated saves; this is automated coverage, not human or physical-phone acceptance.
var checks: TestContext = TestContext.new()
var rows: Array[Dictionary] = []
var evidence_dir: String = "res://docs/evidence/M10-battle-polish/" if "--battle-polish" in OS.get_cmdline_user_args() else "res://docs/evidence/M10-polish/"
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence_dir + name + ".png")
func run() -> void:
	for support: String in ["static_net", "bass_driver"]:
		root.size = Vector2i(360,640) if support == "static_net" else Vector2i(450,950)
		root.content_scale_size = Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path = "user://polish_autoplay_" + support + ".json"
		for suffix: String in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(boot.save_path + suffix): DirAccess.remove_absolute(boot.save_path + suffix)
		root.add_child(boot); await process_frame
		boot.loadout.support = support
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen = boot.combat
		var s: CombatSession = screen.session
		screen.set_process(false); screen.arena.set_process(false)
		var drafts: int = 0
		var frames: int = 0
		var captured: Dictionary = {}
		while not s.is_finished() and frames < 9000:
			if s.is_wiring(): s.launch_wave()
			if s.is_deciding():
				screen._refresh()
				if drafts == 0: await capture(support + "-draft")
				var choice: int = 0
				for index: int in s.draft.offers.size():
					if SignalDraft.is_new(s.draft.offers[index]): choice = index; break
				var offer: StringName = s.draft.offers[choice]
				var target: StringName = s.draft.card(offer).target_id
				screen.draft_panel.cards[choice].pressed.emit()
				checks.check(not s.draft.offers.has(offer) or not s.is_deciding(), "legal visible upgrade button advances play")
				checks.check(screen.arena.feedback.upgrades.has(target), "earned choice highlights the upgraded instrument")
				if drafts == 0:
					screen._refresh(); screen.arena.queue_redraw()
					await capture(support + "-upgrade-highlight")
				drafts += 1
			screen.arena._process(.1)
			s.advance(.1)
			screen._refresh()
			if s.wave in [1,5,10] and not captured.has(s.wave) and not screen.arena.pulses.is_empty():
				captured[s.wave] = true
				await capture(support + "-wave-%d" % s.wave)
			frames += 1
			await process_frame
		checks.check(s.is_finished(), "rendered mission reaches a real result")
		screen._refresh(); await capture(support + "-result")
		rows.append({"support":support,"seed":s.random.seed_value,"wave":s.wave,"victory":s.phase == CombatSession.Phase.VICTORY,"hull":s.hull,"breaches":s.breaches,"seconds":s.elapsed,"drafts":drafts})
		boot.show_page(BootScreen.Page.MENU)
		await capture(support + "-return-menu")
		checks.check(boot.splash.visible and boot.menu.visible, "result returns to splash menu")
		boot.queue_free(); await process_frame
	FileAccess.open(evidence_dir + "playthrough.json",FileAccess.WRITE).store_string(JSON.stringify({"runs":rows,"checks":checks.checks,"failures":checks.failures},"\t"))
	print("RESULT: %d rendered playthrough checks; %d failures; %s" % [checks.checks,checks.failures,JSON.stringify(rows)])
	quit(0 if checks.failures == 0 else 1)
