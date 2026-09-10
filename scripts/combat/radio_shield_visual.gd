class_name RadioShieldVisual
extends RefCounted
## Read the actual temporary reserve; visuals disappear on absorption or expiry.
static func reserve(session: CombatSession) -> float:
	return session.supports.overshield if session.supports != null and session.supports.overshield_left > 0 else 0.0

static func seconds_left(session: CombatSession) -> float:
	return session.supports.overshield_left if reserve(session) > 0 else 0.0

static func draw_boost(canvas: CombatArena) -> void:
	var amount: float = reserve(canvas.session)
	if amount <= 0: return
	var reduced: bool = RadioPreferences.current.enabled("reduced_flash")
	var low: bool = RadioPreferences.current.enabled("low_effects")
	var tint: Color = Color("c4aff5")
	var center: Vector2 = Vector2(320,CombatArena.SHIELD_LINE_Y)
	var polygon: PackedVector2Array = PackedVector2Array([center])
	for index: int in 33:
		polygon.append(center + Vector2(cos(PI + index*PI/32)*230,sin(PI + index*PI/32)*105))
	canvas.draw_colored_polygon(polygon,Color(tint,.09 if reduced else .13))
	var rim: PackedVector2Array = []
	for index: int in 33: rim.append(polygon[index+1])
	canvas.draw_polyline(rim,Color(tint,.8),4,true)
	canvas.draw_line(center+Vector2(-230,0),center+Vector2(230,0),tint,5,true)
	if not low:
		for index: int in 7:
			var angle: float = PI + (index+.5)*PI/7
			var at: Vector2 = center+Vector2(cos(angle)*216,sin(angle)*94)
			canvas.draw_line(at,at+Vector2(0,-6),Color(tint,.6),2,true)
	# Small shield crest and reserve sit on the dome, above the station.
	var at: Vector2 = center + Vector2(0,-83)
	canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(-13,-14),at+Vector2(13,-14),at+Vector2(11,1),at+Vector2(0,10),at+Vector2(-11,1)]),Color("77669f"))
	canvas.draw_line(at+Vector2(0,-10),at+Vector2(0,2),Color("f0e5ff"),2,true)
	canvas.draw_line(at+Vector2(-6,-4),at+Vector2(6,-4),Color("f0e5ff"),2,true)
	canvas.draw_string(ThemeDB.fallback_font,at+Vector2(-40,34),"+%d" % ceili(amount),HORIZONTAL_ALIGNMENT_CENTER,80,24,Color("eee4ff"))
