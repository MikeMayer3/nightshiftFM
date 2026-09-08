class_name CombatArena
extends Control
## Presentation and pointer mapping only. Simulation coordinates never depend on aspect ratio.
var session: CombatSession
var shot_end: Vector2
var shot_flash: float = 0.0
var hit_flash: float = 0.0
var _mouse_held: bool = false

func arena_scale() -> float:
	return minf(size.x / CombatSession.ARENA.x, size.y / CombatSession.ARENA.y)

func arena_offset() -> Vector2:
	return (size - CombatSession.ARENA * arena_scale()) * 0.5

func _gui_input(event: InputEvent) -> void:
	if session == null or session.paused or session.is_finished():
		return
	# Godot's enabled touch-to-mouse bridge uses this same path on Android.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_held = event.pressed
		session.focus_active = event.pressed
		session.focus_point = (event.position - arena_offset()) / arena_scale()
		accept_event()
	elif event is InputEventMouseMotion and _mouse_held:
		session.focus_point = (event.position - arena_offset()) / arena_scale()
		accept_event()

func clear_pointer() -> void:
	_mouse_held = false
	if session != null:
		session.focus_active = false

func _input(event: InputEvent) -> void:
	# Release outside the arena must not leave a stuck override.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		clear_pointer()

func _process(delta: float) -> void:
	if session != null and not session.paused:
		shot_flash = maxf(0.0, shot_flash - delta)
		hit_flash = maxf(0.0, hit_flash - delta)
	queue_redraw()

func show_shot(at: Vector2) -> void:
	shot_end = at
	shot_flash = 0.10

func show_hit(_amount: float) -> void:
	hit_flash = 0.22

func _draw() -> void:
	if session == null:
		return
	draw_set_transform(arena_offset(), 0.0, Vector2.ONE * arena_scale())
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
	draw_string(font, Vector2(12, 665), tr("COMBAT_BREACH"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, muted)
	var aimed: CombatActor = session.target()
	for actor: CombatActor in session.actors:
		var p: Vector2 = actor.position
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
		if actor.health < actor.max_health:
			draw_rect(Rect2(p + Vector2(-22,-actor.radius-10), Vector2(44,4)), Color("384252"))
			draw_rect(Rect2(p + Vector2(-22,-actor.radius-10), Vector2(44 * actor.health / actor.max_health,4)), color)
		if actor == aimed:
			draw_arc(p, actor.radius + 8.0, 0, TAU, 32, cyan, 2.0)
	if session.focus_active:
		draw_circle(session.focus_point, 12.0, cyan, false, 2.0)
	var base: Vector2 = CombatSession.TRANSMITTER
	draw_rect(Rect2(base - Vector2(30, 12), Vector2(60, 28)), cyan, false, 3.0)
	var direction: Vector2 = (aimed.position - base).normalized() if aimed != null else Vector2.UP
	draw_line(base, base + direction * 46.0, cyan, 7.0)
	if session.run.shield.current > 0 or session.ability_left > 0:
		draw_arc(base, 50.0, PI, TAU, 32, cyan, 5.0 if session.ability_left > 0 else 2.0)
	if shot_flash > 0:
		draw_line(base + direction * 46.0, shot_end, cyan, 3.0)
		draw_circle(shot_end, 8.0, cyan, false, 2.0)
