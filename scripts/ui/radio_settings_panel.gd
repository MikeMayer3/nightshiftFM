class_name RadioSettingsPanel
extends PanelContainer
signal back_requested
var column: VBoxContainer
var notice: Label
var toggles: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("101c29")
	add_theme_stylebox_override("panel", style)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(28, 24, 28, 24)
	add_child(safe)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	safe.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	label("M10_SETTINGS", 36)
	for key: String in RadioPreferences.current.DEFAULTS:
		if key == "left_handed": continue
		var toggle: CheckButton = CheckButton.new()
		toggle.name = "ShowSignal" if key == "show_signal" else key
		toggle.custom_minimum_size.y = 88
		toggle.add_theme_font_size_override("font_size", 25)
		toggle.button_pressed = RadioPreferences.current.enabled(key)
		toggle.text = tr("M10_" + key.to_upper())
		RadioUI.button(toggle)
		column.add_child(toggle)
		toggles[key] = toggle
		toggle.toggled.connect(func(value: bool) -> void:
			RadioPreferences.current.set_option(key, value)
			notice.text = tr("M10_SAVED" if RadioPreferences.current.save_error == OK else "M10_SAVE_ERROR"))
	var guide: VBoxContainer = RadioUI.fold(column, tr("M10_CONTROLS"))
	for key: String in ["M10_RADIO_CONTROLS", "M10_STATUS_GUIDE"]:
		var instructions: Label = Label.new()
		instructions.text = tr(key)
		instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		instructions.add_theme_font_size_override("font_size", 24)
		guide.add_child(instructions)
	notice = label("M10_SAVED", 23)
	var back: Button = Button.new()
	back.name = "Back"
	back.text = tr("MENU_BACK")
	back.custom_minimum_size.y = 80
	back.add_theme_font_size_override("font_size", 28)
	RadioUI.button(back, true)
	column.add_child(back)
	back.pressed.connect(func() -> void: back_requested.emit())

func label(key: String, font_size: int) -> Label:
	var node: Label = Label.new()
	node.text = tr(key)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	column.add_child(node)
	return node

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("menu_back"):
		back_requested.emit()
		get_viewport().set_input_as_handled()
