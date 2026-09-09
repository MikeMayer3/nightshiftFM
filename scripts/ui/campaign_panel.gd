class_name CampaignPanel
extends PanelContainer
signal selected(mission: int)
signal changed
signal back_requested
var profile: MissionProfile
var column: VBoxContainer
var mission_selector: OptionButton
var launch_button: Button
var notice: Label
var briefing: Label
var selected_mission: int = 1

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(28, 24, 28, 24)
	add_child(safe)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	scroll.add_child(column)
	selected_mission = mini(12, profile.campaign.cleared + 1)
	show_home()

func clear() -> void:
	for node: Node in column.get_children():
		column.remove_child(node)
		node.queue_free()
	(column.get_parent() as ScrollContainer).set_deferred("scroll_vertical", 0)

func label_text(text: String, font_size: int = 26) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	column.add_child(label)
	return label

func button(text: String, callback: Callable) -> Button:
	var node: Button = Button.new()
	node.text = text
	node.custom_minimum_size.y = 80
	node.add_theme_font_size_override("font_size", 28)
	node.mouse_filter = Control.MOUSE_FILTER_PASS
	node.pressed.connect(callback)
	column.add_child(node)
	return node

func show_home() -> void:
	clear()
	label_text(tr("M7_CAMPAIGN"), 42)
	label_text(tr("M7_PERSISTENCE"), 25)
	label_text(tr("M7_PROGRESS") % [profile.campaign.cleared, 12], 28)
	mission_selector = OptionButton.new()
	mission_selector.mouse_filter = Control.MOUSE_FILTER_PASS
	mission_selector.custom_minimum_size.y = 84
	mission_selector.add_theme_font_size_override("font_size", 27)
	mission_selector.get_popup().add_theme_font_size_override("font_size", 26)
	mission_selector.get_popup().add_theme_constant_override("v_separation", 20)
	for mission: MissionDefinition in CampaignContent.MISSIONS:
		mission_selector.add_item(tr(mission.name_key))
		mission_selector.set_item_disabled(mission.campaign_index - 1, not profile.campaign.can_play(mission.campaign_index))
	mission_selector.selected = selected_mission - 1
	mission_selector.item_selected.connect(func(index: int) -> void:
		selected_mission = index + 1
		refresh_briefing())
	column.add_child(mission_selector)
	briefing = label_text("", 24)
	refresh_briefing()
	label_text(tr("M7_NEXT_UNLOCK") % next_unlock(), 25)
	launch_button = button(tr("M7_EQUIP"), func() -> void: selected.emit(selected_mission))
	button(tr("M7_CODEX"), show_codex)
	button(tr("M7_RECORDS"), show_records)
	button(tr("MENU_BACK"), func() -> void: back_requested.emit())
	notice = label_text(tr("M7_PRESET_MIGRATION") if profile.campaign.migrated_presets else "", 23)

func refresh_briefing() -> void:
	var mission: MissionDefinition = CampaignContent.MISSIONS[selected_mission - 1]
	briefing.text = tr(mission.description_key)
	briefing.modulate = Color("efa968") if mission.prototype else Color("b7d9df")

func next_unlock() -> String:
	match profile.campaign.cleared:
		0: return tr("M7_UNLOCK_1")
		1: return tr("M7_UNLOCK_2")
		2: return tr("M7_UNLOCK_3")
		3: return tr("M7_UNLOCK_4")
		_: return tr("M7_UNLOCK_LATER")

func show_codex() -> void:
	clear()
	label_text(tr("M7_CODEX"), 40)
	label_text(tr("M7_CODEX_HINT"), 24)
	for id: StringName in PatchboardContent.RECIPES:
		var recipe: SynergyDefinition = PatchboardContent.RECIPES[id]
		label_text(tr(recipe.name_key) + " · " + tr("M6_DISCOVERED" if id in profile.discovered else "M7_UNDISCOVERED"), 30)
		var endpoints: PackedStringArray = []
		for endpoint: StringName in recipe.endpoint_ids:
			endpoints.append(tr("M5_SELECT_" + String(endpoint).to_upper()) if endpoint in [&"main", &"shield"] else tr(ArsenalContent.DEFINITIONS[String(endpoint)].name_key))
		label_text(" + ".join(endpoints), 24)
		label_text(tr(recipe.description_key), 25)
	button(tr("MENU_BACK"), show_home)

func show_records() -> void:
	clear()
	label_text(tr("M7_RECORDS"), 40)
	label_text(tr("M7_MASTERY_HINT"), 24)
	var choose: OptionButton = OptionButton.new()
	choose.mouse_filter = Control.MOUSE_FILTER_PASS
	choose.custom_minimum_size.y = 84
	choose.add_theme_font_size_override("font_size", 27)
	choose.get_popup().add_theme_font_size_override("font_size", 27)
	choose.get_popup().add_theme_constant_override("v_separation", 20)
	var skins: Array[StringName] = [&"default"]
	choose.add_item(tr("M7_DEFAULT_SKIN"))
	for family: StringName in ArsenalContent.FAMILIES:
		if profile.campaign.cosmetic_available(family):
			skins.append(family)
			choose.add_item(tr(ArsenalContent.DEFINITIONS[String(family)].name_key))
	choose.selected = skins.find(profile.campaign.cosmetic)
	choose.item_selected.connect(func(index: int) -> void:
		profile.campaign.cosmetic = skins[index]
		changed.emit())
	column.add_child(choose)
	for family: StringName in ArsenalContent.FAMILIES:
		var count: int = profile.campaign.mastery.get(String(family), []).size()
		label_text(tr(ArsenalContent.DEFINITIONS[String(family)].name_key) + " · " + tr("M7_MASTERY_COUNT") % count, 26)
		if count == 3: label_text(tr("M7_MASTER_TITLE") % tr(ArsenalContent.DEFINITIONS[String(family)].name_key), 24).modulate = DraftPanel.ACCENTS[family]
	for index: int in profile.campaign.cleared:
		var mission: MissionDefinition = CampaignContent.MISSIONS[index]
		var record: Dictionary = profile.campaign.records[String(mission.id)]
		label_text(tr(mission.name_key), 30)
		var medals: PackedStringArray = []
		for id: String in record.medals: medals.append(tr("M7_MEDAL_" + id.to_upper()))
		label_text(" · ".join(medals), 24)
		label_text(tr("M7_BEST") % [record.best_hull * 100, record.best_seconds], 23)
	button(tr("MENU_BACK"), show_home)
