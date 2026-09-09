extends RefCounted

const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")

func run(context: TestContext, tree: SceneTree) -> bool:
	var boot: BootScreen = BOOT.instantiate() as BootScreen
	boot.save_path = "user://test_boot_m3.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(boot.save_path + suffix): DirAccess.remove_absolute(boot.save_path + suffix)
	tree.root.add_child(boot)
	await tree.process_frame
	context.check(boot.current_page == BootScreen.Page.MENU and boot.menu.visible, "boot opens menu")
	context.check(boot.tr("BOOT_TITLE") == "Nightshift FM", "English translation imported")
	for action: StringName in [&"menu_back", &"pause", &"focus_target", &"aim_override", &"shield_ability"]:
		context.check(InputMap.has_action(action), "declared input action: %s" % action)
	(boot.menu.get_node("Start") as Button).pressed.emit()
	context.check(boot.campaign_panel != null, "Start opens campaign selection")
	boot.campaign_panel.launch_button.pressed.emit()
	context.check(boot.picker != null, "Campaign opens equipment selector")
	boot.picker.launch_button.pressed.emit()
	context.check(boot.combat != null and not boot.menu.visible, "Start signal opens combat")
	context.check(boot.combat.session.signal_progress != null, "New mission uses kill-meter flow")
	context.check(boot.combat.session.active_combat != null, "New mission starts active combat flow")
	var probe_seconds: float = boot.probe.clock.active_seconds
	await tree.create_timer(0.08).timeout
	context.check(boot.probe.clock.active_seconds == probe_seconds, "hidden diagnostic clock stays frozen during combat")
	boot.probe._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	context.check(not tree.paused, "hidden diagnostic cannot take combat pause ownership")
	boot.probe._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	boot.combat.back_requested.emit()
	context.check(boot.menu.visible, "combat Back returns to menu")
	(boot.menu.get_node("Settings") as Button).pressed.emit()
	context.check(boot.settings.visible and not boot.start_placeholder.visible, "Settings signal opens settings")
	var toggle: CheckButton = boot.settings.get_node("ShowSignal") as CheckButton
	toggle.button_pressed = false
	context.check(not boot.transmitter.show_signal, "setting disables decorative signal")
	(boot.settings.get_node("Back") as Button).pressed.emit()
	context.check(boot.menu.visible and not boot.settings.visible, "settings Back returns to menu")
	(boot.menu.get_node("Settings") as Button).pressed.emit()
	context.check(not toggle.button_pressed, "display preference survives page navigation")
	var back: InputEventAction = InputEventAction.new()
	back.action = &"menu_back"
	back.pressed = true
	boot._unhandled_input(back)
	context.check(boot.menu.visible, "menu_back action returns to menu")
	context.check((boot.menu.get_node("Quit") as Button).pressed.is_connected(boot._quit), "Quit signal is connected")
	boot.show_page(BootScreen.Page.SETTINGS)
	tree.root.go_back_requested.emit()
	context.check(boot.current_page == BootScreen.Page.MENU, "Android system Back returns from settings without exiting")
	context.check(not tree.quit_on_go_back, "Android automatic quit is disabled for in-app Back routing")
	boot.queue_free()
	await tree.process_frame
	return true
