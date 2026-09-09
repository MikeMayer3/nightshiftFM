class_name ArsenalPicker
extends PanelContainer
signal launched(loadout: Dictionary)
signal campaign_launched(mission: int, loadout: Dictionary, modules: Array[StringName])
signal settings_changed
signal back_requested
var campaign_profile: CampaignProfile
var mission_index: int = 1
var modules: Array[StringName] = []
var module_heading: Label
var preview: Label
var module_buttons: Dictionary = {}
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
		if campaign_profile != null: ids = CampaignContent.options(campaign_profile.cleared, category)
		var choose: OptionButton = OptionButton.new()
		choose.mouse_filter = Control.MOUSE_FILTER_PASS
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
			role.text = tr(ArsenalContent.DEFINITIONS[String(ids[index])].preview_key)
			refresh_preview())
	if campaign_profile != null: add_campaign_controls(column)
	launch_button = Button.new()
	launch_button.text = tr("M5_LAUNCH")
	launch_button.custom_minimum_size.y = 90
	launch_button.add_theme_font_size_override("font_size", 30)
	column.add_child(launch_button)
	launch_button.pressed.connect(func() -> void:
		if campaign_profile == null: launched.emit(selection.duplicate())
		elif CampaignContent.valid_selection(selection, modules, campaign_profile.cleared): campaign_launched.emit(mission_index, selection.duplicate(), modules.duplicate()))
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

func add_campaign_controls(column: VBoxContainer) -> void:
	module_heading = _label(column, tr("M7_MODULE_SLOTS") % [modules.size(), 2], 30)
	if campaign_profile.cleared < 4:
		_label(column, tr("M7_MODULE_LOCKED"), 24)
	else:
		for id: String in CampaignContent.options(campaign_profile.cleared, "modules"):
			var definition: ModuleDefinition = CampaignContent.MODULES[StringName(id)]
			var button: CheckButton = CheckButton.new()
			button.text = tr(definition.name_key)
			button.custom_minimum_size.y = 76
			button.add_theme_font_size_override("font_size", 27)
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			column.add_child(button)
			module_buttons[id] = button
			_label(column, tr(definition.description_key), 24)
			button.toggled.connect(func(enabled: bool) -> void:
				if enabled and modules.size() >= 2:
					button.set_pressed_no_signal(false)
					return
				if enabled: modules.append(StringName(id))
				else: modules.erase(StringName(id))
				refresh_preview())
	preview = _label(column, "", 24)
	refresh_preview()
	_label(column, tr("M7_PRESETS"), 30)
	for index: int in 3:
		var row: HBoxContainer = HBoxContainer.new()
		column.add_child(row)
		for save: bool in [false, true]:
			var button: Button = Button.new()
			button.text = tr("M7_SAVE_PRESET" if save else "M7_LOAD_PRESET") % (index + 1)
			button.custom_minimum_size.y = 76
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 23)
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			row.add_child(button)
			button.pressed.connect(func() -> void:
				if save:
					if campaign_profile.save_preset(index, selection, modules): settings_changed.emit()
				else: load_preset(index))

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
	module_heading.text = tr("M7_MODULE_SLOTS") % [modules.size(), 2]
	for id: String in module_buttons: module_buttons[id].disabled = modules.size() >= 2 and StringName(id) not in modules
	var main: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[selection.main])
	var shield: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[selection.shield])
	main.modules = modules.duplicate()
	shield.modules = modules.duplicate()
	var attack: Dictionary = ArsenalStats.parameters(main)
	var defense: Dictionary = ArsenalStats.parameters(shield)
	preview.text = tr("M7_MODULE_SLOTS") % [modules.size(), 2] + "\n" + tr("M7_PREVIEW") % [ModuleStats.maximum_hull(modules), defense.capacity, defense.recharge, defense.delay, defense.cooldown, attack.damage, attack.interval, attack.reach, attack.crit * 100, 2 + int(ModuleStats.coefficient(modules, &"rerolls"))]

	var support: UpgradeTrack = UpgradeTrack.new(ArsenalContent.DEFINITIONS[selection.support])
	support.modules = modules.duplicate()
	var params: Dictionary = ArsenalStats.parameters(support)
	preview.text += "\n" + tr(support.definition.name_key)
	for key: StringName in [&"damage", &"interval", &"reach", &"radius", &"push", &"pull", &"speed", &"duration"]:
		if params.has(key): preview.text += "\n" + tr("M5_STAT_" + String(key).to_upper()) + ": %.2f" % float(params[key])
	preview.text += "\n" + tr("M7_BURST_PREVIEW") % [45 * ModuleStats.damage_multiplier(modules, &"main"), ModuleStats.area_radius(modules, ActiveCombat.RADIUS)]
