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
var fragments: Array[Dictionary] = []
var drone_shots: Array[Dictionary] = []
var broadcast: RadioBroadcast
var feedback: RadioFeedback = RadioFeedback.new()
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
		feedback.advance(delta)
		for shot: Dictionary in drone_shots: shot.left -= delta
		drone_shots = drone_shots.filter(func(shot: Dictionary) -> bool: return shot.left > 0)
		waveform_time += delta
		for id: StringName in support_flashes:
			support_flashes[id] = maxf(0, float(support_flashes[id]) - delta)
		shot_flash = maxf(0.0, shot_flash - delta)
		hit_flash = maxf(0.0, hit_flash - delta)
		for fragment: Dictionary in fragments: fragment.left -= delta
		fragments = fragments.filter(func(f: Dictionary) -> bool: return f.left > 0)
		for pulse: Dictionary in pulses: pulse.left -= delta
		pulses = pulses.filter(func(p: Dictionary) -> bool: return p.left > 0)
		for chain: Dictionary in chains: chain.left -= delta
		chains = chains.filter(func(c: Dictionary) -> bool: return c.left > 0.0)
	queue_redraw()

func show_event(event: CombatEvent) -> void:
	feedback.hit(event)
	if event.kind == CombatEvent.Kind.DAMAGE and session != null:
		for actor: CombatActor in session.actors:
			if actor.serial == event.target_id:
				feedback.damage_numbers.hit(event, actor)
				break
	if event.kind != CombatEvent.Kind.KILL: return
	for actor: CombatActor in session.actors:
		if actor.serial != event.target_id: continue
		if fragments.size() >= 32: fragments.pop_front()
		fragments.append({"position": actor.position, "serial": actor.serial, "left": .32})
		break

func show_drone_shot(origin: Vector2, target: Vector2) -> void:
	if drone_shots.size() >= 64: drone_shots.pop_front()
	drone_shots.append({"origin": origin, "target": target, "left": .16})

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
	RadioScenery.background(self, era, low)
	draw_line(Vector2(0, SHIELD_LINE_Y + 5), Vector2(640, SHIELD_LINE_Y + 5), RadioArt.TRIMS[era], 3)
	var font: Font = ThemeDB.fallback_font
	draw_line(Vector2(0, SHIELD_LINE_Y), Vector2(640, SHIELD_LINE_Y), Color("f78279") if hit_flash > 0 and not reduced else Color("efb178"), 4)
	RadioShieldVisual.draw_boost(self)
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
			if needle.get("orbiting", false): draw_arc(at, 11, 0, TAU, 16, Color("cfb4ff", .3), 1.5, true)
			draw_circle(at, 6, DraftPanel.ACCENTS[&"needle_swarm"])
			draw_line(at + Vector2(4, 0), at + Vector2(4, -19), DraftPanel.ACCENTS[&"needle_swarm"], 3)
			draw_arc(at + Vector2(6, -16), 6, -PI * .5, PI * .5, 8, DraftPanel.ACCENTS[&"needle_swarm"], 3)
		for zone: Dictionary in session.arsenal.zones:
			var tint: Color = DraftPanel.ACCENTS[StringName(zone.source)]
			if zone.source == "static_net": _net_pattern(Vector2(zone.x, zone.y), float(zone.p.radius), tint)
			elif zone.source == "reverb_well": _spiral(Vector2(zone.x, zone.y), float(zone.p.radius), tint, waveform_time)
			# Bass is an impact pulse; its mechanical zone must not add static rings.
	for shot: Dictionary in drone_shots:
		var alpha: float = float(shot.left) / .16
		draw_line(shot.origin, shot.target, Color("cfb4ff", alpha * .7), 2, true)
		var bullet: Vector2 = Vector2(shot.origin).lerp(shot.target, 1 - alpha)
		draw_circle(bullet, 3.5, Color("f4eee0", alpha))
	for pulse: Dictionary in pulses:
		var tint: Color = DraftPanel.ACCENTS.get(pulse.source, Color("efa968"))
		tint.a = .45 if reduced else clampf(float(pulse.left) / .55, .15, .8)
		var age: float = 1 - float(pulse.left) / .55
		match String(pulse.source):
			"static_net":
				# One deployment accent; the live zone supplies the mesh.
				draw_arc(pulse.center, pulse.radius.x * (.7 + age * .3), 0, TAU, 24, Color(tint, (1 - age) * .3), 2, true)
			"reverb_well": pass # The persistent well already draws the vortex.
			"bass_driver":
				if pulse.get("wideband", false): BassPayoff.pressure(self, pulse.center, pulse.radius.x, age, tint)
				else: RadioEffects.bass(self, pulse.center, pulse.radius.x, tint, age)
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
	for fragment: Dictionary in fragments:
		var age: float = 1 - float(fragment.left) / .32
		for index: int in (2 if low else 5):
			var direction: Vector2 = Vector2.from_angle(index * TAU / 5 + int(fragment.serial) * .7)
			var at: Vector2 = fragment.position + direction * (6 + age * 22)
			draw_line(at, at + direction * 5, Color(.65, .83, .86, (1 - age) * (.35 if reduced else .7)), 2, true)
	if RadioBalance.enabled(session):
		# Area visuals stop at the same protected approach boundary as damage.
		draw_set_transform(arena_offset(), 0, arena_stretch())
		draw_rect(Rect2(0, 0, 640, RadioBalance.ENTRY_Y), Color("0d1c29"))
	var aimed: CombatActor = session.target()
	for actor: CombatActor in session.actors:
		var p: Vector2 = actor.position
		# Fill the battlefield while preserving round enemy silhouettes.
		draw_set_transform(arena_offset() + p * (arena_stretch() - Vector2.ONE * arena_scale()), 0.0, Vector2.ONE * arena_scale())
		if session.arsenal != null and session.arsenal.mark_strength(actor.serial) > 0:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-5, -actor.radius - 17), p + Vector2(5, -actor.radius - 17), p + Vector2(0, -actor.radius - 10)]), Color("f3d57b"))
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
			var extent: float = actor.radius * 3.4
			var tilt: float = sin(actor.age * 3 + actor.serial) * .055 if actor.path_kind == EnemyDefinition.PathKind.DIVE and not low else 0
			var local_scale: Vector2 = Vector2.ONE * arena_scale()
			draw_set_transform(arena_offset() + p * arena_stretch() + feedback.recoil(actor, reduced or low) * arena_scale(), tilt, local_scale)
			draw_texture_rect(RadioArt.enemy(actor, era), Rect2(-Vector2.ONE * extent * .5, Vector2.ONE * extent), false)
			draw_set_transform(arena_offset() + p * (arena_stretch() - local_scale), 0, local_scale)
			if actor.path_kind == EnemyDefinition.PathKind.CARRIER:
				for n: int in actor.child_limit - actor.children_spawned:
					draw_rect(Rect2(p + Vector2(-16 + n * 12, actor.radius + 3), Vector2(8, 5)), color)
		RadioEncounters.actor(self, actor)
		feedback.decorate_enemy(self, actor)
		if session.supports != null:
			if actor.elite and not EncounterDirector.boss(actor):
				draw_polyline(PackedVector2Array([p + Vector2(-10, -actor.radius - 8), p + Vector2(-10, -actor.radius - 15), p + Vector2(10, -actor.radius - 15), p + Vector2(10, -actor.radius - 8)]), Color("ffdc86"), 3)
				draw_string(font, p + Vector2(-24, -actor.radius - 18), tr("M4_ELITE_TAG"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffdc86"))
			if actor.projectiles_fired < actor.projectile_limit and actor.ability_interval - actor.ability_time < 0.9:
				draw_rect(Rect2(p + Vector2(-18, actor.radius + 8), Vector2(36, 4)), Color("f78279"))
				draw_line(p + Vector2(0, actor.radius), p + Vector2(0, actor.radius + 55), Color("f78279"), 2)
			if actor.status.charged > 0:
				for charge: int in actor.status.charged: draw_circle(p + Vector2(-12 + charge * 12, actor.radius + 8), 4, Color("bba5f4"))
			if actor.status.slow > 0 and actor.status.slow_source != &"static_net":
				for side: int in [-1, 1]: draw_line(p + Vector2(side * 5, actor.radius + 12), p + Vector2(side * 5, actor.radius + 21), Color("7ad8ee"), 3)
			if actor.status.exposure > 0: draw_line(p + Vector2(-12, -actor.radius), p + Vector2(12, -actor.radius + 12), Color("efa968"), 5)
			if actor.status.jam_left > 0:
				draw_line(p + Vector2(-12, -12), p + Vector2(12, 12), Color.WHITE, 4)
				draw_line(p + Vector2(-12, 12), p + Vector2(12, -12), Color.WHITE, 4)
		if actor.health < actor.max_health and not EncounterDirector.boss(actor):
			draw_rect(Rect2(p + Vector2(-22,-actor.radius-10), Vector2(44,4)), Color("384252"))
			draw_rect(Rect2(p + Vector2(-22,-actor.radius-10), Vector2(44 * actor.health / actor.max_health,4)), color)
		if actor == aimed and session.focus_active:
			for side: int in [-1, 1]:
				var x: float = side * (actor.radius + 10)
				draw_polyline(PackedVector2Array([p + Vector2(x - side * 5, -7), p + Vector2(x, -7), p + Vector2(x, 7), p + Vector2(x - side * 5, 7)]), cyan, 2)
	draw_set_transform(arena_offset(), 0.0, arena_stretch())
	if session.focus_active:
		draw_line(session.focus_point - Vector2(7, 0), session.focus_point + Vector2(7, 0), cyan, 2)
		draw_line(session.focus_point - Vector2(0, 7), session.focus_point + Vector2(0, 7), cyan, 2)

	var base: Vector2 = tower_position()
	cyan = station_color
	var direction: Vector2 = (aimed.position - base).normalized() if aimed != null else Vector2.UP
	draw_set_transform(arena_offset() + base * arena_stretch(), 0, Vector2.ONE * arena_scale())
	RadioScenery.station(self)
	feedback.instrument(self, &"main", cyan)
	feedback.instrument(self, &"shield", Color("efa968"))
	feedback.instrument(self, &"repair", Color("96dbac"))
	draw_texture_rect(RadioArt.main_texture(session), Rect2(-48, -82, 96, 96), false)
	if session.draft != null: RadioEncounters.hardware(self, session.draft.track(&"main"), cyan, true)

	draw_set_transform(arena_offset(), 0, arena_stretch())
	if session.run.shield.current > 0 or session.ability_left > 0:
		draw_arc(base, 50.0, PI, TAU, 32, cyan, 5.0 if session.ability_left > 0 else 2.0)
	if session.supports != null and session.supports.overshield > 0:
		draw_arc(base, 59, PI, TAU, 32, Color("bba5f4"), 5)
	for chain: Dictionary in chains:
		var tint: Color = chain.get("color", Color("c4aff5") if chain.support else cyan)
		for index: int in chain.points.size() - 1:
			if not chain.support:
				var chassis: String = session.draft.loadout.main if session.draft is ArsenalDraft else "pulse"
				RadioEffects.tower(self, chain.points[index], chain.points[index + 1], chassis, clampf(1 - float(chain.left) / .22, 0, 1), Color("f4c786") if chassis == "burst" else tint)
			else:
				_sound_path(chain.points[index], chain.points[index + 1], Color(tint, clampf(float(chain.left) / .18, 0, 1)), 8, 28, waveform_time * 12, 2.4)
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
	feedback.damage_numbers.draw(self)
	# Incoming Signals stays above moving actors and every attack effect.
	draw_set_transform(arena_offset(), 0, deck_stretch())
	feedback.danger(self)
	draw_rect(Rect2(0, 0, 640, 40), Color("0d1c29"))
	var warning: bool = broadcast != null and broadcast.approaching
	var announcing: bool = feedback.wave_left > 0
	# Preserve letter proportions on wide screens while the signal spans the field.
	var text_scale: float = minf(deck_stretch().x, deck_stretch().y)
	draw_set_transform(arena_offset() + Vector2(16, 25) * deck_stretch(), 0, Vector2.ONE * text_scale)
	draw_string(font, Vector2.ZERO, tr("P4_APPROACH") if warning else (tr("POLISH_ON_AIR") % feedback.wave if announcing else tr("COMBAT_SPAWN")), HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if announcing or warning else 18, Color("efb178") if announcing or warning else muted)
	draw_set_transform(arena_offset(), 0, deck_stretch())
	for x: int in range(225, 611, 16):
		var reach: float = 10 if x % 3 == 0 else 6
		draw_line(Vector2(x, 20 - reach), Vector2(x, 20 + reach), RadioArt.TRIMS[era], 1)
	if warning:
		# Static interference brackets: no flash, shake, or change to population waveform.
		for x: int in range(230, 600, 70):
			draw_polyline(PackedVector2Array([Vector2(x, 6), Vector2(x + 18, 6), Vector2(x + 18, 11)]), Color("efb178"), 2)
			draw_polyline(PackedVector2Array([Vector2(x + 25, 29), Vector2(x + 25, 34), Vector2(x + 43, 34)]), Color("efb178"), 2)
	draw_polyline(RadioFeedback.signal_points(RadioFeedback.living_enemies(session), waveform_time * 5),Color("88c9bf"),2,true)

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
		feedback.instrument(self, id, tint)
		var direction: Vector2 = ((aimed.position - p) * arena_stretch()).normalized() if aimed != null else Vector2.UP
		var wideband: bool = id == &"bass_driver" and BassPayoff.active(session)
		draw_texture_rect(BassPayoff.texture(session) if id == &"bass_driver" else DraftPanel.ICONS[id], Rect2(-40, -53, 80, 80) if wideband else Rect2(-34, -43, 68, 68), false)
		if not wideband: RadioEncounters.hardware(self, session.draft.track(id), tint)
		if BroadcastRules.expanded(session) and EncounterDirector.jammed_support(session) == id:
			draw_line(Vector2(-25, -35), Vector2(25, 15), Color.WHITE, 4)
			draw_string(ThemeDB.fallback_font, Vector2(-36, -49), tr("BROADCAST_MUTED"), HORIZONTAL_ALIGNMENT_CENTER, 72, 14, Color.WHITE)
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
	chains.append({"points": points, "support": support, "left": 0.18 if support else .22})

func show_support(source: StringName, center: Vector2, radius: Vector2) -> void:
	if source in equipped_supports():
		support_flashes[source] = 0.35
		if source == &"echo_deck": chains.append({"points": PackedVector2Array([support_position(source), center]), "support": true, "left": 0.22, "color": DraftPanel.ACCENTS[source]})
	if source in [&"static_net", &"reverb_well"]:
		pulses = pulses.filter(func(p: Dictionary) -> bool: return p.source != source)
	pulses.append({"source": source, "center": center, "radius": radius, "left": 0.55, "wideband": source == &"bass_driver" and BassPayoff.active(session)})

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
	RadioEffects.net(self, center, radius, tint)

func _spiral(center: Vector2, radius: float, tint: Color, phase: float) -> void:
	for arm: int in 3:
		var points: PackedVector2Array = []
		for index: int in 33:
			var t: float = float(index) / 32
			points.append(center + Vector2.from_angle(t * TAU + phase + arm * TAU / 3) * radius * t)
		draw_polyline(points, Color(tint, .55), 2, true)
