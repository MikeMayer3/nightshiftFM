class_name ConnectionDiagram
extends VBoxContainer
## Existing hardware illustrations, explicit endpoint state and short activation cue.
const ICONS: Dictionary = {
	&"arc_aerial": preload("res://assets/art/radio/arc.svg"),
	&"bass_driver": preload("res://assets/art/radio/bass.svg"),
	&"static_net": preload("res://assets/art/radio/net.svg"),
	&"needle_swarm": preload("res://assets/art/radio/needle.svg"),
	&"reverb_well": preload("res://assets/art/radio/reverb.svg"),
	&"echo_deck": preload("res://assets/art/radio/echo.svg"),
	&"shield": preload("res://assets/art/equipment/shield.svg"),
}
var data: Dictionary

func configure(session: CombatSession, row: Dictionary, compact: bool = false) -> void:
	data = row
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 5)
	var recipe: SynergyDefinition = PatchboardContent.RECIPES[row.id]
	if compact:
		var strip: HBoxContainer = HBoxContainer.new()
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		strip.add_theme_constant_override("separation", 6)
		add_child(strip)
		for endpoint: StringName in recipe.endpoint_ids:
			var image: TextureRect = TextureRect.new()
			image.mouse_filter = Control.MOUSE_FILTER_IGNORE
			image.texture = RadioArt.main_texture(session) if endpoint == &"main" else ICONS[endpoint]
			image.custom_minimum_size = Vector2(36, 36)
			image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			if endpoint in row.missing: image.modulate = Color("82919b")
			strip.add_child(image)
		var text: Label = Label.new()
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.text = tr(recipe.name_key) + " · " + tr(row.status_key)
		if row.warning_key != &"": text.text += "\n" + tr(row.warning_key)
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 19)
		strip.add_child(text)
		return
	var title: Label = caption(tr(recipe.name_key), 21)
	title.modulate = Color("f3d57b")
	var line: HBoxContainer = HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 8)
	add_child(line)
	for index: int in recipe.endpoint_ids.size():
		if index > 0:
			var link: Label = Label.new()
			link.text = "↔" if row.ready else "+"
			link.mouse_filter = Control.MOUSE_FILTER_IGNORE
			link.add_theme_font_size_override("font_size", 26)
			line.add_child(link)
		var endpoint: StringName = recipe.endpoint_ids[index]
		var tile: VBoxContainer = VBoxContainer.new()
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(tile)
		var icon: TextureRect = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = RadioArt.main_texture(session) if endpoint == &"main" else ICONS[endpoint]
		icon.custom_minimum_size = Vector2(42, 42) if compact else Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if endpoint in row.missing: icon.modulate = Color("82919b")
		tile.add_child(icon)
		var status: Label = Label.new()
		status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status.text = tr("P1_NEED" if endpoint in row.missing else "P1_AFTER" if session.draft.track(endpoint) == null else "P1_OWNED")
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.add_theme_font_size_override("font_size", 18)
		tile.add_child(status)
		var owned: UpgradeTrack = BuildGuide.track_in(row.tracks, endpoint)
		var definition: TrackDefinition = owned.definition if owned != null else ArsenalContent.DEFINITIONS[String(endpoint)]
		var name_label: Label = Label.new()
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.text = tr(definition.name_key)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 20)
		tile.add_child(name_label)
	caption(tr(row.status_key), 19).modulate = Color("9ce3cf") if row.ready else Color("edbd91")
	if row.warning_key != &"": caption(tr(row.warning_key), 20).modulate = Color("edbd91")
	if not compact:
		caption(tr("P1_" + String(row.id).to_upper() + "_USE"), 23)
		caption(tr("P1_" + String(row.id).to_upper() + "_TRADE"), 20).modulate = Color("b6c5ce")

func caption(value: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label
