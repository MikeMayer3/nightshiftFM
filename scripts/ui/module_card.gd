class_name ModuleCard
extends Button
## The whole illustrated tile is the touch target; no tiny selector control.
var module_id: StringName
var artwork: TextureRect
func configure(id: StringName) -> void:
	module_id = id
	var definition: ModuleDefinition = CampaignContent.MODULES[id]
	toggle_mode = true
	custom_minimum_size = Vector2(0, 246)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_text = tr(definition.description_key)
	RadioUI.button(self)
	# Focus must outline the tile without painting over its selected surface.
	var focus: StyleBoxFlat = RadioUI.surface("142735", "e8bb7a")
	focus.bg_color = Color.TRANSPARENT
	add_theme_stylebox_override("focus", focus)
	var box: VBoxContainer = VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 10; box.offset_right = -10; box.offset_top = 8; box.offset_bottom = -8
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 3)
	add_child(box)
	artwork = RadioUI.art(box, load("res://assets/art/modules/" + String(id) + ".svg"), 114)
	var title: Label = Label.new()
	title.text = tr(definition.name_key)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	for suffix: String in ["_GAIN", "_COST"]:
		var line: Label = Label.new()
		line.text = tr("MODULE_" + String(id).to_upper() + suffix)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_theme_font_size_override("font_size", 20)
		line.add_theme_color_override("font_color", Color("a9e4ce" if suffix == "_GAIN" else "e5b38d"))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(line)
