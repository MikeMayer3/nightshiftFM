extends SceneTree
func _initialize() -> void:
	var session: CombatSession = CombatSession.new()
	var context: Dictionary = {"mission": 4, "cleared": 12, "modules": [], "mode": "campaign", "difficulty": 0, "contract": ""}
	assert(session.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, context))
	print("START ", session.active_combat.content_version)
	var snapshot: Dictionary = JSON.parse_string(JSON.stringify(session.to_checkpoint()))
	var copy: CombatSession = CombatSession.new()
	assert(copy.restore_checkpoint(snapshot), "expanded start checkpoint")
	session.launch_wave()
	session.advance(3)
	snapshot = JSON.parse_string(JSON.stringify(session.to_checkpoint()))
	assert(copy.restore_checkpoint(snapshot), "expanded actors checkpoint")
	print("PASS expanded initial snapshot")
	quit()
