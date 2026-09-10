class_name ProgressionCard
extends PanelContainer
var row: Dictionary
var caption: String = ""
var title_label: Label
var requirement_label: Label
var badge: Label
var meter: ProgressBar

func _ready() -> void:
	name = "Reward_" + row.kind + "_" + row.id
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_stylebox_override("panel", RadioUI.surface())
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	var heading: HBoxContainer = HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	body.add_child(heading)
	var texture: Texture2D = DraftPanel.ICONS.shield
	if row.kind == "main": texture = RadioArt.MAIN[row.id]
	elif row.kind in ["support", "color"]: texture = DraftPanel.ICONS[StringName(row.id)]
	elif row.kind == "title": texture = preload("res://assets/art/equipment/title_reward.svg")
	var art: TextureRect = RadioUI.art(heading, texture, 76)
	if row.kind == "color": art.modulate = DraftPanel.ACCENTS[StringName(row.id)]
	elif row.state == "locked": art.modulate = Color("607884")
	var titles: VBoxContainer = VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(titles)
	var state_text: String = tr("P6_" + String(row.state).to_upper())
	if not caption.is_empty(): state_text = caption if caption == tr("P6_NEW") else caption + " · " + state_text
	badge = label(titles, state_text, 20)
	badge.modulate = Color("e8bb7a") if row.state == "locked" else Color("9de1bf")
	title_label = label(titles, row.name, 26)
	requirement_label = label(body, row.requirement, 22)
	if row.target > 0:
		var progress: HBoxContainer = HBoxContainer.new()
		progress.add_theme_constant_override("separation", 12)
		body.add_child(progress)
		meter = ProgressBar.new()
		meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meter.custom_minimum_size.y = 12
		meter.show_percentage = false
		meter.max_value = row.target
		meter.value = row.count
		progress.add_child(meter)
		label(progress, "%d / %d" % [row.count, row.target], 20)

func label(parent: Node, text: String, font_size: int) -> Label:
	var node: Label = Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", font_size)
	parent.add_child(node)
	return node

static func add_to(parent: Node, data: Dictionary, heading: String = "") -> ProgressionCard:
	var card: ProgressionCard = ProgressionCard.new()
	card.row = data
	card.caption = heading
	parent.add_child(card)
	return card
