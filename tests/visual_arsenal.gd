extends SceneTree
var boot: BootScreen
func _initialize() -> void:
	_run.call_deferred()
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M5/" + name + ".png")
func _run() -> void:
	boot = (load("res://scenes/boot/boot.tscn") as PackedScene).instantiate() as BootScreen
	boot.save_path = "user://arsenal_visual_fixture.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(boot.save_path + suffix): DirAccess.remove_absolute(boot.save_path + suffix)
	root.add_child(boot)
	boot.show_page(BootScreen.Page.ARSENAL)
	await capture("arsenal-picker")
	var picker: ArsenalPicker = boot.picker
	for index: int in 3:
		picker.selectors[index].select([1, 2, 5][index])
		picker.selectors[index].item_selected.emit([1, 2, 5][index])
	await capture("arsenal-selection")
	picker.launch_button.pressed.emit()
	await process_frame
	var screen: CombatScreen = boot.combat
	screen.set_process(false)
	var s: CombatSession = screen.session
	assert(s.arsenal != null and s.draft.track(&"reverb_well") != null)
	assert((s.draft as ArsenalDraft).loadout.main == "sweep")
	# Artificial five-support presentation fixture: disconnected from save persistence.
	s.checkpoint_changed.disconnect(screen._save_checkpoint)
	for id: StringName in ArsenalContent.FAMILIES: s.draft.equip(id)
	s.apply_ranks()
	s.advance(2.4)
	screen._refresh()
	await capture("arsenal-five-turrets")
	root.size = Vector2i(360, 640)
	await capture("arsenal-small")
	root.size = Vector2i(450, 950)
	await capture("arsenal-tall")
	s.phase = CombatSession.Phase.DRAFT
	s.draft.begin()
	screen.draft_panel.show_draft(s)
	await capture("arsenal-draft")
	screen.draft_panel._show_details(s, s.draft.offers[1])
	await capture("arsenal-comparison")
	print("PASS: arsenal selection, chosen chassis, five turrets and draft/compare at three sizes; save_failed=", screen.save_failed)
	quit(0 if not screen.save_failed else 1)
