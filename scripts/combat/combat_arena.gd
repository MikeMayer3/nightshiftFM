class_name CombatArena
extends Control
## Presentation and pointer mapping only. Simulation coordinates never depend on aspect ratio.
const SHIELD_LINE_Y: float = 610.0
var station_color: Color = Color("76dbca")
var session: CombatSession
var shot_end: Vector2
var shot_flash: float = 0.0
var waveform_time: float = 0.0
var hit_flash: float = 0.0
var pulses: Array[Dictionary] = []
var chains: Array[Dictionary] = []
var _mouse_held: bool = false
var _touch_index: int = -1
const SUPPORT_POSITIONS: Dictionary = {
	&"arc_aerial": Vector2(195, 682),
	&"bass_driver": Vector2(445, 682),
	&"static_net": Vector2(95, 682),
}
var support_flashes: Dictionary = {}

func _ready() -> void:
	clip_contents = true

func arena_scale() -> float:
	return minf(size.x / CombatSession.ARENA.x, size.y / CombatSession.ARENA.y)

func deck_stretch() -> Vector2:
	return size / CombatSession.ARENA if session != null and session.signal_progress != null else Vector2.ONE * arena_scale()

func arena_stretch() -> Vector2:
	# Map the simulation breach boundary to the raised visible shield line.
	return deck_stretch() * Vector2(1, SHIELD_LINE_Y / CombatSession.BREACH_Y)

func _deck_to_field(point: Vector2) -> Vector2:
	return point * Vector2(1, CombatSession.BREACH_Y / SHIELD_LINE_Y)

func arena_offset() -> Vector2:
	if session != null and session.signal_progress != null: return Vector2.ZERO
	return (size - CombatSession.ARENA * arena_scale()) * 0.5

func _gui_input(event: InputEvent) -> void:
	if not _can_aim():
		return
	# Acquire only through GUI hit testing so HUD and modal touches cannot aim.
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled and _touch_index == -1 and not _mouse_held:
			_touch_index = event.index
			session.focus_active = true
			session.focus_point = (event.position - arena_offset()) / arena_stretch()
			accept_event()
		return
	# Native touch owns its gesture; the bridge remains enabled for UI buttons.
	if event.device == InputEvent.DEVICE_ID_EMULATION or _touch_index != -1:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_held = event.pressed
		session.focus_active = event.pressed
		session.focus_point = (event.position - arena_offset()) / arena_stretch()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_held:
		session.focus_point = (event.position - arena_offset()) / arena_stretch()
		accept_event()

func clear_pointer() -> void:
	_mouse_held = false
	_touch_index = -1
	if session != null:
		session.focus_active = false

func _input(event: InputEvent) -> void:
	# Track the owning finger even outside the Control, including OS cancellation.
	if event is InputEventScreenDrag and event.index == _touch_index:
		if _can_aim():
			_move_pointer(event.position)
		else:
			clear_pointer()
	elif event is InputEventScreenTouch and event.index == _touch_index and (not event.pressed or event.canceled):
		if not event.canceled:
			_finish_pointer(event.position)
		clear_pointer()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_held:
		if _can_aim(): _move_pointer(event.position)
		else: clear_pointer()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _mouse_held:
		_finish_pointer(event.position)
		clear_pointer()

func _move_pointer(position: Vector2) -> void:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * position
	session.focus_point = (local - arena_offset()) / arena_stretch()
func _finish_pointer(_position: Vector2) -> void:
	# Releasing focus returns to automatic targeting; there is no cooldown attack.
	pass

func _contains_pointer(control: Control, position: Vector2) -> bool:
	return Rect2(Vector2.ZERO, control.size).has_point(control.get_global_transform_with_canvas().affine_inverse() * position)

func _can_aim() -> bool:
	return session != null and is_visible_in_tree() and not session.paused and not session.is_finished() and not session.is_deciding() and not session.is_wiring()

func _process(delta: float) -> void:
	if session != null and not session.paused and not session.is_deciding() and not session.is_wiring():
		waveform_time += delta
		for id: StringName in support_flashes:
			support_flashes[id] = maxf(0, float(support_flashes[id]) - delta)
		shot_flash = maxf(0.0, shot_flash - delta)
		hit_flash = maxf(0.0, hit_flash - delta)
	if session != null and not session.paused:
		for pulse: Dictionary in pulses: pulse.left -= delta
		pulses = pulses.filter(func(p: Dictionary) -> bool: return p.left > 0)
		for chain: Dictionary in chains: chain.left -= delta
		chains = chains.filter(func(c: Dictionary) -> bool: return c.left > 0.0)
	queue_redraw()

func show_shot(at: Vector2) -> void:
	shot_end = at
	shot_flash = 0.22

func show_hit(_amount: float) -> void:
	hit_flash = 0.22

func _draw() -> void:
	if session == null:
		return
	draw_set_transform(arena_offset(), 0.0, deck_stretch())
	var cyan: Color = Color("76dbca")
	var muted: Color = Color("657f91")
	var era: int = RadioArt.era(session)
	var low: bool = RadioPreferences.current.enabled("low_effects")
	var reduced: bool = RadioPreferences.current.enabled("reduced_flash")
	draw_rect(Rect2(Vector2.ZERO, CombatSession.ARENA), RadioArt.BACKGROUNDS[era])
	if not low:
		for y: int in range(100, 610, 90):
			draw_line(Vector2(24, y), Vector2(616, y), RadioArt.TRIMS[era].darkened(.65), 1)
	draw_rect(Rect2(0, SHIELD_LINE_Y, 640, 720 - SHIELD_LINE_Y), Color("15242c"))
	draw_line(Vector2(0, SHIELD_LINE_Y + 5), Vector2(640, SHIELD_LINE_Y + 5), RadioArt.TRIMS[era], 3)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(16, 25), tr("COMBAT_SPAWN"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, muted)
	for x: int in range(225, 611, 16):
		var reach: float = 10 if x % 3 == 0 else 6
		draw_line(Vector2(x, 20 - reach), Vector2(x, 20 + reach), RadioArt.TRIMS[era], 1)
	_sound_path(Vector2(225, 20), Vector2(610, 20), Color("88c9bf"), 9, 44, waveform_time * 5, 2)
	draw_line(Vector2(0, SHIELD_LINE_Y), Vector2(640, SHIELD_LINE_Y), Color("f78279") if hit_flash > 0 and not reduced else Color("efb178"), 4)
	draw_set_transform(arena_offset(), 0, arena_stretch())
	if session.supports != null:
		var field: Dictionary = session.supports.field
		if not field.is_empty():
			var center: Vector2 = field.position
			var radius: float = float(field.radius)
			_net_pattern(center, radius, Color("7ad8ee"))
			draw_string(font, center + Vector2(-32, 0), str(field.charges), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("7ad8ee"))
		for shock: Dictionary in session.supports.shocks:
			_sound_path(Vector2(float(shock.x) - float(shock.width), float(shock.y)), Vector2(float(shock.x) + float(shock.width), float(shock.y)), Color("efa968"), 12, 55, waveform_time * 4, 5)
	if session.arsenal != null:
		for needle: Dictionary in session.arsenal.needles:
			var at: Vector2 = Vector2(needle.x, needle.y)
			draw_circle(at, 5, DraftPanel.ACCENTS[&"needle_swarm"])
			draw_line(at + Vector2(4, 0), at + Vector2(4, -19), DraftPanel.ACCENTS[&"needle_swarm"], 3)
			draw_arc(at + Vector2(6, -16), 6, -PI * .5, PI * .5, 8, DraftPanel.ACCENTS[&"needle_swarm"], 3)
		for zone: Dictionary in session.arsenal.zones:
			var tint: Color = DraftPanel.ACCENTS[StringName(zone.source)]
			if zone.source == "static_net": _net_pattern(Vector2(zone.x, zone.y), float(zone.p.radius), tint)
			elif zone.source == "reverb_well": _spiral(Vector2(zone.x, zone.y), float(zone.p.radius), tint, waveform_time)
			else:
				for ring: int in 3: draw_arc(Vector2(zone.x, zone.y), float(zone.p.radius) * (0.4 + ring * .3), 0, TAU, 24, Color(tint, 0.5), 2)
	for pulse: Dictionary in pulses:
		var tint: Color = DraftPanel.ACCENTS.get(pulse.source, Color("efa968"))
		tint.a = .45 if reduced else clampf(float(pulse.left) / .55, .15, .8)
		var age: float = 1 - float(pulse.left) / .55
		match String(pulse.source):
			"static_net": _net_pattern(pulse.center, pulse.radius.x, tint)
			"reverb_well": _spiral(pulse.center, pulse.radius.x, tint, age * 3)
			"bass_driver":
				for ring: int in 3:
					draw_arc(pulse.center + Vector2(0, pulse.radius.y * .6), pulse.radius.x * (.35 + ring * .25 + age * .15), PI * 1.12, PI * 1.88, 24, tint, 5 - ring)
			"echo_deck":
				for side: int in [-1, 1]:
					var center: Vector2 = pulse.center + Vector2(side * pulse.radius.x * .28, 0)
					draw_arc(center, pulse.radius.x * (.35 + age * .4), 0, TAU, 28, tint, 3)
					_sound_path(center - Vector2(24, 0), center + Vector2(24, 0), tint, 8, 16, age * 4, 2)
			"needle_swarm":
				for ray: int in 5:
					var direction: Vector2 = Vector2.from_angle(-PI + ray * PI / 4)
					draw_line(pulse.center + direction * 12, pulse.center + direction * (25 + age * 20), tint, 2)
			_:
				_sound_path(pulse.center - Vector2(pulse.radius.x, 0), pulse.center + Vector2(pulse.radius.x, 0), tint, 12, 40, age * 5, 3)
	var aimed: CombatActor = session.target()
	for actor: CombatActor in session.actors:
		var p: Vector2 = actor.position
		# Fill the battlefield while preserving round enemy silhouettes.
		draw_set_transform(arena_offset() + p * (arena_stretch() - Vector2.ONE * arena_scale()), 0.0, Vector2.ONE * arena_scale())
		if session.arsenal != null and session.arsenal.mark_strength(actor.serial) > 0:
			draw_arc(p, actor.radius + 7, 0, TAU, 24, Color("f3d57b"), 3)
		var color: Color = Color("efa968")
		if actor.projectile:
			color = Color("f78279")
			draw_rect(Rect2(p - Vector2(4, 6), Vector2(8, 12)), color)
			for bit: int in 3:
				draw_rect(Rect2(p + Vector2(-3, -14 - bit * 8), Vector2(6, 4)), Color(color, .65 - bit * .15))
		elif actor.path_kind == EnemyDefinition.PathKind.DIVE:
			color = Color("f78279")
			if actor.age < 2.0:
				draw_line(p + Vector2(0, 30), p + Vector2(0, 80), color, 2.0)
		elif actor.path_kind == EnemyDefinition.PathKind.CARRIER:
			color = Color("b1a1ed")
		if not actor.projectile:
			var extent: float = actor.radius * 2.8
			draw_texture_rect(RadioArt.enemy(actor, era), Rect2(p - Vector2.ONE * extent * .5, Vector2.ONE * extent), false)
			if actor.path_kind == EnemyDefinition.PathKind.CARRIER:
				for n: int in actor.child_limit - actor.children_spawned:
					draw_rect(Rect2(p + Vector2(-16 + n * 12, actor.radius + 3), Vector2(8, 5)), color)
		if session.supports != null:
			if actor.elite:
				draw_arc(p, actor.radius + 4, PI, TAU, 16, Color("ffdc86"), 5)
				draw_string(font, p + Vector2(-24, -actor.radius - 18), tr("M4_ELITE_TAG"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffdc86"))
			if actor.projectiles_fired < actor.projectile_limit and actor.ability_interval - actor.ability_time < 0.9:
				draw_arc(p, actor.radius + 14, 0, TAU, 24, Color("f78279"), 3)
				draw_line(p + Vector2(0, actor.radius), p + Vector2(0, actor.radius + 55), Color("f78279"), 2)
			if actor.status.charged > 0:
				for charge: int in actor.status.charged: draw_circle(p + Vector2(-12 + charge * 12, actor.radius + 8), 4, Color("bba5f4"))
			if actor.status.slow > 0: draw_arc(p, actor.radius + 5, 0, PI, 16, Color("7ad8ee"), 4)
			if actor.status.exposure > 0: draw_line(p + Vector2(-12, -actor.radius), p + Vector2(12, -actor.radius + 12), Color("efa968"), 5)
			if actor.status.jam_left > 0:
				draw_line(p + Vector2(-12, -12), p + Vector2(12, 12), Color.WHITE, 4)
				draw_line(p + Vector2(-12, 12), p + Vector2(12, -12), Color.WHITE, 4)
		if actor.health < actor.max_health:
			draw_rect(Rect2(p + Vector2(-22,-actor.radius-10), Vector2(44,4)), Color("384252"))
			draw_rect(Rect2(p + Vector2(-22,-actor.radius-10), Vector2(44 * actor.health / actor.max_health,4)), color)
		if actor == aimed:
			draw_arc(p, actor.radius + 8.0, 0, TAU, 32, cyan, 2.0)
	draw_set_transform(arena_offset(), 0.0, arena_stretch())
	if session.focus_active:
		draw_circle(session.focus_point, 12.0, cyan, false, 2.0)

	var base: Vector2 = tower_position()
	cyan = station_color
	var direction: Vector2 = (aimed.position - base).normalized() if aimed != null else Vector2.UP
	draw_set_transform(arena_offset() + base * arena_stretch(), 0, Vector2.ONE * arena_scale())
	draw_texture_rect(RadioArt.main_texture(session), Rect2(-48, -64, 96, 96), false)

	draw_set_transform(arena_offset(), 0, arena_stretch())
	if session.run.shield.current > 0 or session.ability_left > 0:
		draw_arc(base, 50.0, PI, TAU, 32, cyan, 5.0 if session.ability_left > 0 else 2.0)
	if session.supports != null and session.supports.overshield > 0:
		draw_arc(base, 59, PI, TAU, 32, Color("bba5f4"), 5)
	for chain: Dictionary in chains:
		var tint: Color = chain.get("color", Color("c4aff5") if chain.support else cyan)
		for index: int in chain.points.size() - 1:
			_sound_path(chain.points[index], chain.points[index + 1], tint, 8 if chain.support else 4, 28, waveform_time * 12, 3)
	if shot_flash > 0.0:
		var chassis: String = session.draft.loadout.main if session.draft is ArsenalDraft else "pulse"
		var source: Vector2 = base + Vector2(0, -58)
		match chassis:
			"sweep":
				_sound_path(source, shot_end, Color("98eee0"), 10, 65, waveform_time * 16, 3)
				_sound_path(source, shot_end, Color("4b998e"), -10, 65, waveform_time * 16, 2)
			"burst":
				for packet: int in 3:
					var at: Vector2 = source.lerp(shot_end, clampf(1 - shot_flash / .22 + packet * .18, 0, 1))
					draw_arc(at, 12 + packet * 4, direction.angle() - .8, direction.angle() + .8, 12, Color("f4c786"), 4)
			_:
				var at: Vector2 = source.lerp(shot_end, 1 - shot_flash / .22)
				for ring: int in 3:
					draw_arc(at, 9 + ring * 8, direction.angle() - 1, direction.angle() + 1, 16, Color(cyan, .9 - ring * .2), 3)
	_draw_support_turrets(aimed)

func equipped_supports() -> Array[StringName]:
	var result: Array[StringName] = []
	if session == null or session.supports == null: return result
	for id: StringName in (ArsenalContent.FAMILIES if session.arsenal != null else SUPPORT_POSITIONS.keys()):
		if session.draft.track(id) != null: result.append(id)
	return result

func support_position(id: StringName) -> Vector2:
	# Paired slots reserve the middle; a full deck uses consecutive 90-unit slots.
	var supports: Array[StringName] = equipped_supports()
	var slots: Array[float] = [140, 500, 50, 410 if supports.size() == 5 else 590, 230]
	var index: int = supports.find(id)
	return _deck_to_field(Vector2(slots[maxi(0, index)], 682))

func tower_position() -> Vector2:
	return _deck_to_field(Vector2(320, 684))

func _draw_support_turrets(aimed: CombatActor) -> void:
	for id: StringName in equipped_supports():
		var p: Vector2 = support_position(id)
		var tint: Color = DraftPanel.ACCENTS[id]
		var fraction: float = session.supports.recharge_fraction(session.draft.track(id))
		# Position follows the expanded field; the miniature and its bar stay undistorted.
		draw_set_transform(arena_offset() + p * arena_stretch(), 0, Vector2.ONE * arena_scale())
		var direction: Vector2 = ((aimed.position - p) * arena_stretch()).normalized() if aimed != null else Vector2.UP
		draw_texture_rect(DraftPanel.ICONS[id], Rect2(-34, -43, 68, 68), false)
		draw_rect(Rect2(-26, 27, 52, 7), Color("334958"))
		draw_rect(Rect2(-26, 27, 52 * fraction, 7), tint)
		if fraction >= 1:
			# A full bar and lit muzzle mean ready, including while waiting for a target.
			draw_circle(direction * 31, 4, tint.lightened(0.3))
		if float(support_flashes.get(id, 0)) > 0 and not RadioPreferences.current.enabled("reduced_flash"):
			draw_circle(direction * 33, 9, tint.lightened(0.5), false, 3)
	draw_set_transform(arena_offset(), 0, arena_stretch())

func show_chain(points: PackedVector2Array, support: bool) -> void:
	if not support and points.size() > 0 and points[0].is_equal_approx(CombatSession.TRANSMITTER):
		points = points.duplicate()
		points[0] = tower_position()
	if support and &"arc_aerial" in equipped_supports() and points.size() > 0 and points[0].is_equal_approx(CombatSession.TRANSMITTER):
		points = points.duplicate()
		points[0] = support_position(&"arc_aerial")
		support_flashes[&"arc_aerial"] = 0.18
	chains.append({"points": points, "support": support, "left": 0.18})

func show_support(source: StringName, center: Vector2, radius: Vector2) -> void:
	if source in equipped_supports():
		support_flashes[source] = 0.35
		if source == &"echo_deck": chains.append({"points": PackedVector2Array([support_position(source), center]), "support": true, "left": 0.22, "color": DraftPanel.ACCENTS[source]})
	pulses.append({"source": source, "center": center, "radius": radius, "left": 0.55})

func _sound_path(start: Vector2, end: Vector2, tint: Color, amplitude: float, wavelength: float, phase: float, width: float) -> void:
	var axis: Vector2 = end - start
	var normal: Vector2 = axis.normalized().orthogonal()
	var count: int = clampi(int(axis.length() / 6), 8, 80)
	if RadioPreferences.current.enabled("low_effects"): count = mini(count, 24)
	var points: PackedVector2Array = []
	for index: int in count + 1:
		var t: float = float(index) / count
		points.append(start + axis * t + normal * sin(t * axis.length() / maxf(wavelength, axis.length() / count * 4) * TAU - phase) * amplitude * sin(t * PI))
	draw_polyline(points, tint, width, true)

func _net_pattern(center: Vector2, radius: float, tint: Color) -> void:
	var diamond: PackedVector2Array = PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0), center + Vector2(0, -radius)])
	draw_polyline(diamond, Color(tint, .6), 2, true)
	for band: int in [-2, -1, 0, 1, 2]:
		var y: float = radius * band / 3.0
		var reach: float = radius - absf(y)
		_sound_path(center + Vector2(-reach, y), center + Vector2(reach, y), Color(tint, .4), 4, 40, waveform_time * 3, 2)

func _spiral(center: Vector2, radius: float, tint: Color, phase: float) -> void:
	for arm: int in 3:
		var points: PackedVector2Array = []
		for index: int in 33:
			var t: float = float(index) / 32
			points.append(center + Vector2.from_angle(t * TAU + phase + arm * TAU / 3) * radius * t)
		draw_polyline(points, Color(tint, .55), 2, true)
