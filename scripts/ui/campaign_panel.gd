class_name CampaignPanel
extends PanelContainer
signal selected(mission: int)
signal changed
signal back_requested
var rules: Dictionary = {"mode": "campaign", "difficulty": 0, "contract": ""}
var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
var profile: MissionProfile
var column: VBoxContainer
var mission_name: Label
var launch_button: Button
var notice: Label
var selected_mission: int = 0
var station_buttons: Array[Button] = []
var prototype_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	RadioUI.skin(self)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(28, 24, 28, 24)
	add_child(safe)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	PageScroll.attach(self, scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	scroll.add_child(column)
	if selected_mission == 0: selected_mission = mini(12, profile.campaign.cleared + 1)
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
	RadioUI.button(node)
	node.pressed.connect(callback)
	column.add_child(node)
	return node

func show_home() -> void:
	clear()
	station_buttons.clear()
	label_text(tr("M10_ROUTE"), 38)
	label_text(tr("M7_PROGRESS") % [profile.campaign.cleared, 12], 24).modulate = Color("8eb4b9")
	if profile.achievements.title != &"":
		label_text(tr("P6_TITLE") % tr(AchievementCatalog.ALL[profile.achievements.title].name_key), 23).modulate = Color("e8bb7a")
	var goal: Dictionary = ProgressionGoals.next(profile)
	if not goal.is_empty(): ProgressionCard.add_to(column, goal, tr("P6_NEXT"))
	else: label_text(tr("P6_ALL_EARNED"), 24)
	for era_index: int in 3:
		var panel: PanelContainer = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", RadioUI.surface())
		column.add_child(panel)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		panel.add_child(row)
		RadioUI.art(row, RadioArt.ENEMIES[era_index][0], 90)
		var route: VBoxContainer = VBoxContainer.new()
		route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(route)
		var era_label: Label = Label.new()
		era_label.text = tr(["M10_VALVE", "M10_TRANSISTOR", "M10_DIGITAL"][era_index])
		era_label.add_theme_font_size_override("font_size", 22)
		era_label.modulate = Color("e8bb7a")
		route.add_child(era_label)
		var stations: HBoxContainer = HBoxContainer.new()
		stations.add_theme_constant_override("separation", 10)
		route.add_child(stations)
		for offset: int in 4:
			var index: int = era_index * 4 + offset + 1
			var station: Button = Button.new()
			station.text = str(index)
			station.add_theme_font_size_override("font_size", 27)
			station.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			station.disabled = not profile.campaign.can_play(index)
			station.tooltip_text = tr(CampaignContent.MISSIONS[index - 1].name_key)
			station.toggle_mode = true
			RadioUI.button(station)
			stations.add_child(station)
			station_buttons.append(station)
			station.pressed.connect(func() -> void:
				selected_mission = index
				refresh_mission())
	mission_name = label_text("", 28)
	prototype_label = label_text(tr("M10_PROTOTYPE"), 22)
	prototype_label.modulate = Color("efa968")
	button(tr("BROADCAST_MODES") + " · " + tr("BROADCAST_" + String(rules.mode).to_upper()), show_modes)
	launch_button = button(tr("M7_EQUIP"), func() -> void: selected.emit(selected_mission))
	RadioUI.button(launch_button, true)
	refresh_mission()
	for id: StringName in profile.achievements.tracked:
		ProgressionCard.add_to(column, ProgressionGoals.achievement(profile.achievements, id, AchievementRun.production_build()), tr("P6_TRACKED"))
	var navigation: HBoxContainer = HBoxContainer.new()
	navigation.add_theme_constant_override("separation", 10)
	column.add_child(navigation)
	for entry: Array in [["M10_CODEX", show_codex], ["M10_AWARDS", show_achievements], ["M10_RECORDS", show_records]]:
		var nav: Button = Button.new()
		nav.text = tr(entry[0])
		nav.add_theme_font_size_override("font_size", 22)
		nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		RadioUI.button(nav)
		nav.pressed.connect(entry[1])
		navigation.add_child(nav)
	button(tr("P6_REWARDS"), show_rewards)
	button(tr("MENU_BACK"), func() -> void: back_requested.emit())
	notice = label_text(tr("M7_PRESET_MIGRATION") if profile.campaign.migrated_presets else "", 23)
	notice.visible = not notice.text.is_empty()

func refresh_mission() -> void:
	var mission: MissionDefinition = CampaignContent.MISSIONS[selected_mission - 1]
	prototype_label.visible = mission.prototype
	mission_name.text = tr(mission.name_key)
	for index: int in station_buttons.size():
		var station: Button = station_buttons[index]
		station.set_pressed_no_signal(index + 1 == selected_mission)
		station.text = ("✓ " if index < profile.campaign.cleared else "") + str(index + 1)

func show_rewards() -> void:
	clear()
	label_text(tr("P6_REWARDS"), 38)
	label_text(tr("P6_LOADOUT_HINT"), 24)
	button(tr("MENU_BACK"), show_home)
	for row: Dictionary in ProgressionGoals.equipment(profile.campaign, loadout) + ProgressionGoals.colors(profile.campaign):
		ProgressionCard.add_to(column, row)
		if row.kind == "color" and row.state == "earned":
			var equip: Button = button(tr("P6_USE_COLOR"), func() -> void:
				profile.campaign.cosmetic = StringName(row.id)
				changed.emit()
				show_rewards())
			equip.set_meta("color_id", row.id)
	button(tr("MENU_BACK"), show_home)

func show_achievements() -> void:
	clear()
	label_text(tr("M9_ACHIEVEMENTS"), 40)
	label_text(tr("M9_HINT"), 24)
	label_text(tr(AchievementPlatform.new().status_key()), 23)
	label_text(tr("M9_PRACTICE"), 23)
	label_text(tr("M9_TRACKED"), 28)
	for id: StringName in profile.achievements.tracked:
		ProgressionCard.add_to(column, ProgressionGoals.achievement(profile.achievements, id, AchievementRun.production_build()), tr("P6_TRACKED"))
	button(tr("MENU_BACK"), show_home)
	for id: StringName in AchievementCatalog.ALL:
		var definition: AchievementDefinition = AchievementCatalog.ALL[id]
		ProgressionCard.add_to(column, ProgressionGoals.achievement(profile.achievements, id, AchievementRun.production_build()))
		if not definition.available:
			label_text(tr(definition.pending_key), 23).modulate = Color("efa968")
			continue
		if profile.achievements.earned(id):
			var title_button: Button = button(tr("M9_USE_TITLE"), func() -> void:
				profile.achievements.select_title(id)
				changed.emit()
				show_home())
			title_button.disabled = profile.achievements.title == id
			title_button.set_meta("achievement_id", id)
		else:
			var track_button: Button = button(tr("M9_UNTRACK" if id in profile.achievements.tracked else "M9_TRACK"), func() -> void:
				profile.achievements.track(id)
				changed.emit()
				show_achievements())
			track_button.disabled = profile.achievements.tracked.size() >= 3 and id not in profile.achievements.tracked
			track_button.set_meta("achievement_id", id)
	button(tr("MENU_BACK"), show_home)

func show_codex() -> void:
	clear()
	label_text(tr("M7_CODEX"), 40)
	label_text(tr("M7_CODEX_HINT"), 24)
	button(tr("BROADCAST_ENEMY_CODEX"), show_enemies)
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
	button(tr("BROADCAST_LOGS"), show_logs)
	for key: String in profile.broadcast.best_scores:
		var parts: PackedStringArray = key.split(":")
		var title: String = tr("BROADCAST_" + parts[0].to_upper())
		if parts[0] == "campaign": title = tr(CampaignContent.MISSIONS[int(parts[1]) - 1].name_key)
		elif parts[0] == "contract": title = tr("BROADCAST_CONTRACT_" + parts[1].to_upper())
		label_text(title + " · " + tr(["BROADCAST_STANDARD", "BROADCAST_HARD", "BROADCAST_OVERLOAD"][int(parts[2])]) + "  " + str(profile.broadcast.best_scores[key]), 23)
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

func show_modes() -> void:
	clear()
	label_text(tr("BROADCAST_MODES"), 36)
	for mode: String in BroadcastRules.MODES:
		var choice: Button = button(tr("BROADCAST_" + mode.to_upper()) + ("  ✓" if rules.mode == mode else ""), func() -> void:
			rules.mode = mode
			rules.contract = "two_channel" if mode == "contract" else ""
			show_modes())
		choice.set_meta("broadcast_mode", mode)
		choice.disabled = profile.campaign.cleared < (4 if mode == "contract" else 12 if mode == "endless" else 0)
		if choice.disabled: label_text(tr("BROADCAST_UNLOCK") % (4 if mode == "contract" else 12), 22)
	for difficulty: int in 3:
		var choice: Button = button(tr(["BROADCAST_STANDARD", "BROADCAST_HARD", "BROADCAST_OVERLOAD"][difficulty]) + ("  ✓" if rules.difficulty == difficulty else ""), func() -> void:
			rules.difficulty = difficulty
			show_modes())
		choice.set_meta("broadcast_difficulty", difficulty)
		choice.disabled = profile.campaign.cleared < (4 if difficulty == 1 else 12 if difficulty == 2 else 0)
	if rules.mode == "contract":
		for contract: String in BroadcastRules.CONTRACTS:
			var choice: Button = button(tr("BROADCAST_CONTRACT_" + contract.to_upper()) + ("  ✓" if rules.contract == contract else ""), func() -> void:
				rules.contract = contract
				show_modes())
			choice.set_meta("broadcast_contract", contract)
			if rules.contract == contract: label_text(tr("BROADCAST_CONTRACT_" + contract.to_upper() + "_DESC"), 23)
	elif rules.mode == "endless": label_text(tr("BROADCAST_ENDLESS_DESC"), 23)
	button(tr("MENU_BACK"), show_home)

func show_enemies() -> void:
	clear()
	label_text(tr("BROADCAST_ENEMY_CODEX"), 36)
	var definitions: Array[EnemyDefinition] = [CombatContent.SWARMER, CombatContent.DIVER, CombatContent.CARRIER]
	definitions.append_array(BroadcastContent.ENEMIES)
	for definition: EnemyDefinition in definitions:
		label_text(tr(definition.name_key), 28)
		label_text(tr(definition.description_key), 23)
		label_text(tr("BROADCAST_SEEN" if String(definition.id) in profile.broadcast.enemies else "BROADCAST_UNSEEN"), 21)
	button(tr("MENU_BACK"), show_home)

func show_logs() -> void:
	clear()
	label_text(tr("BROADCAST_LOGS"), 36)
	for mission: int in range(1, profile.campaign.cleared + 1):
		label_text(tr(CampaignContent.MISSIONS[mission - 1].name_key), 27)
		label_text(tr("BROADCAST_LOG_" + str(mission)), 23)
		var medal: String = BroadcastProfile.medal_key(mission)
		label_text(tr("BROADCAST_MEDAL_" + medal.to_upper()) + ("  ✓" if profile.broadcast.medals.has(str(mission)) else ""), 23)
	if profile.campaign.cleared == 0: label_text(tr("BROADCAST_LOGS_EMPTY"), 23)
	button(tr("MENU_BACK"), show_home)
