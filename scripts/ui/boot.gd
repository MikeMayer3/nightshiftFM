class_name BootScreen
extends Control

enum Page { MENU, START_PLACEHOLDER, SETTINGS, MOBILE_CHECKS, COMBAT, ARSENAL, CAMPAIGN }
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
var campaign_panel: CampaignPanel
var mission_profile: MissionProfile = MissionProfile.new()
var mission_index: int = 1
var modules: Array[StringName] = []
var picker: ArsenalPicker
var loadout: Dictionary = ArsenalContent.DEFAULT.duplicate()
var save_path: String = "user://m3_mission.json"
var continue_button: Button
var _continuing: bool = false
var combat: CombatScreen
var current_page: Page = Page.MENU

@onready var menu: VBoxContainer = $Margin/Column/Menu
@onready var start_placeholder: VBoxContainer = $Margin/Column/StartPlaceholder
@onready var settings: VBoxContainer = $Margin/Column/Settings
@onready var transmitter: TransmitterArt = $Margin/Column/Transmitter
@onready var probe: MobileProbe = $MobileProbe

func _ready() -> void:
	# Literal localization keys also remain visible to the editor's string extractor.
	(menu.get_node("Start") as Button).pressed.connect(show_page.bind(Page.CAMPAIGN))
	(menu.get_node("Settings") as Button).pressed.connect(show_page.bind(Page.SETTINGS))
	(menu.get_node("Quit") as Button).pressed.connect(_quit)
	(menu.get_node("MobileChecks") as Button).pressed.connect(show_page.bind(Page.MOBILE_CHECKS))
	probe.back_requested.connect(show_page.bind(Page.MENU))
	(start_placeholder.get_node("Back") as Button).pressed.connect(show_page.bind(Page.MENU))
	(settings.get_node("Back") as Button).pressed.connect(show_page.bind(Page.MENU))
	(settings.get_node("ShowSignal") as CheckButton).toggled.connect(_set_signal_visible)
	continue_button = Button.new()
	continue_button.text = tr("M3_CONTINUE")
	continue_button.custom_minimum_size.y = 84
	continue_button.add_theme_font_size_override("font_size", 28)
	menu.add_child(continue_button)
	menu.move_child(continue_button, 1)
	continue_button.pressed.connect(func() -> void:
		_continuing = true
		show_page(Page.COMBAT))
	show_page(Page.MENU)

func show_page(page: Page) -> void:
	if campaign_panel != null:
		remove_child(campaign_panel)
		campaign_panel.queue_free()
		campaign_panel = null
	if picker != null:
		remove_child(picker)
		picker.queue_free()
		picker = null
	if combat != null:
		remove_child(combat)
		combat.queue_free()
		combat = null
	current_page = page
	menu.visible = page == Page.MENU
	start_placeholder.visible = page == Page.START_PLACEHOLDER
	settings.visible = page == Page.SETTINGS
	($Margin as MarginContainer).visible = page not in [Page.MOBILE_CHECKS, Page.COMBAT, Page.ARSENAL, Page.CAMPAIGN]
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
		add_child(campaign_panel)
		campaign_panel.back_requested.connect(show_page.bind(Page.MENU))
		campaign_panel.changed.connect(_save_profile)
		campaign_panel.selected.connect(func(mission: int) -> void:
			mission_index = mission
			show_page(Page.ARSENAL))
	if page == Page.ARSENAL:
		picker = ArsenalPicker.new()
		picker.campaign_profile = mission_profile.campaign
		picker.mission_index = mission_index
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
			(settings.get_node("ShowSignal") as CheckButton).grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_back") and current_page not in [Page.MENU, Page.COMBAT]:
		show_page(Page.MENU)
		get_viewport().set_input_as_handled()

func _set_signal_visible(enabled: bool) -> void:
	transmitter.show_signal = enabled
	transmitter.queue_redraw()

func _quit() -> void:
	get_tree().quit(0)

func _save_profile() -> void:
	var store: MissionStore = MissionStore.new(save_path)
	var data: Dictionary = store.load_save()
	var result: Error = store.error
	if result == OK: result = store.save(mission_profile, data.get("run") if data.get("run") != null else {})
	if campaign_panel != null and is_instance_valid(campaign_panel.notice): campaign_panel.notice.text = tr("M7_SAVED" if result == OK else "M3_SAVE_ERROR")
	if picker != null and picker.preview != null:
		picker.refresh_preview()
		picker.preview.text += "\n" + tr("M7_SAVED" if result == OK else "M3_SAVE_ERROR")
