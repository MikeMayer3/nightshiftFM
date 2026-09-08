class_name SafeMargin
extends MarginContainer

signal safe_area_changed

@export var base_margins: Vector4 = Vector4(56, 70, 56, 70)
@export var show_boundary: bool = false
var canvas_safe_rect: Rect2

func _process(_delta: float) -> void:
	var canvas: Rect2 = Rect2(Vector2.ZERO, get_viewport_rect().size)
	var safe: Rect2 = canvas
	if OS.has_feature("android") or OS.has_feature("ios"):
		safe = SafeArea.to_canvas(Rect2(DisplayServer.get_display_safe_area()),
			get_viewport().get_screen_transform(), canvas)
	if safe == canvas_safe_rect:
		return
	canvas_safe_rect = safe
	add_theme_constant_override("margin_left", int(ceil(base_margins.x + safe.position.x)))
	add_theme_constant_override("margin_top", int(ceil(base_margins.y + safe.position.y)))
	add_theme_constant_override("margin_right", int(ceil(base_margins.z + canvas.end.x - safe.end.x)))
	add_theme_constant_override("margin_bottom", int(ceil(base_margins.w + canvas.end.y - safe.end.y)))
	safe_area_changed.emit()
	queue_redraw()

func _draw() -> void:
	if show_boundary:
		draw_rect(canvas_safe_rect.grow(-2.0), Color(0.46, 0.86, 0.78), false, 2.0)
