extends SceneTree
var t: TestContext = TestContext.new()
var rows: Array[Dictionary] = []
const DIR: String = "res://docs/evidence/compact-upgrades/"
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for frame: int in 5: await process_frame
	await RenderingServer.frame_post_draw
func tap(button: Button) -> void:
	var point: Vector2 = button.get_global_rect().get_center()
	for down: bool in [true,false]:
		var e: InputEventMouseButton = InputEventMouseButton.new()
		e.position=point; e.button_index=MOUSE_BUTTON_LEFT; e.pressed=down; root.push_input(e,true)
	await settle()
func check_labels(node: Node) -> void:
	if node is Label and node.is_visible_in_tree():
		t.check(node.get_line_count()==node.get_visible_line_count(), "upgrade label keeps all text visible")
	for child: Node in node.get_children(): check_labels(child)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	for dimensions: Vector2i in [Vector2i(360,640),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size=dimensions; root.content_scale_size=Vector2i(720,1280)
		for large: bool in [false,true]:
			RadioPreferences.current.values.large_text=large
			for variant: String in ["tuned","branch","long-text"]:
				var s: CombatSession=CombatSession.new()
				s.start_campaign(42,&"run.1",{"main":"pulse","shield":"capacitor","support":"needle_swarm"},{"mission":1,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
				if variant=="tuned":
					for step: int in 800:
						if s.is_deciding() or s.is_finished(): break
						s.advance(.1)
					t.check(s.is_deciding() and s.draft.offers.size()==3,"actual Tuned threshold supplies three choices")
				else:
					s.advance(.1); s.phase=CombatSession.Phase.DRAFT
					s.draft.track(&"needle_swarm").accept(&"m5.needle_swarm.t0",[])
					s.draft.offers.assign([&"m5.needle_swarm.b3",&"recruit.echo_deck",&"m5.pulse.t0"])
					if variant=="long-text":
						var options: Array[UpgradeDefinition]=[]
						for track: UpgradeTrack in s.draft.tracks: options.append_array(track.definition.options)
						options.sort_custom(func(a: UpgradeDefinition,b: UpgradeDefinition) -> bool: return tr(String(a.name_key).trim_suffix("_NAME")+"_SHORT").length()>tr(String(b.name_key).trim_suffix("_NAME")+"_SHORT").length())
						s.draft.offers.assign([options[0].id,options[1].id,options[2].id])
				var snapshot: Dictionary=s.to_checkpoint()
				var panel: DraftPanel=DraftPanel.new(); root.add_child(panel); panel.show_draft(s)
				await settle()
				var scroll: ScrollContainer=panel.column.get_parent()
				var heights: Array[float]=[]
				for card: Button in panel.cards:
					heights.append(card.size.y)
					t.check(scroll.get_global_rect().encloses(card.get_global_rect()),"entire choice card visible without scrolling")
					check_labels(card)
				for info: Button in panel.info_buttons:
					t.check(info.size.x>=72 and info.size.y>=72,"info keeps a 72-unit touch target")
					t.check(scroll.get_global_rect().encloses(info.get_global_rect()),"info target is visible")
				t.check(scroll.get_v_scroll_bar().max_value<=scroll.get_v_scroll_bar().page,"three choices and actions fit without vertical scroll")
				t.check(scroll.get_h_scroll_bar().max_value<=scroll.size.x+1,"compact choices have no horizontal overflow")
				t.check(s.to_checkpoint()==snapshot,"compact layout does not change gameplay or checkpoint")
				rows.append({"size":str(dimensions),"large_text":large,"fixture":variant,"heights":heights,"content_height":scroll.get_v_scroll_bar().max_value,"available":scroll.get_v_scroll_bar().page})
				if variant=="branch":
					root.get_texture().get_image().save_png(DIR+"choices-%dx%d-%s.png"%[dimensions.x,dimensions.y,"large" if large else "normal"])
					await tap(panel.info_buttons[0])
					t.check(panel.cards.is_empty() and s.to_checkpoint()==snapshot,"info tap opens full details without choosing")
					var back: Button=panel.column.get_children().filter(func(n: Node) -> bool: return n is Button and n.text==tr("M3_BACK_DRAFT"))[0]
					await tap(back)
					t.check(panel.cards.size()==3,"Back restores the compact choices")
					var selected: Array[StringName]=[]
					panel.selected.connect(func(id: StringName) -> void: selected.append(id))
					await tap(panel.cards[2])
					t.check(selected==[&"m5.pulse.t0"],"third whole-card tap selects the correct upgrade once")
				panel.queue_free(); await process_frame
	FileAccess.open(DIR+"native.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":t.checks,"failures":t.failures,"cases":rows},"\t"))
	print("RESULT: %d compact upgrade checks; %d failures"%[t.checks,t.failures])
	quit(0 if t.failures==0 else 1)
