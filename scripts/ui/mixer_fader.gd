class_name MixerFader
extends VSlider
var accent: Color = Color("eba85c")

func _ready() -> void:
	min_value = 0
	max_value = MixerState.LIMIT
	step = 1
	custom_minimum_size = Vector2(116, 224)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rail: StyleBoxFlat = StyleBoxFlat.new()
	rail.bg_color = Color("050d14")
	rail.border_color = Color("36434a")
	rail.set_border_width_all(2)
	rail.content_margin_left = 5
	rail.content_margin_right = 5
	add_theme_stylebox_override("slider", rail)
	var cap: Texture2D = preload("res://assets/art/radio/mixer_fader.svg")
	for key: String in ["grabber", "grabber_highlight", "grabber_disabled"]: add_theme_icon_override(key, cap)
	value_changed.connect(func(_value: float) -> void: queue_redraw())

func _draw() -> void:
	for mark: int in 17:
		var y: float = 19 + (size.y - 38) * mark / 16.0
		var wide: bool = mark % 4 == 0
		draw_line(Vector2(8, y), Vector2(24 if wide else 18, y), Color("63757a"), 2)
		draw_line(Vector2(size.x - 24 if wide else size.x - 18, y), Vector2(size.x - 8, y), Color("63757a"), 2)
	for pip: int in 4:
		var y: float = size.y - 36 - pip * (size.y - 72) / 4.0
		draw_rect(Rect2(size.x - 6, y, 4, 22), accent if pip < int(value) else Color("263a3d"))
