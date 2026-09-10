class_name MixerDesk
extends VBoxContainer
var session: CombatSession
var faders: Array[MixerFader] = []
var readouts: Array[Label] = []
var plus_buttons: Array[Button] = []
var minus_buttons: Array[Button] = []
var lamps: Array[ColorRect] = []
var remaining: Label
var unlocks: Label

func _ready() -> void:
	add_theme_constant_override("separation", 12)
	remaining = text_label("", self, 26)
	var meter: HBoxContainer = HBoxContainer.new()
	meter.add_theme_constant_override("separation", 8)
	add_child(meter)
	for index: int in 7:
		var lamp: ColorRect = ColorRect.new()
		lamp.custom_minimum_size = Vector2(12, 8)
		lamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		meter.add_child(lamp)
		lamps.append(lamp)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	for index: int in 3:
		var panel: PanelContainer = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var surface: StyleBoxFlat = RadioUI.surface("15242c", "384a4e")
		surface.content_margin_left = 8
		surface.content_margin_right = 8
		panel.add_theme_stylebox_override("panel", surface)
		row.add_child(panel)
		var strip: VBoxContainer = VBoxContainer.new()
		strip.add_theme_constant_override("separation", 10)
		panel.add_child(strip)
		var accent: Color = [Color("eda657"), Color("6dd9c2"), Color("a6aeef")][index]
		text_label(tr("MIXER_" + MixerState.CHANNELS[index].to_upper()), strip, 26).modulate = accent
		var fader: MixerFader = MixerFader.new()
		fader.accent = accent
		fader.tooltip_text = tr("MIXER_DETAIL_" + str(index))
		strip.add_child(fader)
		faders.append(fader)
		fader.value_changed.connect(func(value: float) -> void: change(index, int(value)))
		readouts.append(text_label("", strip, 23))
		var buttons: HBoxContainer = HBoxContainer.new()
		buttons.alignment = BoxContainer.ALIGNMENT_CENTER
		strip.add_child(buttons)
		for direction: int in [-1, 1]:
			var button: Button = Button.new()
			button.text = "−" if direction < 0 else "+"
			button.custom_minimum_size = Vector2(64, 60)
			button.add_theme_font_size_override("font_size", 28)
			button.tooltip_text = tr("MIXER_" + MixerState.CHANNELS[index].to_upper())
			RadioUI.button(button)
			buttons.add_child(button)
			button.pressed.connect(func() -> void: change(index, session.patchboard.mixer.levels[index] + direction))
			if direction < 0: minus_buttons.append(button)
			else: plus_buttons.append(button)
	unlocks = text_label("", self, 22)
	unlocks.modulate = Color("b9b9a9")

func text_label(value: String, parent: Node, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func change(index: int, value: int) -> void:
	if session == null: return
	var mix: MixerState = session.patchboard.mixer
	var maximum: int = mini(MixerState.LIMIT, mix.levels[index] + MixerState.budget(session.campaign.cleared) - mix.spent())
	mix.adjust(session, index, clampi(value, 0, maximum))
	render()

func render() -> void:
	var mix: MixerState = session.patchboard.mixer
	var budget: int = MixerState.budget(session.campaign.cleared)
	var free: int = budget - mix.spent()
	remaining.text = tr("MIXER_POINTS") % [free, budget]
	for index: int in 7:
		lamps[index].color = Color("eda657") if index < mix.spent() else Color("69c8b5") if index < budget else Color("343d40")
	for index: int in 3:
		var level: int = mix.levels[index]
		faders[index].set_value_no_signal(level)
		faders[index].queue_redraw()
		plus_buttons[index].disabled = free == 0 or level == MixerState.LIMIT
		minus_buttons[index].disabled = level == 0
		readouts[index].text = tr("MIXER_READOUT_" + str(index)) % ([level * 8, level * 6] if index == 1 else level * (10 if index == 0 else 12))
	unlocks.text = tr("MIXER_UNLOCK_" + str(budget))
