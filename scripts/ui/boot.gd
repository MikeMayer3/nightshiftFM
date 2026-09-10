class_name BootScreen
extends Control

enum Page { MENU, START_PLACEHOLDER, SETTINGS, MOBILE_CHECKS, COMBAT, ARSENAL, CAMPAIGN }
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
var campaign_panel: CampaignPanel
var mission_profile: MissionProfile = MissionProfile.new()
var broadcast_context: Dictionary = {"mode": "campaign", "difficulty": 0, "contract": ""}
var mission_index: int = 1
var modules: Array[StringName] = []
var picker: ArsenalPicker
var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
var save_path: String = "user://m3_mission.json"
var continue_button: Button
var _continuing: bool = false
var combat: CombatScreen
var current_page: Page = Page.MENU
var splash: SplashArt
var settings_panel: RadioSettingsPanel

@onready var menu: VBoxContainer = $Margin/Column/Menu
@onready var start_placeholder: VBoxContainer = $Margin/Column/StartPlaceholder
@onready var settings: VBoxContainer = $Margin/Column/Settings
@onready var transmitter: TransmitterArt = $Margin/Column/Transmitter
@onready var probe: MobileProbe = $MobileProbe

func _ready() -> void:
	get_window().go_back_requested.connect(_system_back)
	# Literal localization keys also remain visible to the editor's string extractor.
	(menu.get_node("Start") as Button).pressed.connect(show_page.bind(Page.CAMPAIGN))
	(menu.get_node("Settings") as Button).pressed.connect(show_page.bind(Page.SETTINGS))
	(menu.get_node("Quit") as Button).pressed.connect(_quit)
	(menu.get_node("MobileChecks") as Button).pressed.connect(show_page.bind(Page.MOBILE_CHECKS))
	probe.back_requested.connect(show_page.bind(Page.MENU))
	(start_placeholder.get_node("Back") as Button).pressed.connect(show_page.bind(Page.MENU))
	settings.queue_free()
	settings_panel = RadioSettingsPanel.new()
	add_child(settings_panel)
	settings = settings_panel.column
	settings_panel.back_requested.connect(show_page.bind(Page.MENU))
	RadioPreferences.current.changed.connect(func() -> void: _set_signal_visible(RadioPreferences.current.enabled("show_signal")))
	_set_signal_visible(RadioPreferences.current.enabled("show_signal"))
	continue_button = Button.new()
	continue_button.text = tr("M3_CONTINUE")
	continue_button.custom_minimum_size.y = 84
	continue_button.add_theme_font_size_override("font_size", 28)
	menu.add_child(continue_button)
	menu.move_child(continue_button, 1)
	continue_button.pressed.connect(func() -> void:
		_continuing = true
		show_page(Page.COMBAT))
	for child: Node in menu.get_children():
		if child is Button: RadioUI.button(child, child.name == "Start")
	_setup_splash()
	show_page(Page.MENU)

func _setup_splash() -> void:
	splash = SplashArt.new()
	splash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(splash)
	move_child(splash, 0)
	($Margin as SafeMargin).base_margins = Vector4(48, 48, 48, 32)
	var column: VBoxContainer = $Margin/Column
	column.add_theme_constant_override("separation", 10)
	($Margin/Column/Eyebrow as Label).text = tr("SPLASH_EYEBROW")
	($Margin/Column/Eyebrow as Label).add_theme_font_size_override("font_size", 20)
	($Margin/Column/Title as Label).add_theme_font_size_override("font_size", 66)
	($Margin/Column/Title as Label).add_theme_color_override("font_color", Color("f1dec0"))
	transmitter.hide()
	column.move_child($Margin/Column/Spacer, menu.get_index())
	($Margin/Column/Footer as Label).hide()
	(menu.get_node("MobileChecks") as Button).hide()
	(menu.get_node("Quit") as Button).visible = not OS.has_feature("android") and not OS.has_feature("ios")
	menu.add_theme_constant_override("separation", 10)
	for child: Node in menu.get_children():
		if child is Button:
			child.custom_minimum_size.y = 64 if child.name in ["Settings", "Quit"] else 76
			child.add_theme_font_size_override("font_size", 25)
			if child.name in ["Settings", "Quit"]:
				var secondary: StyleBoxFlat = RadioUI.surface("0c1c28", "34474e")
				secondary.bg_color.a = .84
				child.add_theme_stylebox_override("normal", secondary)

func show_page(page: Page) -> void:
	var returning_to_route: bool = current_page == Page.ARSENAL and page == Page.CAMPAIGN
	if campaign_panel != null:
		remove_child(campaign_panel)
		campaign_panel.queue_free()
		campaign_panel = null
	if picker != null:
		loadout = picker.selection.duplicate()
		modules = picker.modules.duplicate()
		remove_child(picker)
		picker.queue_free()
		picker = null
	if combat != null:
		remove_child(combat)
		combat.queue_free()
		combat = null
	current_page = page
	if splash != null: splash.visible = page == Page.MENU
	menu.visible = page == Page.MENU
	start_placeholder.visible = page == Page.START_PLACEHOLDER
	settings.visible = page == Page.SETTINGS
	settings_panel.visible = page == Page.SETTINGS
	($Margin as MarginContainer).visible = page not in [Page.SETTINGS, Page.MOBILE_CHECKS, Page.COMBAT, Page.ARSENAL, Page.CAMPAIGN]
	probe.set_enabled(page == Page.MOBILE_CHECKS)
	if page == Page.CAMPAIGN:
		var saved: MissionStore = MissionStore.new(save_path)
		var data: Dictionary = saved.load_save()
		if saved.error != OK:
			_continuing = true
			show_page(Page.COMBAT)
			return
		mission_profile = MissionProfile.new()
		if not data.is_empty(): mission_profile.restore(data.profile)
		campaign_panel = CampaignPanel.new()
		campaign_panel.profile = mission_profile
		campaign_panel.rules = broadcast_context.duplicate()
		if returning_to_route: campaign_panel.selected_mission = mission_index
		add_child(campaign_panel)
		campaign_panel.back_requested.connect(show_page.bind(Page.MENU))
		campaign_panel.changed.connect(_save_profile)
		campaign_panel.selected.connect(func(mission: int) -> void:
			mission_index = mission
			broadcast_context = campaign_panel.rules.duplicate()
			show_page(Page.ARSENAL))
	if page == Page.ARSENAL:
		picker = ArsenalPicker.new()
		picker.campaign_profile = mission_profile.campaign
		picker.mission_index = mission_index
		picker.broadcast_context = broadcast_context.duplicate()
		if CampaignContent.valid_selection(loadout, modules, mission_profile.campaign.cleared):
			picker.selection = loadout.duplicate()
			picker.modules = modules.duplicate()
		add_child(picker)
		picker.back_requested.connect(show_page.bind(Page.CAMPAIGN))
		picker.settings_changed.connect(_save_profile)
		picker.campaign_launched.connect(func(mission: int, chosen: Dictionary, selected_modules: Array[StringName]) -> void:
			mission_index = mission
			loadout = chosen.duplicate()
			modules = selected_modules.duplicate()
			show_page(Page.COMBAT))
		picker.launched.connect(func(chosen: Dictionary) -> void:
			loadout = chosen.duplicate()
			show_page(Page.COMBAT))
	if page == Page.COMBAT:
		combat = COMBAT_SCENE.instantiate() as CombatScreen
		combat.m3_enabled = true
		combat.m4_enabled = true
		combat.signal_enabled = true
		combat.active_enabled = true
		combat.arsenal_enabled = true
		combat.patchboard_enabled = true
		combat.campaign_enabled = true
		combat.campaign_mission = mission_index
		combat.broadcast_context = broadcast_context.duplicate()
		combat.campaign_modules = modules.duplicate()
		combat.loadout = loadout.duplicate()
		combat.resume_existing = _continuing
		combat.store = MissionStore.new(save_path)
		_continuing = false
		add_child(combat)
		combat.back_requested.connect(show_page.bind(Page.MENU))
	elif page != Page.MOBILE_CHECKS:
		get_tree().paused = false
	match page:
		Page.MENU:
			var saved: MissionStore = MissionStore.new(save_path)
			var data: Dictionary = saved.load_save()
			continue_button.visible = saved.error != OK or data.get("run") != null and not data.run.is_empty()
			(menu.get_node("Start") as Button).grab_focus()
		Page.START_PLACEHOLDER:
			(start_placeholder.get_node("Back") as Button).grab_focus()
		Page.SETTINGS:
			settings_panel.toggles.reduced_flash.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back") and current_page not in [Page.MENU, Page.COMBAT]:
		_system_back()
		get_viewport().set_input_as_handled()

func _set_signal_visible(enabled: bool) -> void:
	transmitter.show_signal = enabled
	transmitter.queue_redraw()

func _system_back() -> void:
	if current_page == Page.COMBAT and combat != null:
		if combat.settings_panel != null:
			combat.settings_panel.back_requested.emit()
		elif not combat.manual_pause:
			combat.toggle_pause()
	elif current_page == Page.MENU:
		_quit()
	else:
		show_page(Page.CAMPAIGN if current_page == Page.ARSENAL else Page.MENU)

func _quit() -> void:
	get_tree().quit(0)

func _save_profile() -> void:
	var store: MissionStore = MissionStore.new(save_path)
	var data: Dictionary = store.load_save()
	var result: Error = store.error
	if result == OK: result = store.save(mission_profile, data.get("run") if data.get("run") != null else {})
	if campaign_panel != null and is_instance_valid(campaign_panel.notice):
		campaign_panel.notice.text = tr("M7_SAVED" if result == OK else "M3_SAVE_ERROR")
		campaign_panel.notice.show()
	if picker != null and picker.preview != null:
		picker.refresh_preview()
		picker.notice.text = tr("M7_SAVED" if result == OK else "M3_SAVE_ERROR")
