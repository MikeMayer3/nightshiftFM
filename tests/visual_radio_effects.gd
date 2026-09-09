extends SceneTree
## Render actual combat effects in isolated panels; no live-save modifications.
var arenas: Array[CombatArena] = []
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1080, 1080)
	root.content_scale_size = Vector2i(1080, 1080)
	RadioPreferences.current.values.low_effects = false
	RadioPreferences.current.values.reduced_flash = false
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(grid)
	var ids: Array[String] = ["pulse", "sweep", "burst", "arc_aerial", "bass_driver", "static_net", "echo_deck", "needle_swarm", "reverb_well"]
	for id: String in ids:
		var column: VBoxContainer = VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		grid.add_child(column)
		var title: Label = Label.new()
		title.text = tr(ArsenalContent.DEFINITIONS[id].name_key)
		title.add_theme_font_size_override("font_size", 22)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(title)
		var arena: CombatArena = CombatArena.new()
		arena.size_flags_vertical = Control.SIZE_EXPAND_FILL
		arena.custom_minimum_size = Vector2(350, 305)
		var s: CombatSession = CombatSession.new()
		s.start_arsenal(42, &"run.1", {"main": id if id in ["pulse", "sweep", "burst"] else "pulse", "shield": "capacitor", "support": id if id not in ["pulse", "sweep", "burst"] else "arc_aerial"})
		s.advance(2.4)
		arena.session = s
		column.add_child(arena)
		arena.set_process(false)
		arena.waveform_time = 1.2
		var center: Vector2 = Vector2(310, 300)
		if id in ["pulse", "sweep", "burst"]:
			arena.show_shot(center)
			arena.shot_flash = .12
		elif id == "arc_aerial":
			arena.show_chain(PackedVector2Array([CombatSession.TRANSMITTER, center, center + Vector2(130, -70)]), true)
		elif id == "needle_swarm":
			for index: int in 5: s.arsenal.needles.append({"x": 230 + index * 40, "y": 300 + index % 2 * 40, "dx": 0, "dy": -1})
		else: arena.show_support(StringName(id), center, Vector2(140, 110))
		arenas.append(arena)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/M10/attack-gallery.png")
	print("Rendered all three transmitter attacks and six studio-instrument effects.")
	grid.queue_free()
	await process_frame
	quit()
