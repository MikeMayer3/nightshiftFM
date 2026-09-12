class_name RadioFeedback
extends RefCounted
## Short-lived presentation state. Never stored in a checkpoint or applied to actors.
var damage_numbers: DamageNumbers = DamageNumbers.new()
var reactions: Dictionary = {}
var upgrades: Dictionary = {}
var wave: int = 0
var wave_left: float = 0

static func living_enemies(session: CombatSession) -> int:
	var count: int = 0
	for actor: CombatActor in session.actors:
		if not actor.projectile and not actor.resolved and actor.health > 0: count += 1
	return count

static func signal_shape(count: int) -> Vector2:
	# Bounded amplitude and wavelength keep even very crowded waves inside the strip.
	var density: float = maxf(0, count) / (maxf(0, count) + 12.0)
	return Vector2(0 if count <= 0 else 2 + 13 * density, 160 - 132 * density)

static func signal_points(count: int, phase: float) -> PackedVector2Array:
	var shape: Vector2 = signal_shape(count)
	var points: PackedVector2Array = []
	for index: int in 97:
		var t: float = float(index) / 96
		points.append(Vector2(225 + 385*t,20 + sin(t*385/shape.y*TAU-phase)*shape.x*sin(t*PI)))
	return points

func advance(delta: float) -> void:
	damage_numbers.advance(delta)
	wave_left = maxf(0, wave_left - delta)
	for id: int in reactions.keys():
		reactions[id].left -= delta
		if reactions[id].left <= 0: reactions.erase(id)
	for id: StringName in upgrades.keys():
		upgrades[id] -= delta
		if upgrades[id] <= 0: upgrades.erase(id)

func hit(event: CombatEvent) -> void:
	if event.kind != CombatEvent.Kind.DAMAGE or event.amount <= 0: return
	if not reactions.has(event.target_id) and reactions.size() >= 128: reactions.erase(reactions.keys()[0])
	reactions[event.target_id] = {"left":.22,"source":event.source_id}

func announce(number: int) -> void:
	wave = number; wave_left = 2.4

func upgrade(id: StringName) -> void:
	if id in ArsenalContent.FAMILIES or id in [&"main",&"shield",&"repair"]: upgrades[id] = 1.3

func reset() -> void:
	damage_numbers.clear()
	reactions.clear(); upgrades.clear(); wave = 0; wave_left = 0

func recoil(actor: CombatActor, reduced: bool) -> Vector2:
	if reduced or not reactions.has(actor.serial): return Vector2.ZERO
	var hit_data: Dictionary = reactions[actor.serial]
	var amount: float = 5.0 if hit_data.source == &"bass_driver" else 2.5
	return Vector2(0,-sin((1 - float(hit_data.left)/.22) * PI) * amount)

static func approaching(actor: CombatActor) -> bool:
	return not actor.resolved and actor.position.y >= CombatSession.BREACH_Y - 105 and actor.position.y < CombatSession.BREACH_Y

func decorate_enemy(canvas: CombatArena, actor: CombatActor) -> void:
	if actor.projectile: return
	var p: Vector2 = actor.position
	var r: float = actor.radius * 1.45
	if reactions.has(actor.serial):
		var data: Dictionary = reactions[actor.serial]
		var tint: Color = DraftPanel.ACCENTS.get(data.source, Color("76dbca"))
		var fade: float = float(data.left) / .22
		# Small contact strokes, rather than a full-screen flash or a new target marker.
		for side: int in [-1,1]:
			canvas.draw_line(p+Vector2(side*r,-3),p+Vector2(side*(r+7),-8),Color(tint,fade*.75),2,true)
	if actor.status.slow > 0 and actor.status.slow_source == &"static_net":
		# A visible weave moves with the trapped enemy for the actual slow duration.
		for offset: int in [-1,0,1]:
			canvas.draw_line(p+Vector2(-r,r*.35+offset*6),p+Vector2(r,-r*.35+offset*6),Color("7ad8ee",.55),1.5,true)
		canvas.draw_arc(p,r,0,PI,14,Color("7ad8ee",.65),2,true)

func instrument(canvas: CombatArena, id: StringName, tint: Color) -> void:
	if not upgrades.has(id): return
	var age: float = 1 - float(upgrades[id])/1.3
	var alpha: float = (1-age) * (.35 if RadioPreferences.current.enabled("reduced_flash") else .65)
	canvas.draw_circle(Vector2(0,-10),39,Color(tint,alpha*.15))
	canvas.draw_arc(Vector2(0,-10),39+age*10,PI*.15,PI*.85,20,Color(tint,alpha),3,true)
	if RadioPreferences.current.enabled("low_effects"): return
	for index: int in 3:
		var at: Vector2 = Vector2(-18+index*18,-22-age*28-index%2*8)
		canvas.draw_line(at,at+Vector2(0,-8),Color(tint,alpha),2,true)

func danger(canvas: CombatArena) -> void:
	var positions: Array[float] = []
	for actor: CombatActor in canvas.session.actors:
		if approaching(actor):
			var x: float = clampf(actor.position.x,16,624)
			if positions.all(func(other: float) -> bool: return absf(x-other)>25): positions.append(x)
			if positions.size() >= 16: break
	var critical: bool = canvas.session.hull / canvas.session.maximum_hull() <= .3
	if positions.is_empty() and not critical: return
	var reduced: bool = RadioPreferences.current.enabled("reduced_flash")
	var alpha: float = .72 if reduced else .63 + .12 * sin(canvas.waveform_time * 4)
	var tint: Color = Color("f49b83",alpha)
	canvas.draw_rect(Rect2(0,592,640,18),Color(tint,.09))
	for x: float in positions:
		canvas.draw_polyline(PackedVector2Array([Vector2(x-7,594),Vector2(x,601),Vector2(x+7,594)]),tint,3,true)
		canvas.draw_line(Vector2(x-12,609),Vector2(x+12,609),tint,4,true)
	if critical:
		canvas.draw_line(Vector2(2,610),Vector2(638,610),tint,4,true)
		canvas.draw_string(ThemeDB.fallback_font,Vector2(12,633),canvas.tr("POLISH_CRITICAL"),HORIZONTAL_ALIGNMENT_LEFT,-1,18,tint)
