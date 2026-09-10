extends SceneTree
## Identical harness runs in HEAD and P5. Synthetic stress is separate from live play.
func _initialize() -> void: run.call_deferred()
func make_session() -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42,&"run.1",{"main":"pulse","shield":"capacitor","support":"bass_driver"},{"mission":12,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	return s
func advance(s: CombatSession) -> void:
	if s.is_deciding():
		s.swap_branch(&"m5.bass_driver.b1")
		var chosen: StringName = s.draft.offers[0]
		for id: StringName in s.draft.offers:
			if s.draft.card(id).target_id == &"bass_driver": chosen = id; break
		s.choose_upgrade(chosen)
	if s.is_wiring(): s.launch_wave()
	if s.run.shield.current < 20: s.activate_shield()
	s.advance(CombatSession.STEP)
func run() -> void:
	root.size = Vector2i(450,1000)
	var rows: Array[Dictionary] = []
	# Find the densest sampled moment in one real legal mission-12 campaign.
	var campaign: CombatSession = make_session()
	var dense: Dictionary = {}
	var count: int = -1
	for step: int in 60000:
		advance(campaign)
		if campaign.actors.size() > count and &"m5.bass_driver.b1" in campaign.draft.track(&"bass_driver").choices and not campaign.is_deciding():
			count = campaign.actors.size(); dense = campaign.to_checkpoint().duplicate(true)
		if campaign.is_finished(): break
	if dense.is_empty(): printerr("FAIL: no upgraded real encounter"); quit(1); return
	for scenario: String in ["stress", "authored"]:
		for low: bool in [false,true]:
			RadioPreferences.current.values.low_effects = low
			var s: CombatSession = make_session()
			if not s.restore_checkpoint(dense): printerr("FAIL: performance capture restore"); quit(1); return
			var arena: CombatArena = CombatArena.new(); arena.session = s
			arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(arena); arena.set_process(false)
			s.support_effect.connect(arena.show_support); s.chain_fired.connect(arena.show_chain); s.combat_event.connect(arena.show_event)
			if scenario == "stress":
				s.actors.clear()
				for index: int in 550:
					var actor: CombatActor = CombatActor.from_definition(CombatContent.SWARMER,index+1,Vector2(25 + (index % 25)*24,75 + (index / 25)*22))
					actor.projectile = index >= 150; actor.radius = 5 if actor.projectile else actor.radius
					s.actors.append(actor)
				for index: int in 12:
					arena.pulses.append({"center":Vector2(80+(index%4)*150,150+(index/4)*150),"radius":Vector2(100,100),"source":&"bass_driver","left":.25,"wideband":true})
			var samples: Array[float] = []
			var simulation: Array[float] = []
			var process_times: Array[float] = []
			var draw_calls: Array[float] = []
			var start_memory: float = 0
			var previous: int = Time.get_ticks_usec()
			for frame: int in 420:
				var start: int = Time.get_ticks_usec()
				if scenario == "authored":
					advance(s); arena._process(CombatSession.STEP)
				var cpu: float = (Time.get_ticks_usec()-start)/1000.0
				arena.queue_redraw(); await RenderingServer.frame_post_draw
				var now: int = Time.get_ticks_usec()
				if frame >= 120:
					samples.append((now-previous)/1000.0); simulation.append(cpu)
					process_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
					draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
				if frame == 120: start_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
				previous = now
			samples.sort(); simulation.sort(); process_times.sort(); draw_calls.sort()
			rows.append({"scenario":scenario,"low_effects":low,"frames":300,"median_ms":samples[150],"p95_ms":samples[284],"process_p95_ms":process_times[284],"draw_calls_p95":draw_calls[284],"simulation_p95_ms":simulation[284],"static_bytes_start":start_memory,"static_bytes_end":Performance.get_monitor(Performance.MEMORY_STATIC),"actors":s.actors.size(),"wave":s.wave,"hull":s.hull,"elapsed":s.elapsed,"checkpoint_sha256":JSON.stringify(s.to_checkpoint(),"",true,true).sha256_text(),"scope":"Mac desktop; 120 warmup + 300 measured frames; no phone acceptance","os":OS.get_name(),"processor":OS.get_processor_name(),"engine":Engine.get_version_info().string})
			print(JSON.stringify(rows[-1]))
			arena.queue_free(); await process_frame
	FileAccess.open("res://docs/evidence/P5-payoff/performance.json",FileAccess.WRITE).store_string(JSON.stringify(rows,"\t"))
	quit(0)
