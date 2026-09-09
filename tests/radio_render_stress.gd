extends SceneTree
## Render-only fixture; does not establish real encounter balance or phone FPS.
var arena: CombatArena

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	root.size = Vector2i(450, 800)
	var session: CombatSession = CombatSession.new()
	session.start_arsenal(42, &"run.1", ArsenalContent.DEFAULT)
	session.phase = CombatSession.Phase.COMBAT
	session.actors.clear()
	for index: int in 150:
		var definitions: Array[EnemyDefinition] = [CombatContent.SWARMER, CombatContent.DIVER, CombatContent.CARRIER]
		var actor: CombatActor = CombatActor.from_definition(definitions[index % 3], index + 1, Vector2(25 + (index % 15) * 42, 75 + (index / 15) * 48))
		session.actors.append(actor)
	for index: int in 400:
		var actor: CombatActor = CombatActor.from_definition(CombatContent.SWARMER, 151 + index, Vector2(20 + (index % 25) * 24, 65 + (index / 25) * 33))
		actor.projectile = true
		actor.radius = 5
		session.actors.append(actor)
	for family: StringName in [&"bass_driver", &"static_net", &"echo_deck", &"reverb_well"]:
		session.draft.equip(family)
	arena = CombatArena.new()
	arena.session = session
	arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(arena)
	arena.set_process(false)
	for index: int in 12:
		arena.pulses.append({"center": Vector2(80 + (index % 4) * 150, 150 + (index / 4) * 150), "radius": Vector2(60, 75), "source": &"bass_driver", "left": .25})
	var rows: Array[Dictionary] = []
	for low: bool in [false, true]:
		RadioPreferences.current.values.low_effects = low
		var samples: Array[float] = []
		var memory_start: float = 0
		var previous: int = Time.get_ticks_usec()
		for frame: int in 420:
			arena.queue_redraw()
			await RenderingServer.frame_post_draw
			var now: int = Time.get_ticks_usec()
			if frame >= 120: samples.append((now - previous) / 1000.0)
			if frame == 120: memory_start = Performance.get_monitor(Performance.MEMORY_STATIC)
			previous = now
		samples.sort()
		var row: Dictionary = {"low_effects": low, "frames": samples.size(), "median_ms": samples[150], "p95_ms": samples[284],
			"static_bytes_start": memory_start, "static_bytes_end": Performance.get_monitor(Performance.MEMORY_STATIC),
			"enemies": 150, "projectiles": 400, "pulses": 12, "remaining_actors": session.actors.size(),
			"scope": "desktop render-only fixture, 120 warmup frames then 300 measured frames; no physical-device acceptance",
			"os": OS.get_name(), "processor": OS.get_processor_name(), "engine": Engine.get_version_info().string}
		rows.append(row)
		print(JSON.stringify(row))
		root.get_texture().get_image().save_png("res://docs/evidence/M10/" + "stress-" + ("low" if low else "normal") + ".png")
	FileAccess.open("res://docs/evidence/M10/render-stress.json", FileAccess.WRITE).store_string(JSON.stringify(rows, "\t"))
	arena.queue_free()
	await process_frame
	quit(0 if rows.all(func(row: Dictionary) -> bool: return row.remaining_actors == 550) else 1)
