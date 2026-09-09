class_name DraftPanel
extends PanelContainer
signal selected(id: StringName)
signal banished(id: StringName)
signal rerolled
signal recruited(id: StringName)
signal branch_swapped(id: StringName)
signal declined
signal back_requested
var column: VBoxContainer
var cards: Array[Button] = []
var info_buttons: Array[Button] = []
var banish_mode: bool = false
var banish_button: Button
var heading: Label
const ICONS: Dictionary = {
	&"echo_deck": preload("res://assets/art/equipment/echo.svg"),
	&"needle_swarm": preload("res://assets/art/equipment/needle.svg"),
	&"reverb_well": preload("res://assets/art/equipment/reverb.svg"),
	&"main": preload("res://assets/art/equipment/pulse.svg"),
	&"shield": preload("res://assets/art/equipment/shield.svg"),
	&"arc_aerial": preload("res://assets/art/equipment/arc.svg"),
	&"bass_driver": preload("res://assets/art/equipment/bass.svg"),
	&"static_net": preload("res://assets/art/equipment/net.svg"),
	&"repair": preload("res://assets/art/equipment/repair.svg"),
}
const ACCENTS: Dictionary = {
	&"ball_lightning": Color("cab0ff"), &"dead_zone": Color("72badb"), &"b_side": Color("ed93ca"), &"live_wire": Color("d0eb86"),
	&"pressure_drop": Color("8bddb0"), &"double_drop": Color("ffa16c"), &"needle_thread": Color("f3d57b"), &"feedback_loop": Color("f07eaa"),
	&"echo_deck": Color("ed93ca"), &"needle_swarm": Color("f3d57b"), &"reverb_well": Color("8bddb0"),
	&"main": Color("76dbca"), &"shield": Color("efa968"),
	&"bass_driver": Color("efa968"), &"static_net": Color("7ad8ee"),
	&"arc_aerial": Color("bba5f4"), &"repair": Color("96dbac"),
}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("0b1824")
	add_theme_stylebox_override("panel", style)
	var safe: SafeMargin = SafeMargin.new()
	safe.base_margins = Vector4(28, 20, 28, 20)
	add_child(safe)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	safe.add_child(scroll)
	column = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_PASS
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)

func _clear() -> void:
	(column.get_parent() as ScrollContainer).set_deferred("scroll_vertical", 0)
	cards.clear()
	info_buttons.clear()
	for node: Node in column.get_children():
		column.remove_child(node)
		node.queue_free()

func label_text(text: String, parent: Node, font_size: int = 26) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label

func button_text(text: String, parent: Node, action: Callable) -> Button:
	var button: Button = Button.new()
	# Let the ScrollContainer receive touch drags and cancel a scrolling press.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.text = text
	button.custom_minimum_size.y = 76
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func show_draft(session: CombatSession) -> void:
	_clear()
	show()
	var draft: DraftState = session.draft
	heading = label_text(tr("M3_BANISH_TITLE") if banish_mode else tr("M3_BONUS" if draft.bonus else "M3_DRAFT"), column, 42)
	if session.signal_progress != null and not banish_mode: heading.text = tr("SIGNAL_READY")
	var hint: Label = label_text(tr("M3_BANISH_HINT") if banish_mode else tr("M3_PICK_HINT") % session.wave, column, 25)
	if session.signal_progress != null and not banish_mode: hint.text = tr("SIGNAL_HINT")
	hint.modulate = Color("a7bbc8")
	for id: StringName in draft.offers:
		_add_card(session, id)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	column.add_child(actions)
	var reroll: Button = button_text(tr("M3_REROLL") % draft.rerolls, actions, func() -> void: rerolled.emit())
	reroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reroll.disabled = banish_mode or draft.rerolls == 0 or draft.offers[0] in [DraftState.REPAIR, DraftState.REFILL, SignalDraft.OVERDRIVE]
	banish_button = button_text(tr("M3_CANCEL_BANISH") if banish_mode else tr("M3_BANISH_ACTION") % draft.banishes, actions, func() -> void:
		banish_mode = not banish_mode
		show_draft(session))
	banish_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banish_button.disabled = not banish_mode and (draft.banishes == 0 or not draft.offers.any(func(id: StringName) -> bool: return _can_banish(draft, id)))
	var help_button: Button = button_text(tr("M3_HELP"), column, func() -> void: pass)
	help_button.custom_minimum_size.y = 52
	help_button.add_theme_font_size_override("font_size", 23)
	var help_text: Label = label_text(tr("SIGNAL_HELP" if session.signal_progress != null else "M3_HELP_BODY"), column, 25)
	help_text.hide()
	help_button.pressed.connect(func() -> void: help_text.visible = not help_text.visible)
	var menu: Button = button_text(tr("MENU_BACK"), column, func() -> void: back_requested.emit())
	menu.custom_minimum_size.y = 64

func _can_banish(draft: DraftState, id: StringName) -> bool:
	var option: UpgradeDefinition = draft.card(id)
	if option == null or option.required_rank != 0 or draft.banishes == 0: return false
	var excluded: Array[StringName] = draft.banished.duplicate()
	excluded.append(id)
	return not draft.track(option.target_id).eligible(excluded).is_empty()

func _add_card(session: CombatSession, id: StringName) -> void:
	var draft: DraftState = session.draft
	var option: UpgradeDefinition = draft.card(id)
	var identity: StringName = option.target_id if option != null else (&"shield" if id == DraftState.REFILL else &"repair")
	var accent: Color = ACCENTS[identity]
	var card: Button = button_text("", column, func() -> void:
		if banish_mode:
			if not _can_banish(draft, id): return
			banish_mode = false
			banished.emit(id)
		else:
			selected.emit(id))
	card.custom_minimum_size.y = 252
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.disabled = banish_mode and not _can_banish(draft, id)
	cards.append(card)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("152a39")
	style.border_color = accent.darkened(0.55)
	style.set_border_width_all(2)
	style.border_width_left = 6
	style.set_corner_radius_all(14)
	card.add_theme_stylebox_override("normal", style)
	var active: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	active.bg_color = Color("203b4b")
	active.border_color = accent
	for state: String in ["hover", "pressed", "focus"]: card.add_theme_stylebox_override(state, active)
	var inactive: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	inactive.bg_color = Color("101e29")
	inactive.border_color = Color("32404a")
	card.add_theme_stylebox_override("disabled", inactive)
	var inset: MarginContainer = MarginContainer.new()
	inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(inset)
	inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: inset.add_theme_constant_override("margin_" + side, 18)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 18)
	inset.add_child(row)
	var icon: TextureRect = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = ICONS[identity]
	icon.custom_minimum_size = Vector2(96, 96)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var body: VBoxContainer = VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_theme_constant_override("separation", 6)
	row.add_child(body)
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(header)
	var caption: Label = label_text(tr("M3_" + String(identity).to_upper() + "_SHORT_NAME") if option != null else tr("M3_STATION"), header, 22)
	if session.arsenal != null and identity in [&"main", &"shield"]:
		caption.text = tr(draft.track(identity).definition.name_key)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.modulate = accent
	if option != null and id != SignalDraft.OVERDRIVE:
		var owned: UpgradeTrack = draft.track(option.target_id)
		var rank: Label = label_text(tr("SIGNAL_NEW") if owned == null else tr("M3_RANK_SHORT") % [owned.rank(), owned.rank() + 1], header, 22)
		rank.autowrap_mode = TextServer.AUTOWRAP_OFF
		rank.modulate = Color("bdcbd4")
	var info: Button = button_text("i", header, func() -> void: _show_details(session, id))
	info.custom_minimum_size = Vector2(88, 88)
	info.tooltip_text = tr("M3_INFO")
	info.flat = true
	info.add_theme_color_override("font_color", accent)
	info.mouse_filter = Control.MOUSE_FILTER_STOP
	info_buttons.append(info)
	label_text(tr(option.name_key) if option != null else tr("M3_REPAIR_SHORT" if id == DraftState.REPAIR else "M3_REFILL_SHORT"), body, 32)
	label_text(tr(String(option.name_key).trim_suffix("_NAME") + "_SHORT") if option != null else tr("M3_REPAIR_EFFECT" if id == DraftState.REPAIR else "M3_REFILL_EFFECT"), body, 26)
	if card.disabled: inset.modulate = Color("697783")

func _show_details(session: CombatSession, id: StringName) -> void:
	if session.signal_progress != null and (SignalDraft.is_new(id) or id == SignalDraft.OVERDRIVE):
		_clear()
		var option: UpgradeDefinition = session.draft.card(id)
		label_text(tr(option.name_key), column, 42)
		label_text(tr(option.description_key), column, 28)
		button_text(tr("M3_BACK_DRAFT"), column, func() -> void: show_draft(session))
		return
	if session.supports != null and session.draft.card(id) != null:
		_show_m4_details(session, id)
		return
	_clear()
	var option: UpgradeDefinition = session.draft.card(id)
	if option != null:
		var owned: UpgradeTrack = session.draft.track(option.target_id)
		label_text(tr(option.name_key), column, 42)
		label_text(tr("M3_CARD_RANK") % [tr(owned.definition.name_key), owned.rank(), owned.rank() + 1], column, 27)
		label_text(tr(option.description_key), column, 28)
		var requirement: String = tr("M3_COMMON") if option.required_rank == 0 else tr("M3_REQUIRED") % owned.rank()
		if option.prerequisite != &"": requirement += " · " + tr(session.draft.card(option.prerequisite).name_key)
		label_text(requirement, column, 25)
		label_text(tr("M3_DETAILS_PATH"), column, 32)
		label_text(tr(owned.definition.preview_key), column, 27)

	else:
		label_text(tr("M3_REPAIR" if id == DraftState.REPAIR else "M3_REFILL"), column, 32)
	button_text(tr("M3_BACK_DRAFT"), column, func() -> void: show_draft(session))

func show_recruit(session: CombatSession) -> void:
	if session.supports != null:
		_show_m4_recruit(session)
		return
	_clear()
	show()
	banish_mode = false
	label_text(tr("M3_RECRUIT_TITLE"), column, 42)
	var icon: TextureRect = TextureRect.new()
	icon.texture = ICONS[&"arc_aerial"]
	icon.custom_minimum_size = Vector2(160, 160)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	column.add_child(icon)
	label_text(tr("M3_SUPPORT_CAP_NOTE") if session.draft.track(&"arc_aerial").rank() == 8 else tr("M3_RECRUIT_BODY"), column, 28)
	button_text(tr("M3_RECOVERY_CHOICE") if session.draft.track(&"arc_aerial").rank() == 8 else tr("M3_DECLINE"), column, func() -> void: declined.emit())
	button_text(tr("MENU_BACK"), column, func() -> void: back_requested.emit())

func show_recovery(message: String, retry: Callable, fresh: Callable) -> void:
	_clear()
	show()
	label_text(tr("M3_RECOVERY_TITLE"), column, 36)
	label_text(message, column)
	button_text(tr("M3_RETRY"), column, retry)
	button_text(tr("M3_FRESH"), column, fresh)
	button_text(tr("MENU_BACK"), column, func() -> void: back_requested.emit())

func _show_m4_recruit(session: CombatSession) -> void:
	_clear()
	show()
	banish_mode = false
	label_text(tr("M4_RECRUIT"), column, 42)
	label_text(tr("M4_RECRUIT_HINT"), column, 26)
	for definition: TrackDefinition in session.draft.catalog:
		if not definition.support or session.draft.track(definition.id) != null or session.draft.support_count() >= GameRules.MAX_SUPPORTS: continue
		var id: StringName = definition.id
		var recruit_button: Button = button_text(tr(definition.name_key), column, func() -> void: recruited.emit(id))
		recruit_button.icon = ICONS[id]
		recruit_button.expand_icon = true
		recruit_button.add_theme_constant_override("icon_max_width", 72)
		recruit_button.custom_minimum_size.y = 112
		label_text(tr("M4_" + String(id).to_upper() + "_ROLE"), column, 26)
	button_text(tr("M4_KEEP_BUILD"), column, func() -> void: declined.emit())
	button_text(tr("MENU_BACK"), column, func() -> void: back_requested.emit())

func show_report(session: CombatSession, back: Callable) -> void:
	_clear()
	show()
	label_text(tr("M4_REPORT"), column, 42)
	label_text(tr("M4_REPORT_HINT"), column, 24)
	for owned: UpgradeTrack in session.draft.tracks:
		var values: Dictionary = session.supports.report.totals[String(owned.definition.id)]
		label_text(tr(owned.definition.name_key), column, 30)
		var lines: PackedStringArray = []
		for metric: StringName in ContributionReport.METRICS:
			if float(values[String(metric)]) > 0:
				lines.append(tr("M4_METRIC_" + String(metric).to_upper()) % float(values[String(metric)]))
		label_text(" · ".join(lines) if not lines.is_empty() else tr("M4_NO_OUTPUT"), column, 25)
	if session.active_combat != null:
		label_text(tr("ACTIVE_REPORT") % [session.active_combat.uses, session.active_combat.damage], column, 25)
		label_text(tr("ACTIVE_REPORT_HINT"), column, 23)
	if session.patchboard != null:
		label_text(tr("M6_REPORT_TITLE"), column, 34)
		label_text(tr("M6_REPORT_HINT"), column, 23)
		for id: StringName in session.patchboard.discovered():
			var row: Dictionary = session.patchboard.totals[String(id)]
			label_text(tr(PatchboardContent.RECIPES[id].name_key), column, 30)
			label_text(tr("M6_REPORT_ROW") % [row.triggers, row.damage, row.assisted_damage, row.control_seconds, row.interrupts, row.intercepts], column, 24)
	button_text(tr("M4_BACK_RESULTS"), column, back)

func _show_m4_details(session: CombatSession, id: StringName) -> void:
	_clear()
	var option: UpgradeDefinition = session.draft.card(id)
	var owned: UpgradeTrack = session.draft.track(option.target_id)
	label_text(tr(option.name_key), column, 40)
	label_text(tr("M3_CARD_RANK") % [tr(owned.definition.name_key), owned.rank(), owned.rank() + 1], column, 26)
	label_text(tr(option.description_key), column, 27)
	button_text(tr("M3_BACK_DRAFT"), column, func() -> void: show_draft(session))
	if option.required_rank in [3, 6]:
		for alternative: UpgradeDefinition in owned.eligible(session.draft.banished):
			if alternative.id == id or alternative.id in session.draft.offers: continue
			var alternative_id: StringName = alternative.id
			button_text(tr("M4_SWAP_BRANCH") % tr(alternative.name_key), column, func() -> void: branch_swapped.emit(alternative_id))
	if session.arsenal != null:
		var after: UpgradeTrack = UpgradeTrack.new(owned.definition)
		for choice: StringName in owned.choices: after.accept(choice, [])
		after.accept(id, [])
		var before_stats: Dictionary = ArsenalStats.parameters(owned)
		var after_stats: Dictionary = ArsenalStats.parameters(after)
		for key: StringName in after_stats:
			if key in [&"mode", &"modifier", &"capstone", &"m5_marker", &"damage_bonus", &"cadence", &"orbit", &"reserve", &"overheal", &"stagger", &"priority", &"distinct"]: continue
			if not is_equal_approx(float(before_stats.get(key, 0)), float(after_stats[key])):
				label_text(tr("M5_STAT_" + String(key).to_upper()) + ": %.2f → %.2f" % [float(before_stats.get(key, 0)), float(after_stats[key])], column, 24)
	var branch: StringName = option.id if option.required_rank == 3 else &""
	for accepted: StringName in owned.choices:
		if session.draft.card(accepted).required_rank == 3: branch = accepted
	if branch != &"":
		label_text(tr("M3_DETAILS_PATH"), column, 30)
		for future: UpgradeDefinition in owned.definition.options:
			if future.required_rank <= maxi(owned.rank() + 1, 3): continue
			if future.prerequisite != branch and future.prerequisite not in owned.choices: continue
			label_text(tr("M4_PATH_STEP") % [future.required_rank, tr(future.name_key)], column, 25)
			label_text(tr(String(future.name_key).trim_suffix("_NAME") + "_SHORT"), column, 23)
