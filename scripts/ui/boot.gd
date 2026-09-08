class_name BootScreen
extends Control

enum Page { MENU, START_PLACEHOLDER, SETTINGS, MOBILE_CHECKS, COMBAT }
const COMBAT_SCENE: PackedScene = preload("res://scenes/combat/combat.tscn")
var combat: CombatScreen
var current_page: Page = Page.MENU

@onready var menu: VBoxContainer = $Margin/Column/Menu
@onready var start_placeholder: VBoxContainer = $Margin/Column/StartPlaceholder
@onready var settings: VBoxContainer = $Margin/Column/Settings
@onready var transmitter: TransmitterArt = $Margin/Column/Transmitter
@onready var probe: MobileProbe = $MobileProbe

func _ready() -> void:
	# Literal localization keys also remain visible to the editor's string extractor.
	(menu.get_node("Start") as Button).pressed.connect(show_page.bind(Page.COMBAT))
	(menu.get_node("Settings") as Button).pressed.connect(show_page.bind(Page.SETTINGS))
	(menu.get_node("Quit") as Button).pressed.connect(_quit)
	(menu.get_node("MobileChecks") as Button).pressed.connect(show_page.bind(Page.MOBILE_CHECKS))
	probe.back_requested.connect(show_page.bind(Page.MENU))
	(start_placeholder.get_node("Back") as Button).pressed.connect(show_page.bind(Page.MENU))
	(settings.get_node("Back") as Button).pressed.connect(show_page.bind(Page.MENU))
	(settings.get_node("ShowSignal") as CheckButton).toggled.connect(_set_signal_visible)
	show_page(Page.MENU)

func show_page(page: Page) -> void:
	if combat != null:
		remove_child(combat)
		combat.queue_free()
		combat = null
	current_page = page
	menu.visible = page == Page.MENU
	start_placeholder.visible = page == Page.START_PLACEHOLDER
	settings.visible = page == Page.SETTINGS
	($Margin as MarginContainer).visible = page not in [Page.MOBILE_CHECKS, Page.COMBAT]
	probe.set_enabled(page == Page.MOBILE_CHECKS)
	if page == Page.COMBAT:
		combat = COMBAT_SCENE.instantiate() as CombatScreen
		add_child(combat)
		combat.back_requested.connect(show_page.bind(Page.MENU))
	elif page != Page.MOBILE_CHECKS:
		get_tree().paused = false
	match page:
		Page.MENU:
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
