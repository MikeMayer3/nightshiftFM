class_name CombatArena
extends Control
## Presentation and pointer mapping only. Simulation coordinates never depend on aspect ratio.
var station_color: Color = Color("76dbca")
var session: CombatSession
var shot_end: Vector2
var shot_flash: float = 0.0
var hit_flash: float = 0.0
var pulses: Array[Dictionary] = []
var chains: Array[Dictionary] = []
var _mouse_held: bool = false
var _touch_index: int = -1
var _aim_button: Button
var _button_dragged: bool = false
var _block_button_click: bool = false
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

func arena_stretch() -> Vector2:
	return size / CombatSession.ARENA if session != null and session.signal_progress != null else Vector2.ONE * arena_scale()

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
	if _aim_button != null:
		_block_button_click = true
		_unblock_button.call_deferred()
	_aim_button = null
	_button_dragged = false
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
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_held and _aim_button != null:
		if _can_aim(): _move_pointer(event.position)
		else: clear_pointer()
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and _mouse_held:
		_finish_pointer(event.position)
		clear_pointer()

func button_input(event: InputEvent, button: Button) -> void:
	if button.disabled or not _can_aim() or session.active_combat == null or _touch_index != -1 or _mouse_held:
		return
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		_touch_index = event.index
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_mouse_held = true
	else:
		return
	_aim_button = button
	_button_dragged = false
	_block_button_click = false

func button_click_handled() -> bool:
	# Button's emulated mouse release can arrive before or after native touch UP.
	return _aim_button != null or _block_button_click

func _unblock_button() -> void:
	_block_button_click = false

func _move_pointer(position: Vector2) -> void:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * position
	session.focus_point = (local - arena_offset()) / arena_stretch()
	if _aim_button != null:
		_button_dragged = _button_dragged or not _contains_pointer(_aim_button, position)
		session.focus_active = Rect2(Vector2.ZERO, size).has_point(local)

func _finish_pointer(position: Vector2) -> void:
	if _aim_button != null and not _button_dragged and _contains_pointer(_aim_button, position) and _can_aim():
		var target: CombatActor = session.target()
		if target != null: session.active_combat.burst(session, target.position)
	else:
		_release_at(position)

func _contains_pointer(control: Control, position: Vector2) -> bool:
	return Rect2(Vector2.ZERO, control.size).has_point(control.get_global_transform_with_canvas().affine_inverse() * position)

func _can_aim() -> bool:
	return session != null and is_visible_in_tree() and not session.paused and not session.is_finished() and not session.is_deciding() and not session.is_wiring()

func _release_at(position: Vector2) -> void:
	if not _can_aim() or session.active_combat == null:
		return
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * position
	if Rect2(Vector2.ZERO, size).has_point(local):
		session.active_combat.burst(session, (local - arena_offset()) / arena_stretch())

func _process(delta: float) -> void:
	if session != null and not session.paused:
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
	shot_flash = 0.10

func show_hit(_amount: float) -> void:
	hit_flash = 0.22

func _draw() -> void:
	if session == null:
		return
	draw_set_transform(arena_offset(), 0.0, arena_stretch())
	var cyan: Color = Color("76dbca")
	var muted: Color = Color("657f91")
	draw_rect(Rect2(Vector2.ZERO, CombatSession.ARENA), Color("0b1824"))
	for x: int in range(0, 641, 64):
		draw_line(Vector2(x, 0), Vector2(x, 640), Color("142c3b"))
	for y: int in range(0, 641, 64):
		draw_line(Vector2(0, y), Vector2(640, y), Color("142c3b"))
	draw_rect(CombatSession.SPAWN_BAND, Color("223b47"))
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(40, 25), tr("COMBAT_SPAWN"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, muted)
	draw_line(Vector2(0, 640), Vector2(640, 640), Color("f78279") if hit_flash > 0 else Color("c08d70"), 4.0)
	if session.signal_progress == null:
		draw_string(font, Vector2(12, 665), tr("COMBAT_BREACH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, muted)
	if session.supports != null:
		var field: Dictionary = session.supports.field
		if not field.is_empty():
			var center: Vector2 = field.position
			var radius: float = float(field.radius)
			draw_circle(center, radius, Color(0.3, 0.8, 0.9, 0.12))
			draw_arc(center, radius, 0, TAU, 48, Color("7ad8ee"), 3)
			for offset: int in [-60, 0, 60]:
				draw_line(center + Vector2(offset, -radius * 0.7), center + Vector2(offset, radius * 0.7), Color(0.3, 0.8, 0.9, 0.35), 2)
			draw_string(font, center + Vector2(-32, 0), str(field.charges), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("7ad8ee"))
		for shock: Dictionary in session.supports.shocks:
			draw_line(Vector2(float(shock.x) - float(shock.width), float(shock.y)), Vector2(float(shock.x) + float(shock.width), float(shock.y)), Color("efa968"), 7)
	if session.arsenal != null:
		for needle: Dictionary in session.arsenal.needles:
			var at: Vector2 = Vector2(needle.x, needle.y)
			draw_line(at, at - Vector2(needle.dx, needle.dy) * 14, DraftPanel.ACCENTS[&"needle_swarm"], 4)
		for zone: Dictionary in session.arsenal.zones:
			var tint: Color = DraftPanel.ACCENTS[StringName(zone.source)]
			tint.a = .13
			draw_circle(Vector2(zone.x, zone.y), float(zone.p.radius), tint)
			tint.a = .7
			draw_arc(Vector2(zone.x, zone.y), float(zone.p.radius), session.elapsed, session.elapsed + TAU * .8, 32, tint, 2)
	for pulse: Dictionary in pulses:
		var points: PackedVector2Array = []
		for index: int in 49:
			var angle: float = TAU * index / 48.0
			points.append(pulse.center + Vector2(cos(angle), sin(angle)) * pulse.radius)
		var pulse_color: Color = DraftPanel.ACCENTS.get(pulse.source, Color("efa968"))
		pulse_color.a = float(pulse.left) / 0.35
		draw_polyline(points, pulse_color, 4)
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
			draw_circle(p, actor.radius, color, false, 3.0)
			draw_line(p + Vector2(0, -20), p + Vector2(0, -5), color, 3.0)
		elif actor.path_kind == EnemyDefinition.PathKind.DIVE:
			color = Color("f78279")
			draw_colored_polygon(PackedVector2Array([p + Vector2(-22,-18), p + Vector2(22,-18), p + Vector2(0,24)]), color)
			if actor.age < 2.0:
				draw_line(p + Vector2(0, 30), p + Vector2(0, 80), color, 2.0)
		elif actor.path_kind == EnemyDefinition.PathKind.CARRIER:
			color = Color("b1a1ed")
			draw_rect(Rect2(p - Vector2(29,24), Vector2(58,48)), color, false, 4.0)
			for n: int in actor.child_limit - actor.children_spawned:
				draw_circle(p + Vector2(float(n - 1) * 15, 0), 4.0, color)
		else:
			draw_circle(p, actor.radius, color)
			draw_circle(p + Vector2(-5,-3), 3.0, Color("0b1824"))
			draw_circle(p + Vector2(5,-3), 3.0, Color("0b1824"))
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
		if session.active_combat != null:
			draw_arc(session.focus_point, session.active_combat.radius_for(session), 0, TAU, 48, cyan if session.active_combat.cooldown == 0 else muted, 2.0)
	var base: Vector2 = CombatSession.TRANSMITTER
	cyan = station_color
	draw_rect(Rect2(base - Vector2(30, 12), Vector2(60, 28)), cyan, false, 3.0)
	var direction: Vector2 = (aimed.position - base).normalized() if aimed != null else Vector2.UP
	draw_line(base, base + direction * 46.0, cyan, 7.0)
	if session.run.shield.current > 0 or session.ability_left > 0:
		draw_arc(base, 50.0, PI, TAU, 32, cyan, 5.0 if session.ability_left > 0 else 2.0)
	if session.supports != null and session.supports.overshield > 0:
		draw_arc(base, 59, PI, TAU, 32, Color("bba5f4"), 5)
	for chain: Dictionary in chains:
		draw_polyline(chain.points, chain.get("color", Color("b1a1ed") if chain.support else cyan), 4.0)
	if shot_flash > 0:
		draw_line(base + direction * 46.0, shot_end, cyan, 3.0)
		draw_circle(shot_end, 8.0, cyan, false, 2.0)
	_draw_support_turrets(aimed)

func equipped_supports() -> Array[StringName]:
	var result: Array[StringName] = []
	if session == null or session.supports == null: return result
	for id: StringName in (ArsenalContent.FAMILIES if session.arsenal != null else SUPPORT_POSITIONS.keys()):
		if session.draft.track(id) != null: result.append(id)
	return result

func support_position(id: StringName) -> Vector2:
	if session.arsenal == null: return SUPPORT_POSITIONS[id]
	var slots: Array[float] = [155, 435, 55, 555, 235]
	return Vector2(slots[equipped_supports().find(id)], 682)

func _draw_support_turrets(aimed: CombatActor) -> void:
	for id: StringName in equipped_supports():
		var p: Vector2 = support_position(id)
		var tint: Color = DraftPanel.ACCENTS[id]
		var fraction: float = session.supports.recharge_fraction(session.draft.track(id))
		# Position follows the expanded field; the miniature and its bar stay undistorted.
		draw_set_transform(arena_offset() + p * arena_stretch(), 0, Vector2.ONE * arena_scale())
		var direction: Vector2 = ((aimed.position - p) * arena_stretch()).normalized() if aimed != null else Vector2.UP
		draw_line(Vector2.ZERO, direction * 31, tint, 5)
		draw_rect(Rect2(-26, -17, 52, 39), Color("203747"))
		draw_rect(Rect2(-26, -17, 52, 39), tint.darkened(0.35), false, 2)
		draw_texture_rect(DraftPanel.ICONS[id], Rect2(-18, -16, 36, 36), false)
		draw_rect(Rect2(-26, 27, 52, 7), Color("334958"))
		draw_rect(Rect2(-26, 27, 52 * fraction, 7), tint)
		if fraction >= 1:
			# A full bar and lit muzzle mean ready, including while waiting for a target.
			draw_circle(direction * 31, 4, tint.lightened(0.3))
		if float(support_flashes.get(id, 0)) > 0:
			draw_circle(direction * 33, 9, tint.lightened(0.5), false, 3)
	draw_set_transform(arena_offset(), 0, arena_stretch())

func show_chain(points: PackedVector2Array, support: bool) -> void:
	if support and &"arc_aerial" in equipped_supports() and points.size() > 0 and points[0].is_equal_approx(CombatSession.TRANSMITTER):
		points = points.duplicate()
		points[0] = support_position(&"arc_aerial")
		support_flashes[&"arc_aerial"] = 0.18
	chains.append({"points": points, "support": support, "left": 0.18})

func show_support(source: StringName, center: Vector2, radius: Vector2) -> void:
	if source in equipped_supports():
		support_flashes[source] = 0.35
		chains.append({"points": PackedVector2Array([support_position(source), center]), "support": true, "left": 0.12, "color": DraftPanel.ACCENTS[source]})
	pulses.append({"source": source, "center": center, "radius": radius, "left": 0.35})
