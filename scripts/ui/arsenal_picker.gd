class_name ArsenalPicker
extends PanelContainer
signal launched(loadout: Dictionary)
signal campaign_launched(mission: int, loadout: Dictionary, modules: Array[StringName])
signal settings_changed
signal back_requested
var broadcast_context: Dictionary = {}
var campaign_profile: CampaignProfile
var mission_index: int = 1
var modules: Array[StringName] = []
var module_heading: Label
var preview: Label
var module_buttons: Dictionary = {}
var selection: Dictionary = ArsenalContent.DEFAULT.duplicate()
var selectors: Array[OptionButton] = []
var launch_button: Button
var stat_strip: Label
var notice: Label
var equipment_art: Dictionary = {}
var details_body: VBoxContainer
var modules_body: VBoxContainer
var presets_body: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RadioUI.skin(self)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(24, 18, 24, 18)
	add_child(safe)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	safe.add_child(layout)
	_label(layout, tr("M10_LOADOUT"), 38)
	if not broadcast_context.is_empty():
		_label(layout, tr("BROADCAST_" + String(broadcast_context.mode).to_upper()) + " · " + tr(["BROADCAST_STANDARD", "BROADCAST_HARD", "BROADCAST_OVERLOAD"][int(broadcast_context.difficulty)]), 23)
		if broadcast_context.mode == "contract": _label(layout, tr("BROADCAST_CONTRACT_" + String(broadcast_context.contract).to_upper() + "_DESC"), 22)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var column: VBoxContainer = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	for category: String in ["main", "shield", "support"]:
		var ids: Array = ArsenalContent.MAINS if category == "main" else ArsenalContent.SHIELDS if category == "shield" else ArsenalContent.FAMILIES
		if campaign_profile != null: ids = CampaignContent.options(campaign_profile.cleared, category)
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", RadioUI.surface())
		column.add_child(card)
		if category == "support" and broadcast_context.get("contract") == "bare_antenna": card.hide()
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		card.add_child(row)
		equipment_art[category] = RadioUI.art(row, _texture(category), 104)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		_label(info, tr("M5_SELECT_" + category.to_upper()).to_upper(), 20).modulate = Color("8eb4b9")
		var choose: OptionButton = OptionButton.new()
		choose.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choose.clip_text = true
		choose.add_theme_font_size_override("font_size", 28)
		choose.get_popup().add_theme_font_size_override("font_size", 28)
		choose.get_popup().add_theme_constant_override("v_separation", 26)
		RadioUI.button(choose)
		info.add_child(choose)
		selectors.append(choose)
		for id: String in ids: choose.add_item(tr(ArsenalContent.DEFINITIONS[id].name_key))
		choose.selected = maxi(0, ids.find(selection[category]))
		var role: Label = _label(info, tr(ArsenalContent.DEFINITIONS[selection[category]].preview_key), 22)
		choose.item_selected.connect(func(index: int) -> void:
			selection[category] = String(ids[index])
			role.text = tr(ArsenalContent.DEFINITIONS[String(ids[index])].preview_key)
			equipment_art[category].texture = _texture(category)
			refresh_preview())
	stat_strip = _label(column, "", 26)
	stat_strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat_strip.modulate = Color("b8ead9")
	if campaign_profile != null: add_campaign_controls(column)
	else:
		details_body = RadioUI.fold(column, tr("M10_STATS"))
		preview = _label(details_body, "", 24)
	refresh_preview()
	notice = _label(column, "", 22)
	var footer: HBoxContainer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	layout.add_child(footer)
	var back: Button = Button.new()
	back.text = tr("M10_BACK")
	back.add_theme_font_size_override("font_size", 26)
	RadioUI.button(back)
	footer.add_child(back)
	back.pressed.connect(func() -> void: back_requested.emit())
	launch_button = Button.new()
	launch_button.text = tr("M5_LAUNCH") + "  →"
	launch_button.custom_minimum_size.y = 94
	launch_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	launch_button.add_theme_font_size_override("font_size", 30)
	RadioUI.button(launch_button, true)
	footer.add_child(launch_button)
	launch_button.pressed.connect(func() -> void:
		if campaign_profile == null: launched.emit(selection.duplicate())
		elif CampaignContent.valid_selection(selection, modules, campaign_profile.cleared): campaign_launched.emit(mission_index, selection.duplicate(), modules.duplicate()))

func _texture(category: String) -> Texture2D:
	if category == "main": return RadioArt.MAIN[selection.main]
	return DraftPanel.ICONS[&"shield" if category == "shield" else StringName(selection.support)]

func _label(parent: Node, text_value: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func add_campaign_controls(column: VBoxContainer) -> void:
	modules_body = RadioUI.fold(column, tr("M10_MODULES"))
	var module_toggle: Button = modules_body.get_parent().get_child(modules_body.get_index() - 1)
	module_toggle.toggled.connect(func(_open: bool) -> void: refresh_preview())
	module_heading = _label(modules_body, tr("M7_MODULE_SLOTS") % [modules.size(), 2], 26)
	for id: String in CampaignContent.options(campaign_profile.cleared, "modules"):
		var definition: ModuleDefinition = CampaignContent.MODULES[StringName(id)]
		var button: CheckButton = CheckButton.new()
		button.text = tr(definition.name_key)
		button.button_pressed = StringName(id) in modules
		button.custom_minimum_size.y = 76
		button.add_theme_font_size_override("font_size", 27)
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		modules_body.add_child(button)
		module_buttons[id] = button
		_label(modules_body, tr(definition.description_key), 24)
		button.toggled.connect(func(enabled: bool) -> void:
			if enabled and modules.size() >= 2:
				button.set_pressed_no_signal(false)
				return
			if enabled: modules.append(StringName(id))
			else: modules.erase(StringName(id))
			refresh_preview())
	details_body = RadioUI.fold(column, tr("M10_STATS"))
	preview = _label(details_body, "", 24)
	presets_body = RadioUI.fold(column, tr("M7_PRESETS"))
	for index: int in 3:
		var row: HBoxContainer = HBoxContainer.new()
		presets_body.add_child(row)
		for save: bool in [false, true]:
			var button: Button = Button.new()
			button.text = tr("M7_SAVE_PRESET" if save else "M7_LOAD_PRESET") % (index + 1)
			button.custom_minimum_size.y = 76
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 23)
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			RadioUI.button(button)
			row.add_child(button)
			button.pressed.connect(func() -> void:
				if save:
					if campaign_profile.save_preset(index, selection, modules): settings_changed.emit()
				else:
					notice.text = tr("M10_PRESET_LOADED" if load_preset(index) else "M10_PRESET_EMPTY"))

func load_preset(index: int) -> bool:
	var preset: Dictionary = campaign_profile.presets[index]
	if preset.is_empty() or not CampaignContent.valid_selection(preset.loadout, preset.modules, campaign_profile.cleared): return false
	selection = preset.loadout.duplicate()
	modules.assign(preset.modules)
	var categories: Array[String] = ["main", "shield", "support"]
	for item: int in categories.size():
		var ids: Array = CampaignContent.options(campaign_profile.cleared, categories[item])
		selectors[item].selected = ids.find(selection[categories[item]])
		selectors[item].item_selected.emit(selectors[item].selected)
	for id: String in module_buttons: module_buttons[id].set_pressed_no_signal(StringName(id) in modules)
	refresh_preview()
	return true

func refresh_preview() -> void:
	if preview == null: return
	if module_heading != null: module_heading.text = tr("M7_MODULE_SLOTS") % [modules.size(), 2]
	for id: String in module_buttons: module_buttons[id].disabled = modules.size() >= 2 and StringName(id) not in modules
	var main: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[selection.main])
	var shield: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[selection.shield])
	main.modules = modules.duplicate()
	shield.modules = modules.duplicate()
	var attack: Dictionary = ArsenalStats.parameters(main)
	var defense: Dictionary = ArsenalStats.parameters(shield)
	stat_strip.text = tr("M10_STATS_STRIP") % [ModuleStats.maximum_hull(modules), defense.capacity, attack.damage]
	if modules_body != null:
		var toggle: Button = modules_body.get_parent().get_child(modules_body.get_index() - 1)
		toggle.text = ("−  " if modules_body.visible else "+  ") + tr("M10_MODULE_COUNT") % modules.size()
	preview.text = tr("M7_MODULE_SLOTS") % [modules.size(), 2] + "\n" + tr("M7_PREVIEW") % [ModuleStats.maximum_hull(modules), defense.capacity, defense.recharge, defense.delay, defense.cooldown, attack.damage, attack.interval, attack.reach, attack.crit * 100, 2 + int(ModuleStats.coefficient(modules, &"rerolls"))]

	var support: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[selection.support])
	support.modules = modules.duplicate()
	var params: Dictionary = ArsenalStats.parameters(support)
	preview.text += "\n" + tr(support.definition.name_key)
	for key: StringName in [&"damage", &"interval", &"reach", &"radius", &"push", &"pull", &"speed", &"duration"]:
		if params.has(key): preview.text += "\n" + tr("M5_STAT_" + String(key).to_upper()) + ": %.2f" % float(params[key])
