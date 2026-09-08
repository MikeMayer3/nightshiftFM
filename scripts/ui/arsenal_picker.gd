class_name ArsenalPicker
extends PanelContainer
signal launched(loadout: Dictionary)
signal back_requested
var selection: Dictionary = ArsenalContent.DEFAULT.duplicate()
var selectors: Array[OptionButton] = []
var launch_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(28, 24, 28, 24)
	add_child(safe)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 22)
	scroll.add_child(column)
	_label(column, tr("M5_ARSENAL"), 42)
	_label(column, tr("M5_FRESH_RANKS"), 24)
	for category: String in ["main", "shield", "support"]:
		_label(column, tr("M5_SELECT_" + category.to_upper()), 27)
		var ids: Array = ArsenalContent.MAINS if category == "main" else ArsenalContent.SHIELDS if category == "shield" else ArsenalContent.FAMILIES
		var choose: OptionButton = OptionButton.new()
		choose.custom_minimum_size.y = 84
		choose.add_theme_font_size_override("font_size", 30)
		choose.get_popup().add_theme_font_size_override("font_size", 30)
		choose.get_popup().add_theme_constant_override("v_separation", 24)
		column.add_child(choose)
		selectors.append(choose)
		for id: String in ids: choose.add_item(tr(ArsenalContent.DEFINITIONS[id].name_key))
		var role: Label = _label(column, tr(ArsenalContent.DEFINITIONS[String(ids[0])].preview_key), 24)
		choose.item_selected.connect(func(index: int) -> void:
			selection[category] = String(ids[index])
			role.text = tr(ArsenalContent.DEFINITIONS[String(ids[index])].preview_key))
	launch_button = Button.new()
	launch_button.text = tr("M5_LAUNCH")
	launch_button.custom_minimum_size.y = 90
	launch_button.add_theme_font_size_override("font_size", 30)
	column.add_child(launch_button)
	launch_button.pressed.connect(func() -> void: launched.emit(selection.duplicate()))
	var back: Button = Button.new()
	back.text = tr("MENU_BACK")
	back.custom_minimum_size.y = 76
	back.add_theme_font_size_override("font_size", 26)
	column.add_child(back)
	back.pressed.connect(func() -> void: back_requested.emit())

func _label(parent: Node, text_value: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label
