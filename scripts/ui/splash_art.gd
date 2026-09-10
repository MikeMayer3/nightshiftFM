class_name SplashArt
extends Control
## Full-bleed station key art. Keep the complete composition visible on wide windows.
const ART: Texture2D = preload("res://assets/art/splash/nightshift_station.png")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("07111b"))
	var scale_factor: float = size.y / ART.get_height()
	var extent: Vector2 = ART.get_size() * scale_factor
	# Portrait uses a modest center crop. Wide windows retain the tower and station.
	if extent.x < size.x and size.x / size.y < .85:
		scale_factor = size.x / ART.get_width()
		extent = ART.get_size() * scale_factor
	draw_texture_rect(ART, Rect2((size - extent) * .5, extent), false)
	# Only the text/button edges receive a soft scrim; the artwork stays clear.
	for band: int in 24:
		var alpha: float = .34 * pow(1.0 - float(band) / 24, 2)
		draw_rect(Rect2(0, band * size.y * .009, size.x, size.y * .01), Color(0.01, .035, .06, alpha))
		draw_rect(Rect2(0, size.y - (band + 1) * size.y * .009, size.x, size.y * .01), Color(0.01, .035, .06, alpha + .08))
