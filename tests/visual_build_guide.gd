extends SceneTree
## Staged readable-choice checks; never labeled an unfamiliar-player session.
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for dimensions: Vector2i in [Vector2i(360,640),Vector2i(450,950),Vector2i(1024,768)]:
		root.size=dimensions; root.content_scale_size=Vector2i(720,1280)
		var boot: BootScreen = load("res://scenes/boot/boot.tscn").instantiate()
		boot.save_path="user://p1_visual_%d.json" % Time.get_ticks_usec()
		root.add_child(boot)
		boot.show_page(BootScreen.Page.COMBAT)
		var screen: CombatScreen=boot.combat
		screen.set_process(false); screen.arena.set_process(false)
		var s: CombatSession=screen.session
		# Synthetic branch states are presentation fixtures, not durable campaign progress.
		s.checkpoint_changed.disconnect(screen._save_checkpoint)
		checks.check(s.start_campaign(42,&"run.1",{"main":"pulse","shield":"capacitor","support":"needle_swarm"},{"mission":1,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""}),"staged unlocked loadout starts")
		checks.check(not screen.save_failed and not screen.recovery_required,"isolated fixture has no save-recovery overlay")
		# Fixed decision fixture, clearly separate from the legal full-run driver.
		s.advance(.1)
		s.draft.track(&"needle_swarm").accept(&"m5.needle_swarm.t0",[])
		s.phase=CombatSession.Phase.DRAFT
		s.draft.offers.assign([&"m5.needle_swarm.b3",&"recruit.echo_deck",&"m5.pulse.t0"])
		var panel: DraftPanel=DraftPanel.new(); root.add_child(panel)
		panel.show_draft(s)
		RadioPreferences.current.values.large_text=true
		RadioPreferences.current.apply_fonts(panel)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		capture("draft",dimensions)
		var selected_ids: Array[StringName] = []
		panel.selected.connect(func(id: StringName) -> void: selected_ids.append(id))
		var diagram: ConnectionDiagram = panel.cards[0].find_children("*","VBoxContainer",true,false).filter(func(node: Node) -> bool: return node is ConnectionDiagram)[0]
		click_at(diagram.get_global_rect().get_center())
		await process_frame
		checks.check(selected_ids==[&"m5.needle_swarm.b3"],"pointer on diagram selects its owning upgrade card")
		checks.check(panel.cards.size()==3,"three choices remain available")
		for card: Button in panel.cards:
			checks.check(card.size.x<=panel.size.x and card.custom_minimum_size.y>=176,"card stays inside scroll sheet width")
		var snapshot: Dictionary=s.to_checkpoint()
		click_at(panel.info_buttons[0].get_global_rect().get_center())
		RadioPreferences.current.apply_fonts(panel)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		capture("branch-details",dimensions)
		checks.check(s.to_checkpoint()==snapshot,"real info button is read-only")
		checks.check(panel.column.get_children().any(func(node: Node) -> bool: return node is ConnectionDiagram),"branch details contain diagrams")
		var scroll: ScrollContainer=panel.column.get_parent()
		checks.check(scroll.get_h_scroll_bar().max_value<=scroll.size.x+1,"large text details do not overflow horizontally")
		panel.queue_free(); await process_frame
		var patch: PatchboardPanel=PatchboardPanel.new(); root.add_child(patch)
		s.paused=true
		patch.show_unavailable=true
		patch.open(s,MissionProfile.new(),true)
		patch.connection_toggle.pressed.emit()
		RadioPreferences.current.apply_fonts(patch)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		capture("connections-missing",dimensions)
		checks.check(patch.recipe_buttons[&"needle_thread"].disabled,"missing marking branch cannot connect")
		s.draft.track(&"needle_swarm").accept(&"m5.needle_swarm.b3",[])
		patch.render()
		checks.check(not patch.recipe_buttons[&"needle_thread"].disabled,"actual branch makes connection available")
		patch.recipe_buttons[&"needle_thread"].pressed.emit()
		checks.check(s.patchboard.slots[0]==&"needle_thread","real Connect button wires chosen slot")
		RadioPreferences.current.apply_fonts(patch)
		await process_frame; await process_frame; await RenderingServer.frame_post_draw
		capture("connected",dimensions)
		checks.check(patch.scroll.get_h_scroll_bar().max_value<=patch.scroll.size.x+1,"connection catalogue fits large text width")
		RadioPreferences.current.values.large_text=false
		patch.queue_free(); boot.queue_free(); await process_frame
	print("RESULT: %d rendered build checks; %d failures" % [checks.checks,checks.failures])
	quit(0 if checks.failures==0 else 1)

func capture(label: String, dimensions: Vector2i) -> void:
	var file_name: String = "%s-%dx%d.png" % [label,dimensions.x,dimensions.y]
	root.get_texture().get_image().save_png("res://docs/evidence/P1-builds/" + file_name)

func click_at(point: Vector2) -> void:
	for down: bool in [true,false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true)
