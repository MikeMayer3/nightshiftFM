extends RefCounted
## State-contract tests only. Fixtures are not implemented gameplay recipes.

const RECIPES: Array[Array] = [
	["ball_lightning", "arc_aerial", "reverb_well"],
	["dead_zone", "static_net", "bass_driver"],
	["b_side", "needle_swarm", "echo_deck"],
	["live_wire", "arc_aerial", "static_net"],
	["pressure_drop", "bass_driver", "reverb_well"],
	["double_drop", "echo_deck", "bass_driver"],
	["needle_thread", "main", "needle_swarm"],
	["feedback_loop", "shield", "arc_aerial"],
]

func run(context: TestContext) -> bool:
	_test_configuration(context)
	_test_selection(context)
	_test_snapshot(context)
	_test_every_recipe(context)
	return true

func _definitions() -> Array[SynergyDefinition]:
	var definitions: Array[SynergyDefinition] = []
	for row: Array in RECIPES:
		var definition: SynergyDefinition = SynergyDefinition.new()
		definition.id = StringName(row[0])
		definition.name_key = StringName("patchboard.%s.name" % row[0])
		definition.description_key = StringName("patchboard.%s.description" % row[0])
		definition.endpoint_ids = [StringName(row[1]), StringName(row[2])]
		definitions.append(definition)
	return definitions

func _configured(context: TestContext) -> PatchboardState:
	var board: PatchboardState = PatchboardState.new()
	context.check(board.configure(_definitions()).is_empty(), "M6: configure eight recipe fixtures")
	return board

func _test_configuration(context: TestContext) -> void:
	var board: PatchboardState = PatchboardState.new()
	context.check(not board.configure([]).is_empty(), "M6: empty catalog rejected")
	context.check(not board.configure([null]).is_empty(), "M6: null recipe rejected")
	var definitions: Array[SynergyDefinition] = _definitions()
	context.check(not board.configure([definitions[0], definitions[0]]).is_empty(), "M6: duplicate catalog ID rejected")
	definitions[0].endpoint_ids = [&"arc_aerial", &"arc_aerial"]
	context.check(not board.configure(definitions).is_empty(), "M6: duplicate recipe endpoints rejected")
	definitions[0].endpoint_ids = [&"arc_aerial"]
	context.check(not board.configure(definitions).is_empty(), "M6: missing second endpoint rejected")
	definitions[0].endpoint_ids = [&"arc_aerial", &"unknown"]
	context.check(not board.configure(definitions).is_empty(), "M6: unknown catalog endpoint rejected")
	definitions = _definitions()
	definitions[0].id = &"Bad ID"
	context.check(not board.configure(definitions).is_empty(), "M6: base content validation retained")
	definitions = _definitions()
	definitions.append(definitions[0])
	context.check(not board.configure(definitions).is_empty(), "M6: ninth recipe rejected")
	definitions = _definitions()
	context.check(board.configure(definitions).is_empty(), "M6: failed setup is atomic and retryable")
	definitions[0].endpoint_ids.clear()
	context.check(not board.preview(&"ball_lightning", [])["eligible"], "M6: state does not retain mutable content endpoints")
	context.check(not board.configure(_definitions()).is_empty(), "M6: live catalog cannot be replaced")
	context.check(not board.preview(&"unknown", [])["known"], "M6: unknown recipe preview is explicit")

func _test_selection(context: TestContext) -> void:
	var board: PatchboardState = _configured(context)
	var equipped: Array[StringName] = [&"arc_aerial", &"static_net", &"bass_driver", &"main", &"shield"]
	var pair: Array[StringName] = [&"live_wire", &"dead_zone"]
	context.check(not board.rewire(pair, equipped, true, false).is_empty(), "M6: locked board cannot equip recipes")
	context.check(board.rewire(pair, equipped, true, true).is_empty(), "M6: two recipes may share an endpoint")
	context.check(board.active_ids() == pair, "M6: preserves slot order")
	context.check(not board.rewire([&"live_wire", &"live_wire"], equipped, true, true).is_empty(), "M6: duplicate active recipe rejected")
	context.check(not board.rewire([&"live_wire", &"dead_zone", &"feedback_loop"], equipped, true, true).is_empty(), "M6: third active recipe rejected")
	context.check(not board.rewire([&"b_side"], equipped, true, true).is_empty(), "M6: unequipped prerequisites rejected")
	context.check(not board.rewire([&"unknown"], equipped, true, true).is_empty(), "M6: unknown selection rejected")
	context.check(not board.rewire([], equipped, false, true).is_empty(), "M6: no combat or mid-wave draft rewiring, even to clear slots")
	context.check(board.active_ids() == pair, "M6: rejected rewire leaves prior pair untouched")
	context.check(board.is_active(&"live_wire", equipped), "M6: equipped selected recipe active")
	context.check(not board.is_active(&"live_wire", [&"arc_aerial"]), "M6: removed endpoint immediately disables selection")
	context.check(not board.is_active(&"feedback_loop", equipped), "M6: eligible but inactive recipe remains inactive")
	context.check(not board.is_active(&"unknown", equipped), "M6: unknown recipe never active")
	var duplicate_equipment: Array[StringName] = equipped.duplicate()
	duplicate_equipment.append(&"arc_aerial")
	context.check(not board.rewire(pair, duplicate_equipment, true, true).is_empty(), "M6: duplicate equipment rejected")
	context.check(not board.rewire([], [&"unknown"], true, true).is_empty(), "M6: unknown equipment rejected")
	context.check(not board.rewire([], PatchboardState.SUPPORT_IDS, true, true).is_empty(), "M6: six-support equipment rejected")
	var detached: Array[StringName] = board.active_ids()
	detached.clear()
	context.check(board.active_ids() == pair, "M6: active-ID accessor does not leak mutable state")
	var preview: Dictionary = board.preview(&"live_wire", [&"arc_aerial"])
	context.check(preview["missing_endpoint_ids"] == [&"static_net"], "M6: preview names missing prerequisite")
	preview["endpoint_ids"].clear()
	context.check(not board.preview(&"live_wire", [])["eligible"], "M6: preview cannot mutate catalog")
	context.check(board.rewire([&"feedback_loop"], equipped, true, true).is_empty(), "M6: intermission replacement accepted")
	context.check(not board.is_active(&"live_wire", equipped), "M6: removed recipe loses selection immediately")
	board.reset_for_mission()
	context.check(board.active_ids().is_empty(), "M6: mission reset clears connection selection")
	context.check(board.rewire([], equipped, true, false).is_empty(), "M6: locked board may remain empty")

func _test_snapshot(context: TestContext) -> void:
	var board: PatchboardState = _configured(context)
	var equipped: Array[StringName] = [&"arc_aerial", &"static_net", &"bass_driver"]
	var pair: Array[StringName] = [&"live_wire", &"dead_zone"]
	context.check(board.rewire(pair, equipped, true, true).is_empty(), "M6: save fixture selection accepted")
	var data: Dictionary = board.to_data()
	var recovered: PatchboardState = _configured(context)
	context.check(recovered.restore(JSON.parse_string(JSON.stringify(data)), equipped, true).is_empty(), "M6: JSON round-trip restores exact connections")
	context.check(recovered.active_ids() == pair, "M6: restored slot order matches")
	data["connections"].clear()
	context.check(board.active_ids() == pair, "M6: serialized data cannot mutate active selection")
	var malformed: Array = [
		null, [], "bad", {},
		{"schema_version": true, "connections": []},
		{"schema_version": "1", "connections": []},
		{"schema_version": 2, "connections": []},
		{"schema_version": 1.5, "connections": []},
		{"schema_version": NAN, "connections": []},
		{"schema_version": INF, "connections": []},
		{"schema_version": 1, "connections": [], "unlocked": true},
		{"schema_version": 1, "connections": "live_wire"},
		{"schema_version": 1, "connections": [7]},
		{"schema_version": 1, "connections": ["unknown"]},
		{"schema_version": 1, "connections": ["live_wire", "live_wire"]},
		{"schema_version": 1, "connections": ["live_wire", "dead_zone", "b_side"]},
	]
	for invalid: Variant in malformed:
		context.check(not recovered.restore(invalid, equipped, true).is_empty(), "M6: malformed save rejected")
		context.check(recovered.active_ids() == pair, "M6: failed restore is atomic")
	context.check(not recovered.restore(board.to_data(), equipped, false).is_empty(), "M6: snapshot cannot unlock patchboard")
	context.check(not recovered.restore(board.to_data(), [&"arc_aerial"], true).is_empty(), "M6: snapshot cannot spoof equipped prerequisites")
	var empty_board: PatchboardState = PatchboardState.new()
	context.check(not empty_board.restore(board.to_data(), equipped, true).is_empty(), "M6: restore requires configured catalog")
	context.check(empty_board.active_ids().is_empty(), "M6: failed restore leaves new board empty")
	context.check(recovered.restore({"schema_version": 1, "connections": []}, equipped, false).is_empty(), "M6: empty locked snapshot accepted")
	context.check(recovered.active_ids().is_empty(), "M6: explicit empty snapshot clears stale selections")

func _test_every_recipe(context: TestContext) -> void:
	var board: PatchboardState = _configured(context)
	for definition: SynergyDefinition in _definitions():
		var request: Array[StringName] = [definition.id]
		var equipped: Array[StringName] = definition.endpoint_ids.duplicate()
		context.check(board.rewire(request, equipped, true, true).is_empty(), "M6: catalog pair selectable: %s" % definition.id)
		context.check(board.is_active(definition.id, equipped), "M6: selected catalog pair active: %s" % definition.id)
		equipped.pop_back()
		context.check(not board.is_active(definition.id, equipped), "M6: missing endpoint disables: %s" % definition.id)
