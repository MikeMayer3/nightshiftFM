class_name PatchboardPanel
extends PanelContainer
signal back_requested
var session: CombatSession
var profile: MissionProfile
var selected_slot: int = 0
var slot_buttons: Array[Button] = []
var recipe_buttons: Dictionary = {}
var launch_button: Button
var scroll: ScrollContainer
var catalog: VBoxContainer
var hint: Label
var known: Array[StringName] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b1824")
	add_theme_stylebox_override("panel", style)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(24, 20, 24, 20)
	add_child(safe)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	safe.add_child(column)
	label(tr("M6_TITLE"), column, 40)
	hint = label(tr("M6_TUTORIAL"), column, 24)
	var slots: HBoxContainer = HBoxContainer.new()
	slots.add_theme_constant_override("separation", 12)
	column.add_child(slots)
	for index: int in 2:
		var button: Button = action("", slots, func() -> void:
			selected_slot = index
			render())
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_buttons.append(button)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	catalog = VBoxContainer.new()
	catalog.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog.add_theme_constant_override("separation", 12)
	scroll.add_child(catalog)
	launch_button = action(tr("M6_LAUNCH"), column, func() -> void:
		if session.launch_wave(): hide())
	action(tr("MENU_BACK"), column, func() -> void: back_requested.emit())
	hide()

func label(text: String, parent: Node, size: int) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size)
	parent.add_child(node)
	return node

func action(text: String, parent: Node, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 76
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.add_theme_font_size_override("font_size", 26)
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func open(value: CombatSession, saved_profile: MissionProfile) -> void:
	session = value
	profile = saved_profile
	known = profile.discovered.duplicate()
	for id: StringName in session.patchboard.discovered():
		if id not in known: known.append(id)
	render()
	show()

func render() -> void:
	var scroll_position: int = scroll.scroll_vertical
	recipe_buttons.clear()
	for child: Node in catalog.get_children():
		catalog.remove_child(child)
		child.queue_free()
	hint.text = tr("M6_TUTORIAL") if session.wave == 0 else tr("M6_INTERMISSION") % (session.wave + 1)
	for index: int in 2:
		var id: StringName = session.patchboard.slots[index]
		slot_buttons[index].text = tr("M6_SLOT") % [index + 1, tr(PatchboardContent.RECIPES[id].name_key) if id != &"" else tr("M6_EMPTY")]
		slot_buttons[index].modulate = Color("76dbca") if selected_slot == index else Color.WHITE
	var clear: Button = action(tr("M6_UNPLUG") % (selected_slot + 1), catalog, func() -> void:
		if session.patchboard.rewire(session, selected_slot, &""): render())
	clear.disabled = session.patchboard.slots[selected_slot] == &""
	var ids: Array = PatchboardContent.RECIPES.keys()
	ids.sort_custom(func(a: StringName, b: StringName) -> bool: return int(PatchboardState.eligible(session, a)) > int(PatchboardState.eligible(session, b)))
	for id: StringName in ids:
		var recipe: SynergyDefinition = PatchboardContent.RECIPES[id]
		var card: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("162b3a")
		style.content_margin_left = 16
		style.content_margin_right = 16
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		style.set_corner_radius_all(10)
		card.add_theme_stylebox_override("panel", style)
		catalog.add_child(card)
		var body: VBoxContainer = VBoxContainer.new()
		body.add_theme_constant_override("separation", 8)
		card.add_child(body)
		label(tr(recipe.name_key) + (" · " + tr("M6_DISCOVERED") if id in known else ""), body, 30)
		label(requirements(recipe), body, 23).modulate = Color("a7bbc8")
		label(tr(recipe.description_key), body, 24)
		var active_slot: int = session.patchboard.slots.find(id)
		var button: Button = action(tr("M6_CONNECTED") % (active_slot + 1) if active_slot >= 0 else tr("M6_CONNECT") % (selected_slot + 1), body, func() -> void:
			if session.patchboard.rewire(session, selected_slot, id): render())
		button.disabled = active_slot >= 0 or not PatchboardState.eligible(session, id)
		recipe_buttons[id] = button
	scroll.set_deferred("scroll_vertical", scroll_position)

func requirements(recipe: SynergyDefinition) -> String:
	var names: PackedStringArray = []
	for endpoint: StringName in recipe.endpoint_ids:
		var owned: UpgradeTrack = session.draft.track(endpoint)
		var name_key: StringName = ArsenalContent.DEFINITIONS[String(endpoint)].name_key if endpoint not in [&"main", &"shield"] else session.draft.track(endpoint).definition.name_key
		names.append(tr(name_key) + (" ✓" if owned != null else " · " + tr("M6_MISSING")))
	if recipe.capability == &"marked": names.append(tr("M6_MARK_REQUIRED"))
	if recipe.capability == &"slowed": names.append(tr("M6_SLOW_REQUIRED"))
	return " + ".join(names)
