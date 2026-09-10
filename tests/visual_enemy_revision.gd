extends SceneTree
## Original enemy material gallery and staged battle readability checks.
var checks: TestContext = TestContext.new()
class Gallery extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("0d1925"))
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(30, 42), "MODERN RIVALS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("def1eb"))
		var textures: Array[Texture2D] = [RadioArt.ENEMIES[0][0], RadioArt.ENEMIES[0][1], RadioArt.ENEMIES[0][2]]
		textures.append_array(RadioArt.ROLES.slice(1))
		var names: Array[String] = ["Pocket player", "Wireless earbuds", "Smart speaker", "Rugged player", "Sync hub", "Noise-cancel buds", "Smartwatch", "Streaming dock", "The Playlist", "Cloud Speaker", "The Noise Canceller", "Satellite speaker"]
		for index: int in textures.size():
			var p: Vector2 = Vector2(24 + index % 4 * 240, 72 + index / 4 * 215)
			draw_style_box(RadioUI.surface("162737", "263c4c"), Rect2(p, Vector2(222, 195)))
			draw_texture_rect(textures[index], Rect2(p + Vector2(47, 10), Vector2(128, 128)), false)
			draw_string(font, p + Vector2(6, 167), names[index], HORIZONTAL_ALIGNMENT_CENTER, 210, 18, Color("c8dfe3"))
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10-frequency-enemies/" + name + ".png")
func run() -> void:
	root.size = Vector2i(990, 740); root.content_scale_size = root.size
	var gallery: Control = Gallery.new(); gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(gallery)
	await capture("enemy-gallery")
	gallery.queue_free(); await process_frame
	root.content_scale_size = Vector2i(720,1280)
	for dimensions: Vector2i in [Vector2i(360,640), Vector2i(450,950)]:
		root.size = dimensions
		var path: String = "user://enemy_revision_visual.json"
		MissionStore.new(path).save(load("res://tests/integration/test_campaign_screen.gd").new().profile_at(12), {})
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate(); boot.save_path = path; root.add_child(boot)
		await process_frame
		boot.show_page(BootScreen.Page.CAMPAIGN)
		boot.campaign_panel.selected_mission = 8
		boot.campaign_panel.launch_button.pressed.emit(); boot.picker.launch_button.pressed.emit()
		var screen: CombatScreen = boot.combat
		screen.set_process(false); screen.session.checkpoint_changed.disconnect(screen._save_checkpoint)
		var s: CombatSession = screen.session
		s.phase = CombatSession.Phase.COMBAT; s.wave = 5; s.patchboard.awaiting = false
		s.actors.clear()
		var definitions: Array[EnemyDefinition] = [CombatContent.SWARMER, BroadcastContent.enemy(&"m8.caster"), CombatContent.DIVER, BroadcastContent.enemy(&"m8.mimic"), BroadcastContent.enemy(&"m8.plated"), BroadcastContent.enemy(&"m8.mortar")]
		for index: int in definitions.size():
			var actor: CombatActor = s.spawn_enemy(definitions[index], 180 + index % 2 * 265)
			actor.position.y = 110 + index / 2 * 160
			actor.age = 2; actor.ability_time = actor.ability_interval - .6
			if index == 4: actor.status.slow = .3
			if index == 0: actor.health *= .6
		screen._refresh_decision()
		var random_before: Dictionary = s.random.to_data()
		for cycle: int in 3:
			screen.signal_bar.set_cycle(s.random.seed_value, cycle)
			await capture("battle-%dx%d-cycle-%d" % [dimensions.x, dimensions.y, cycle])
			checks.check(screen.signal_bar.frequency_text().contains("."), "visible station includes decimal")
			var label_start: float = screen.signal_bar.size.x - 172
			checks.check(label_start >= 155, "station readout clears tuning status at %s" % dimensions)
		checks.check(s.random.to_data() == random_before, "rendered tuning cycles leave run RNG unchanged")
		boot.queue_free(); await process_frame
	print("RESULT: %d enemy revision visual checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
