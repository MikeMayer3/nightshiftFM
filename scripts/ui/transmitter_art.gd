class_name TransmitterArt
extends Control
## Original radio-console art; no gameplay RNG or combat state.
const RADIO: Texture2D = preload("res://assets/art/radio/pulse.svg")

var show_signal: bool = true

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var center: Vector2 = Vector2(size.x * 0.5, 105.0)
	var mint: Color = Color(0.46, 0.86, 0.78)
	if show_signal:
		for radius: float in [45.0, 72.0, 99.0]:
			draw_arc(center, radius, PI * 1.12, PI * 1.88, 32, mint, 3.0, true)
	draw_texture_rect(RADIO, Rect2(Vector2(size.x * .5 - 110, 25), Vector2(220, 220)), false)

func _cabinet_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.16, 0.21)
	style.border_color = Color(0.46, 0.86, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
