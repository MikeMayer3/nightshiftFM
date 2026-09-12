extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(450,1000);root.content_scale_size=Vector2i(720,1280)
	var boot: BootScreen=preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path="user://release_audit_static_net.json"
	root.add_child(boot);boot._continuing=true;boot.show_page(BootScreen.Page.COMBAT)
	for frame: int in 10:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/evidence/release-audit/restored-result-desktop.png")
	var s: CombatScreen=boot.combat
	print(JSON.stringify({"caption":s.shield_caption.text,"rect":str(s.shield_caption.get_global_rect()),"minimum":str(s.shield_caption.get_minimum_size()),"bar":str(s.shield_bar.get_global_rect()),"boost_visible":s.boost_duration_bar.visible,"button_visible":s.shield_button.visible,"button":str(s.shield_button.get_global_rect())}))
	quit()
