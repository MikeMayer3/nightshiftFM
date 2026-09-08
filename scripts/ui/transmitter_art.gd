class_name TransmitterArt
extends Control
## Original static geometric placeholder; no external assets, audio, RNG, or combat.

var show_signal: bool = true

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var center: Vector2 = Vector2(size.x * 0.5, 105.0)
	var mint: Color = Color(0.46, 0.86, 0.78)
	if show_signal:
		for radius: float in [45.0, 72.0, 99.0]:
			draw_arc(center, radius, PI * 1.12, PI * 1.88, 32, mint, 3.0, true)
	draw_line(center, center + Vector2(0, 66), mint, 6.0, true)
	draw_circle(center, 8.0, mint)
	draw_style_box(_cabinet_style(), Rect2(center + Vector2(-110, 66), Vector2(220, 70)))
	for index: int in 6:
		draw_line(center + Vector2(-85 + index * 12, 86), center + Vector2(-85 + index * 12, 116), mint, 3.0)
	draw_circle(center + Vector2(72, 101), 17.0, Color(0.97, 0.69, 0.4))

func _cabinet_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.16, 0.21)
	style.border_color = Color(0.46, 0.86, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style
