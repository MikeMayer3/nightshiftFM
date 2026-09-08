class_name SafeArea
extends RefCounted
## Convert OS display pixels through the actual viewport transform, including bars.

static func to_canvas(display_rect: Rect2, canvas_to_screen: Transform2D, canvas: Rect2) -> Rect2:
	if display_rect.size.x <= 0.0 or display_rect.size.y <= 0.0:
		return canvas
	return (canvas_to_screen.affine_inverse() * display_rect).intersection(canvas)
