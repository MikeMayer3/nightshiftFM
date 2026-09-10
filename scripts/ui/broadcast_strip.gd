class_name BroadcastStrip
extends PanelContainer
## A fixed console slot keeps captions outside combat and prevents layout jumps.
var caption: Label
var icon: TextureRect
var state: RadioBroadcast
var surface: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size.y = 104
	surface = RadioUI.surface("101f2a", "365351")
	add_theme_stylebox_override("panel", surface)
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	icon = TextureRect.new()
	icon.texture = preload("res://assets/art/radio/aerial.svg")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size.x = 52
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.add_theme_font_size_override("font_size", 22)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption)

func refresh(s: CombatSession) -> void:
	visible = RadioBroadcast.enabled(s)
	if not visible: return
	var speaking: bool = not state.key.is_empty() and not s.is_finished()
	caption.text = tr(state.key if speaking else "P4_IDLE")
	var color: Color = Color("efb178") if state.approaching else Color("88c9bf")
	surface.border_color = color if speaking else Color("365351")
	icon.texture = preload("res://assets/art/radio/caller.svg") if state.key.ends_with("W4") or state.key == "P4_CALLER_ARRIVED" else preload("res://assets/art/radio/aerial.svg")
	icon.modulate = color
	caption.add_theme_color_override("font_color", Color("e5eee8") if speaking else Color("93acae"))
