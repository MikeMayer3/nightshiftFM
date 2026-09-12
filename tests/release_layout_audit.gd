extends SceneTree
## Rendered production-page audit. Completed-profile fixtures are labeled synthetic.
const DIR: String = "res://docs/evidence/release-audit/layout/"
var issues: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var checked: int = 0
var tag: String
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for frame: int in 6: await process_frame
	await RenderingServer.frame_post_draw
func inspect(node: Node) -> void:
	if node is Control and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		var viewport: Rect2 = root.get_visible_rect()
		if rect.intersects(viewport) and node is not ScrollBar:
			checked += 1
			if rect.position.x < -1 or rect.end.x > viewport.end.x + 1:
				issues.append({"screen":tag,"kind":"horizontal-overflow","node":str(node.get_path()),"rect":str(rect),"text":node.text if node is Label or node is Button else ""})
			if node is Label and node.get_visible_line_count() < node.get_line_count():
				issues.append({"screen":tag,"kind":"clipped-label","node":str(node.get_path()),"text":node.text,"visible":node.get_visible_line_count(),"lines":node.get_line_count()})
	for child: Node in node.get_children(): inspect(child)
func capture(page: Node, name: String) -> void:
	tag = name
	await settle()
	var before: int = issues.size()
	inspect(page)
	root.get_texture().get_image().save_png(DIR + tag + ".png")
	samples.append({"screen":tag,"issues":issues.size()-before})
func run() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	RadioPreferences.current.values.sound=false
	RadioPreferences.current.values.music=false
	for dimensions: Vector2i in [Vector2i(320,568),Vector2i(360,640),Vector2i(450,1000),Vector2i(1024,768)]:
		root.size=dimensions; root.content_scale_size=Vector2i(720,1280)
		for large: bool in [false,true]:
			RadioPreferences.current.values.large_text=large
			var prefix: String="%dx%d-%s-"%[dimensions.x,dimensions.y,"large" if large else "normal"]
			var boot: BootScreen=load("res://scenes/boot/boot.tscn").instantiate()
			boot.save_path="user://release_layout_%d.json"%Time.get_ticks_usec()
			root.add_child(boot)
			await capture(boot,prefix+"menu")
			boot.show_page(BootScreen.Page.SETTINGS)
			await capture(boot.settings_panel,prefix+"settings")
			boot.show_page(BootScreen.Page.CAMPAIGN)
			await capture(boot.campaign_panel,prefix+"new-route")
			boot.campaign_panel.profile=preload("res://tests/integration/test_campaign_screen.gd").new().profile_at(12)
			for method: String in ["show_home","show_rewards","show_achievements","show_codex","show_records","show_modes","show_enemies","show_logs"]:
				boot.campaign_panel.call(method)
				await capture(boot.campaign_panel,prefix+method)
			boot.show_page(BootScreen.Page.ARSENAL)
			boot.picker.modules_body.show(); boot.picker.details_body.show()
			await capture(boot.picker,prefix+"equipment")
			boot.show_page(BootScreen.Page.COMBAT)
			boot.combat.set_process(false); boot.combat.arena.set_process(false)
			boot.combat.session.advance(8)
			boot.combat._refresh()
			await capture(boot.combat,prefix+"combat")
			boot.combat.toggle_pause()
			await capture(boot.combat.overlay,prefix+"pause")
			boot.combat.open_mixer()
			await capture(boot.combat.patchboard_panel,prefix+"mixer")
			boot.queue_free(); await process_frame
	FileAccess.open(DIR+"audit.json",FileAccess.WRITE).store_string(JSON.stringify({"controls_checked":checked,"screens":samples,"issues":issues},"\t"))
	print("RESULT: %d controls, %d screenshots, %d geometry findings"%[checked,samples.size(),issues.size()])
	quit(0 if issues.is_empty() else 1)
