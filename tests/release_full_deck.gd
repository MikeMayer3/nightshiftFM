extends SceneTree
## Synthetic maximum-equipment render fixtures; no earned-progression claim.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var t: TestContext=TestContext.new()
	var folder: String="res://docs/evidence/release-audit/full-deck/"
	DirAccess.make_dir_recursive_absolute(folder)
	RadioPreferences.current.values.sound=false; RadioPreferences.current.values.music=false
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size=dimensions;root.content_scale_size=Vector2i(720,1280)
		for low: bool in [false,true]:
			RadioPreferences.current.values.low_effects=low
			RadioPreferences.current.values.reduced_flash=low
			var arena: CombatArena=CombatArena.new();root.add_child(arena)
			arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var s: CombatSession=CombatSession.new()
			s.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":12,"cleared":12,"modules":[]})
			for family: StringName in ArsenalContent.FAMILIES:
				if s.run.supports.size()>=5:break
				if s.draft.track(family)==null:s.draft.equip(family)
			arena.session=s;arena.set_process(false)
			s.phase=CombatSession.Phase.COMBAT;s.wave=10
			for i: int in 35:
				var enemy: CombatActor=s.spawn_enemy(CombatContent.SWARMER if i%2==0 else CombatContent.CARRIER,40+(i%7)*90)
				enemy.position.y=60+(i/7)*90
			s.chain_fired.connect(arena.show_chain);s.support_effect.connect(arena.show_support)
			for id: StringName in arena.equipped_supports():
				s.arsenal._deploy(s,Vector2(320,300),id,ArsenalStats.parameters(s.draft.track(id)),1)
			t.check(arena.equipped_supports().size()==5,"full-deck fixture has five supports")
			var positions: Array[float]=[arena.tower_position().x]
			for id: StringName in arena.equipped_supports():positions.append(arena.support_position(id).x)
			positions.sort()
			for i: int in range(1,positions.size()):t.check(positions[i]-positions[i-1]>=90,"tower and support art slots remain separated")
			for frame: int in 6:await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder+"%dx%d-%s.png"%[dimensions.x,dimensions.y,"reduced" if low else "normal"])
			arena.queue_free();await process_frame
	print("RESULT: %d full-deck checks; %d failures"%[t.checks,t.failures])
	quit(0 if t.failures==0 else 1)
