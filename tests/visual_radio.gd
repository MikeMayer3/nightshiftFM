extends SceneTree
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")
var checks: TestContext = TestContext.new()
var boot: BootScreen

class Gallery extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("111c29"))
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(32, 47), "NIGHTSHIFT FM / RADIO HARDWARE", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("f1dfbd"))
		draw_string(font, Vector2(32, 75), "Original vector art · first playable M10 pass", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("a2b9bf"))
		var names: Array[String] = ["ARC AERIAL", "BASS DRIVER", "STATIC NET", "ECHO DECK", "NEEDLE SWARM", "REVERB WELL"]
		var ids: Array[StringName] = [&"arc_aerial", &"bass_driver", &"static_net", &"echo_deck", &"needle_swarm", &"reverb_well"]
		for index: int in 6:
			var x: float = 25 + index * 145
			draw_texture_rect(DraftPanel.ICONS[ids[index]], Rect2(x, 106, 122, 122), false)
			draw_string(font, Vector2(x + 2, 253), names[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d2e1df"))
		var eras: Array[String] = ["01 / VALVE", "02 / TRANSISTOR", "03 / DIGITAL"]
		for era_index: int in 3:
			var y: float = 297 + era_index * 135
			draw_string(font, Vector2(32, y + 60), eras[era_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("d2e1df"))
			for role: int in 3:
				draw_texture_rect(RadioArt.ENEMIES[era_index][role], Rect2(255 + role * 200, y, 110, 110), false)
		draw_string(font, Vector2(272, 291), "SWARMER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a2b9bf"))
		draw_string(font, Vector2(481, 291), "DIVER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a2b9bf"))
		draw_string(font, Vector2(669, 291), "CARRIER", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a2b9bf"))

func _initialize() -> void: _run.call_deferred()

func click(button: BaseButton) -> void:
	var ancestor: Node = button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await process_frame
	await process_frame
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10/" + name + ".png")

func fits(control: Control, text: String) -> void:
	var box: Rect2 = control.get_global_rect()
	checks.check(box.position.x >= -1 and box.end.x <= root.get_visible_rect().size.x + 1, text + " fits horizontally")
	checks.check(box.position.y >= -1 and box.end.y <= root.get_visible_rect().size.y + 1, text + " fits vertically")

func horizontal_fit(control: Control, description: String) -> void:
	var overflow: Array[String] = []
	_scan_width(control, overflow)
	checks.check(overflow.is_empty(), description + " no horizontal overflow " + str(overflow))

func _scan_width(node: Node, overflow: Array[String]) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		if rect.position.x < -1 or rect.end.x > root.get_visible_rect().size.x + 1:
			overflow.append(str(node.name))
	for child: Node in node.get_children(): _scan_width(child, overflow)

func unfold(body: VBoxContainer) -> void:
	await click(body.get_parent().get_child(body.get_index() - 1))
	await process_frame

func _run() -> void:
	root.size = Vector2i(920, 740)
	root.content_scale_size = Vector2i(920, 740)
	var gallery: Gallery = Gallery.new()
	gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(gallery)
	await capture("radio-hardware")
	gallery.queue_free()
	await process_frame
	root.content_scale_size = Vector2i(720, 1280)
	var path: String = "user://m10_visual_fixture.json"
	for window_size: Vector2i in [Vector2i(360,640), Vector2i(450,950), Vector2i(768,1024), Vector2i(1024,768)]:
		root.size = window_size
		RadioPreferences.current.values = RadioPreferences.DEFAULTS.duplicate()
		MissionStore.new(path).save(MissionProfile.new(), {})
		boot = BOOT.instantiate() as BootScreen
		boot.save_path = path
		root.add_child(boot)
		await process_frame
		await click(boot.menu.get_node("Settings"))
		var panel: RadioSettingsPanel = boot.settings_panel
		checks.check(panel.visible, "M10 settings open via viewport click")
		await click(panel.toggles.large_text)
		await click(panel.toggles.reduced_flash)
		await click(panel.toggles.low_effects)
		checks.check(RadioPreferences.current.enabled("large_text"), "M10 viewport toggles apply preferences")
		var scroll: ScrollContainer = panel.column.get_parent()
		checks.check(panel.column.size.x <= scroll.size.x + 1, "M10 large-text settings have no horizontal overflow")
		scroll.scroll_vertical = 0
		await capture("settings-%dx%d" % [window_size.x, window_size.y])
		horizontal_fit(panel, "Compact settings %s" % window_size)
		for label: Node in panel.find_children("*", "Label", true, false):
			if label.text == panel.tr("M10_RADIO_CONTROLS"):
				await unfold(label.get_parent())
				checks.check(label.is_visible_in_tree(), "Full controls guide opens from settings")
				horizontal_fit(panel, "Controls guide %s" % window_size)
				await unfold(label.get_parent())
		await click(panel.column.get_node("Back"))
		await click(boot.menu.get_node("Start"))
		await capture("campaign-%dx%d" % [window_size.x, window_size.y])
		horizontal_fit(boot.campaign_panel, "Route %s" % window_size)
		await click(boot.campaign_panel.launch_button)
		await capture("equipment-%dx%d" % [window_size.x, window_size.y])
		horizontal_fit(boot.picker, "Equipment %s" % window_size)
		fits(boot.picker.launch_button, "Setup footer %s" % window_size)
		await unfold(boot.picker.details_body)
		checks.check(boot.picker.preview.is_visible_in_tree() and "65" in boot.picker.preview.text, "Full stats open with actual shield capacity")
		horizontal_fit(boot.picker, "Expanded stats %s" % window_size)
		fits(boot.picker.launch_button, "Expanded setup footer %s" % window_size)
		await unfold(boot.picker.details_body)
		await unfold(boot.picker.presets_body)
		horizontal_fit(boot.picker, "Presets %s" % window_size)
		await unfold(boot.picker.presets_body)
		await click(boot.picker.launch_button)
		var screen: CombatScreen = boot.combat
		screen.set_process(false)
		screen.session.advance(2.5)
		screen._refresh()
		await capture("combat-%dx%d" % [window_size.x, window_size.y])
		checks.check(not screen.ability_button.visible, "Manual cooldown attack is absent")
		horizontal_fit(screen, "Combat %s" % window_size)
		var health: Label = screen.get_node("Safe/Column/Health")
		checks.check("Station Health" in health.text, "Station Health label appears below field")
		var arena: CombatArena = screen.arena
		var tower: Vector2 = arena.tower_position() * arena.arena_stretch()
		checks.check(is_equal_approx(tower.x, arena.size.x * .5), "Visible tower is horizontally centered")
		checks.check(tower.y - 64 * arena.arena_scale() > arena.SHIELD_LINE_Y * arena.deck_stretch().y + 4, "Tower clears raised shield line")
		checks.check(is_equal_approx(CombatSession.BREACH_Y * arena.arena_stretch().y, arena.SHIELD_LINE_Y * arena.deck_stretch().y), "Visible boundary matches simulated enemy breach")
		checks.check(screen.pause_button.size.y < 70, "Pause remains compact with large text")
		fits(screen.shield_button, "M10 Shield %s" % window_size)
		fits(screen.arena, "M10 arena %s" % window_size)
		checks.check(screen.get_node("Safe/Column/Health").get_index() > screen.arena.get_index(), "Station Health and shield are below the battlefield")
		# Isolated visual loadout only; disconnect saving before placing five supports.
		screen.session.checkpoint_changed.disconnect(screen._save_checkpoint)
		screen.session.draft.catalog = ArsenalContent.tracks(ArsenalContent.DEFAULT)
		for family: StringName in [&"bass_driver", &"static_net", &"needle_swarm", &"reverb_well"]:
			screen.session.draft.equip(family)
		checks.check(screen.arena.equipped_supports().size() == 5, "M10 five-support visual fixture")
		await capture("five-supports-%dx%d" % [window_size.x, window_size.y])
		await click(screen.pause_button)
		checks.check(screen.session.paused, "M10 pause click freezes combat")
		await click(screen.settings_button)
		checks.check(screen.settings_panel != null, "M10 settings open from pause menu")
		var elapsed: float = screen.session.elapsed
		screen.session.advance(2)
		checks.check(screen.session.elapsed == elapsed, "M10 settings preserve paused clock")
		await click(screen.settings_panel.column.get_node("Back"))
		await capture("pause-%dx%d" % [window_size.x, window_size.y])
		fits(screen.resume_button, "M10 Resume %s" % window_size)
		await click(screen.resume_button)
		checks.check(not screen.session.paused, "M10 explicit Resume returns to combat")
		# Let real automatic combat earn a choice; keep the field visible behind it.
		for step: int in 150:
			if screen.session.is_deciding(): break
			screen.session.advance(.5)
		screen._refresh_decision()
		await capture("upgrade-sheet-%dx%d" % [window_size.x, window_size.y])
		checks.check(screen.session.is_deciding() and screen.draft_panel.visible, "Automatic combat earns an upgrade choice")
		checks.check(screen.draft_panel.size.y < screen.size.y * .75 and screen.arena.visible, "Upgrade sheet leaves the playing field visible")
		horizontal_fit(screen.draft_panel, "Compact upgrade %s" % window_size)
		for card: Button in screen.draft_panel.cards:
			var content: Control = card.get_child(0)
			checks.check(content.size.y <= card.size.y + 1, "Upgrade text remains inside its card")
		var frozen: float = screen.session.elapsed
		screen.session.advance(2)
		checks.check(screen.session.elapsed == frozen, "Upgrade sheet freezes the battle behind it")
		if not screen.draft_panel.info_buttons.is_empty():
			await click(screen.draft_panel.info_buttons[0])
			horizontal_fit(screen.draft_panel, "Upgrade details %s" % window_size)
			screen.draft_panel.show_draft(screen.session)
			await process_frame
		var earned: int = screen.session.signal_progress.choices
		await click(screen.draft_panel.cards[0])
		checks.check(screen.session.signal_progress.choices == earned + 1, "Compact upgrade card accepts a choice through viewport input")
		boot.queue_free()
		await process_frame
		# A progressed profile exposes every module and completed station at large text.
		var progressed: MissionProfile = load("res://tests/integration/test_campaign_screen.gd").new().profile_at(12)
		MissionStore.new(path).save(progressed, {})
		boot = BOOT.instantiate() as BootScreen
		boot.save_path = path
		root.add_child(boot)
		await process_frame
		await click(boot.menu.get_node("Start"))
		horizontal_fit(boot.campaign_panel, "Completed route %s" % window_size)
		await capture("route-complete-%dx%d" % [window_size.x, window_size.y])
		await click(boot.campaign_panel.station_buttons[4])
		checks.check(boot.campaign_panel.selected_mission == 5, "Station tile selects replay mission")
		await click(boot.campaign_panel.launch_button)
		await unfold(boot.picker.modules_body)
		await click(boot.picker.module_buttons.hot_tubes)
		await click(boot.picker.module_buttons.heavy_battery)
		checks.check(boot.picker.modules.size() == 2 and boot.picker.module_buttons.long_mast.disabled, "Two module slots enforce cap through actual clicks")
		horizontal_fit(boot.picker, "All modules %s" % window_size)
		fits(boot.picker.launch_button, "Module browsing footer %s" % window_size)
		await capture("modules-%dx%d" % [window_size.x, window_size.y])
		await unfold(boot.picker.modules_body)
		checks.check(not boot.picker.modules_body.visible and boot.picker.modules.size() == 2, "Closing module drawer preserves fitted modules")
		boot.queue_free()
		await process_frame
	print("RESULT: %d M10 visual checks; %d failures" % [checks.checks, checks.failures])
	quit(0 if checks.failures == 0 else 1)
