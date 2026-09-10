class_name RadioEffects
extends RefCounted
## Presentation-only geometry: bounded sampling, no random numbers or gameplay writes.
static func net(canvas: CombatArena, center: Vector2, radius: float, tint: Color) -> void:
	var low: bool = RadioPreferences.current.enabled("low_effects")
	var phase: float = canvas.waveform_time
	canvas.draw_circle(center, radius, Color(tint, .045))
	# Two diagonal strand families are clipped to the real circular hit area.
	var strands: int = 3 if low else 5
	for slope: int in [-1, 1]:
		var axis: Vector2 = Vector2(1, slope).normalized()
		var normal: Vector2 = axis.orthogonal()
		for index: int in range(-strands, strands + 1):
			var offset: float = radius * index / (strands + 1.0)
			var half: float = sqrt(maxf(0, radius * radius - offset * offset))
			var middle: Vector2 = center + normal * offset
			canvas.draw_line(middle - axis * half, middle + axis * half, Color(tint, .26), 1.4, true)
	# Small energized anchors distinguish this field from a target marker.
	for index: int in 8:
		var angle: float = index * TAU / 8
		var at: Vector2 = center + Vector2.from_angle(angle) * radius
		canvas.draw_arc(center, radius, angle - .12, angle + .12, 4, Color(tint, .65), 2, true)
		canvas.draw_circle(at, 2.5, Color(tint, .7))
	if low: return
	for index: int in 5:
		var t: float = fposmod(phase * .28 + index * .2, 1)
		var at: Vector2 = center + Vector2.from_angle(index * 2.4) * radius * (t * 1.6 - .8)
		canvas.draw_circle(at, 3.5, Color(tint, .28))
		canvas.draw_circle(at, 1.4, Color("dbfff7"))

static func bass(canvas: CombatArena, center: Vector2, radius: float, tint: Color, age: float) -> void:
	var low: bool = RadioPreferences.current.enabled("low_effects")
	var reduced: bool = RadioPreferences.current.enabled("reduced_flash")
	var steps: int = 24 if low else 48
	var fade: float = (1 - age) * (.42 if reduced else .78)
	# A pressure front expands from the real impact, with a broad soft trailing band.
	for band: int in (1 if low else 2):
		var progress: float = clampf(age * 1.25 - band * .18, 0, 1)
		var outer: float = radius * (.18 + progress * .82)
		var inner: float = maxf(0, outer - radius * .10 * (1 - progress))
		var mesh: PackedVector2Array = []
		for index: int in steps + 1: mesh.append(center + Vector2.from_angle(PI * .94 + index * PI * 1.12 / steps) * outer)
		for index: int in range(steps, -1, -1): mesh.append(center + Vector2.from_angle(PI * .94 + index * PI * 1.12 / steps) * inner)
		if inner > 0 and outer > inner: canvas.draw_colored_polygon(mesh, Color(tint, fade * .20))
		canvas.draw_arc(center, outer, PI * .94, PI * 2.06, steps, Color(tint, fade / (band + 1)), 3.0 if band == 0 else 1.4, true)
	if not low:
		for index: int in 7:
			var direction: Vector2 = Vector2.from_angle(-PI + index * PI / 6)
			var distance: float = radius * (.2 + age * .65)
			canvas.draw_line(center + direction * distance, center + direction * minf(radius, distance + 8), Color(tint, fade * .55), 2, true)

static func tower(canvas: CombatArena, start: Vector2, end: Vector2, chassis: String, age: float, tint: Color) -> void:
	var reduced: bool = RadioPreferences.current.enabled("reduced_flash")
	var fade: float = (1 - age) * (.55 if reduced else .85)
	var axis: Vector2 = start.direction_to(end)
	if chassis == "sweep":
		canvas._sound_path(start, end, Color(tint, fade * .18), 4, 54, canvas.waveform_time * 8, 12)
		canvas._sound_path(start, end, Color(tint, fade), 6, 54, canvas.waveform_time * 8, 2.4)
		canvas._sound_path(start, end, Color("e0fff0", fade * .65), -6, 54, canvas.waveform_time * 8, 1.2)
	else:
		var count: int = 3
		for index: int in count:
			var t: float = clampf(age * 2.3 - index * .11, 0, 1)
			var at: Vector2 = start.lerp(end, t)
			canvas.draw_arc(at, 12 + index * 7, axis.angle() - .85, axis.angle() + .85, 12, Color(tint, fade), 3, true)
	# A compact contact spark shows hits without hiding the enemy silhouette.
	canvas.draw_line(end - axis * 5, end + axis * 5, Color("f4e6bd", fade), 2, true)
	canvas.draw_line(end - axis.orthogonal() * 4, end + axis.orthogonal() * 4, Color(tint, fade), 2, true)
