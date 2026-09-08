extends SceneTree
const FIXTURE: Script = preload("res://tests/unit/test_arsenal.gd")
func _initialize() -> void:
	var builder: RefCounted = FIXTURE.new()
	var rows: Array[Dictionary] = []
	for branch: int in [1, 2, 3]:
		for excluded: StringName in ArsenalContent.FAMILIES:
			var s: CombatSession = builder.fixture("sweep", "feedback")
			s.draft.tracks.clear()
			for id: StringName in [&"main", &"shield"]: s.draft.equip(id)
			for family: StringName in ArsenalContent.FAMILIES:
				if family != excluded: s.draft.equip(family)
			for index: int in s.draft.tracks.size(): s.draft.tracks[index] = builder.path(s.draft.tracks[index].definition, branch, 2)
			s.apply_ranks()
			for actor: CombatActor in s.actors: actor.speed = 0
			var started: int = Time.get_ticks_usec()
			var events: Array[int] = [0]
			s.combat_event.connect(func(_event: CombatEvent) -> void: events[0] += 1)
			for tick: int in 1800:
				if tick % 120 == 0:
					for actor: CombatActor in s.actors:
						actor.health = 10000
						actor.position.y = 420
				s.advance(1.0/60)
				if s.is_finished(): break
			var row: Dictionary = {"branch": branch, "excluded": String(excluded), "seconds": s.elapsed, "cpu_ms": (Time.get_ticks_usec() - started)/1000.0, "events": events[0], "pending_peak": s.arsenal.peak_pending, "report": s.arsenal.report.totals}
			rows.append(row)
			print(JSON.stringify(row.merged({"report": {}}, true)))
	FileAccess.open("res://docs/evidence/M5/stress.json", FileAccess.WRITE).store_string(JSON.stringify(rows, "\t"))
	quit(0 if rows.all(func(r: Dictionary) -> bool: return r.seconds > 29 and r.pending_peak < 128 and r.events < 20000) else 1)
