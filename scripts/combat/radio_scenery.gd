class_name RadioScenery
extends RefCounted
## Original vector scenery in deck coordinates; no simulation state or random draws.
static func background(canvas: CombatArena, era: int, low: bool) -> void:
	var sky: Color = [Color("0c1925"), Color("101d2c"), Color("0c222a")][era]
	canvas.draw_rect(Rect2(0, 0, 640, 720), sky)
	var ridge: PackedVector2Array = PackedVector2Array([Vector2(0,270),Vector2(76,167),Vector2(136,218),Vector2(240,94),Vector2(304,184),Vector2(360,132),Vector2(465,232),Vector2(540,155),Vector2(640,252),Vector2(640,380),Vector2(0,380)])
	canvas.draw_colored_polygon(ridge, Color("182d3c"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(136,218),Vector2(240,94),Vector2(304,184),Vector2(257,164),Vector2(240,128),Vector2(203,185)]), Color("203747"))
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,313),Vector2(92,261),Vector2(186,302),Vector2(299,246),Vector2(415,312),Vector2(540,256),Vector2(640,306),Vector2(640,450),Vector2(0,450)]), Color("122634"))
	# Broad dark foothills leave the action corridor calm and high contrast.
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(0,370),Vector2(126,350),Vector2(286,390),Vector2(454,349),Vector2(640,377),Vector2(640,720),Vector2(0,720)]), Color("0f222e"))
	for side: int in [-1,1]:
		for index: int in (3 if low else 6):
			var x: float = 22 + (index % 2) * 23 if side == -1 else 618 - (index % 2) * 23
			var y: float = 244 + index * 60.0
			pine(canvas, Vector2(x,y), 45 + index * 7, Color("192f3b") if index < 3 else Color("0b1a25"))
	if not low:
		for index: int in 12:
			canvas.draw_circle(Vector2(28 + index * 51, 56 + (index * 29) % 69), 1.2, Color("355466"))
	canvas.draw_rect(Rect2(0,610,640,110),Color("122c37"))
	canvas.draw_line(Vector2(0,716),Vector2(640,716),Color("304957"),3)

static func pine(canvas: CombatArena, at: Vector2, height: float, tint: Color) -> void:
	canvas.draw_line(at, at + Vector2(0,height), tint, 4)
	for tier: int in 3:
		var y: float = tier * height * .19
		var half: float = height * (.18 + tier * .05)
		canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(0,y),at+Vector2(-half,y+height*.43),at+Vector2(half,y+height*.43)]),tint)

static func lit_windows(health_fraction: float) -> int:
	return 3 if health_fraction > .65 else 2 if health_fraction > .3 else 1 if health_fraction > 0 else 0

static func station(canvas: CombatArena) -> void:
	# Local to the central instrument: the transmitter sits on this studio roof.
	var ratio: float = canvas.session.hull / canvas.session.maximum_hull()
	var lit: int = lit_windows(ratio)
	var outline: Color = Color("547681")
	canvas.draw_rect(Rect2(-43,9,86,30),Color("172b38"))
	canvas.draw_rect(Rect2(-43,9,86,30),outline,false,1.5)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-50,10),Vector2(-38,3),Vector2(36,3),Vector2(49,10)]),Color("365360"))
	for index: int in 3:
		var bright: bool = index < lit
		var tint: Color = Color("e7ad70") if bright else Color("263b48")
		if bright and canvas.hit_flash > 0 and not RadioPreferences.current.enabled("reduced_flash"):
			tint = tint.darkened(.35 * (sin(canvas.waveform_time * 22) * .5 + .5))
		canvas.draw_rect(Rect2(-34+index*23,17,17,14),tint)
		canvas.draw_line(Vector2(-26+index*23,17),Vector2(-26+index*23,31),Color("1b2e39"),2)
	if ratio <= .3:
		canvas.draw_polyline(PackedVector2Array([Vector2(30,11),Vector2(25,20),Vector2(31,25),Vector2(27,35)]),Color("081923"),2)
