class_name BassPayoff
extends RefCounted
## One authored branch's presentation, derived entirely from equipped choices.
const BRANCH: StringName = &"m5.bass_driver.b1"
const CABINET: Texture2D = preload("res://assets/art/equipment/bass_wideband.svg")
static var _front_lines: PackedVector2Array = _make_front()

static func _make_front() -> PackedVector2Array:
	var points: PackedVector2Array = []
	for segment: int in 3:
		var start: float = PI + segment * PI / 3.0 + .045
		var length: float = PI / 3.0 - .09
		for step: int in 12:
			points.append(Vector2.from_angle(start + length * step / 12.0))
			points.append(Vector2.from_angle(start + length * (step + 1) / 12.0))
	return points

static func active(session: CombatSession) -> bool:
	if session == null or session.draft == null: return false
	var track: UpgradeTrack = session.draft.track(&"bass_driver")
	return track != null and BRANCH in track.choices

static func texture(session: CombatSession) -> Texture2D:
	return CABINET if active(session) else DraftPanel.ICONS[&"bass_driver"]

static func pressure(canvas: CombatArena, center: Vector2, radius: float, age: float, tint: Color) -> void:
	# Twin fronts stay INSIDE the real radius and do not represent extra hits.
	# Batch normal segments; low effects keeps two simple arcs without end caps.
	var low: bool = RadioPreferences.current.enabled("low_effects")
	var reduced: bool = RadioPreferences.current.enabled("reduced_flash")
	var fade: float = (1 - age) * (.42 if reduced else .72)
	for front: int in 2:
		var distance: float = radius * clampf(.22 + age * .76 - front * .12, .08, .98)
		if low:
			canvas.draw_arc(center, distance, PI + .045, TAU - .045, 16, Color(tint, fade), 3 if front == 0 else 2, true)
			continue
		var points: PackedVector2Array = []
		for point: Vector2 in _front_lines: points.append(center + point * distance)
		# Outward-facing end caps make the wider front recognizable without color.
		for side: int in [-1, 1]:
			var at: Vector2 = center + Vector2(side * distance * .94, -distance * .20)
			points.append(at); points.append(at + Vector2(-side * 6, -6))
		canvas.draw_multiline(points, Color(tint, fade), 3 if front == 0 else 2, true)
