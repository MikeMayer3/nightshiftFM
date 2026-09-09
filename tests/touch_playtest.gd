extends Node
## Isolated Android QA fixture. Production screen/input code is unchanged.
## Freeze a seeded formation to make native DOWN/MOVE/UP observable, without
## racing automatic combat. Never loaded by the ordinary game entry scene.
var screen: CombatScreen
var events: Array[String] = []
var sample_wait: float = 0

func _ready() -> void:
	screen = load("res://scenes/combat/combat.tscn").instantiate()
	screen.m3_enabled = true
	screen.active_enabled = true
	screen.arsenal_enabled = true
	screen.patchboard_enabled = true
	screen.store = MissionStore.new("user://qa_mission.json")
	add_child(screen)
	screen.set_process(false)
	screen.session.launch_wave()
	screen.session.advance(2.4)
	screen._refresh()
	screen.arena.gui_input.connect(func(event: InputEvent) -> void:
		if events.size() < 50: events.append(event.as_text()))

func physical(point: Vector2) -> Array[float]:
	var mapped: Vector2 = get_viewport().get_screen_transform() * point
	return [mapped.x, mapped.y]

func _process(delta: float) -> void:
	sample_wait -= delta
	if sample_wait > 0: return
	sample_wait = .1
	var arena: CombatArena = screen.arena
	var actors: Array[Dictionary] = []
	for actor: CombatActor in screen.session.actors:
		actors.append({"position": [actor.position.x, actor.position.y], "health": actor.health, "resolved": actor.resolved, "pixel": physical(arena.get_global_transform_with_canvas() * (arena.arena_offset() + actor.position * arena.arena_stretch()))})
	var row: Dictionary = {"focus": screen.session.focus_active, "point": [screen.session.focus_point.x, screen.session.focus_point.y], "uses": screen.session.active_combat.uses, "cooldown": screen.session.active_combat.cooldown, "kills": screen.session.kills, "paused": screen.session.paused, "phase": screen.session.phase, "events": events, "actors": actors, "center": physical(arena.get_global_rect().get_center()), "arena": str(arena.get_global_rect())}
	row["button"] = physical(screen.ability_button.get_global_rect().get_center())
	row["screen_transform"] = str(get_viewport().get_screen_transform())
	var file: FileAccess = FileAccess.open("user://qa_telemetry.tmp", FileAccess.WRITE)
	file.store_string(JSON.stringify(row))
	file.close()
	DirAccess.rename_absolute("user://qa_telemetry.tmp", "user://qa_telemetry.json")
