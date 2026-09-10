extends RefCounted
const BOOT: PackedScene = preload("res://scenes/boot/boot.tscn")

func profile_at(cleared: int) -> MissionProfile:
	var profile: MissionProfile = MissionProfile.new()
	for index: int in cleared:
		var s: CombatSession = CombatSession.new()
		var identity: StringName = StringName("run.%d" % profile.next_run)
		profile.next_run += 1
		s.start_campaign(11, identity, ArsenalContent.DEFAULT, {"mission": index + 1, "cleared": index, "modules": []})
		s.phase = CombatSession.Phase.VICTORY
		s.wave = 10
		profile.commit_reward(identity, s)
	return profile

func run(t: TestContext, tree: SceneTree) -> bool:
	var path: String = "user://campaign_screen_test.json"
	var store: MissionStore = MissionStore.new(path)
	for cleared: int in [0, 1, 2, 3, 4, 12]:
		var profile: MissionProfile = profile_at(cleared)
		t.check(store.save(profile, {}) == OK, "campaign profile-only fixture persists %d" % cleared)
		var boot: BootScreen = BOOT.instantiate() as BootScreen
		boot.save_path = path
		tree.root.add_child(boot)
		await tree.process_frame
		t.check(not boot.continue_button.visible, "profile-only saves do not advertise a nonexistent run")
		boot.show_page(BootScreen.Page.CAMPAIGN)
		t.check(boot.campaign_panel.mission_name.text == TranslationServer.translate(CampaignContent.MISSIONS[mini(cleared, 11)].name_key), "selected tile displays its mission name")
		if cleared >= 3:
			boot.campaign_panel.station_buttons[0].pressed.emit()
			t.check(boot.campaign_panel.mission_name.text == TranslationServer.translate(CampaignContent.MISSIONS[0].name_key), "tile selection updates the mission name")
			boot.campaign_panel.station_buttons[mini(cleared, 11)].pressed.emit()
		for index: int in 12:
			t.check(boot.campaign_panel.station_buttons[index].disabled == (index > cleared), "campaign locks unavailable mission %d at clear %d" % [index + 1, cleared])
		boot.campaign_panel.launch_button.pressed.emit()
		var picker: ArsenalPicker = boot.picker
		t.check(picker.selectors[2].item_count == CampaignContent.options(cleared, "support").size(), "picker exposes only progressively unlocked support choices")
		t.check(picker.module_buttons.size() == CampaignContent.options(cleared, "modules").size(), "picker exposes modules only after their mission clears")
		if cleared >= 4:
			picker.module_buttons.hot_tubes.button_pressed = true
			picker.module_buttons.heavy_battery.button_pressed = true
			if cleared == 12:
				t.check(picker.module_buttons.long_mast.disabled, "third module disabled while two slots are occupied")
				picker.module_buttons.long_mast.toggled.emit(true)
				t.check(picker.modules.size() == 2, "direct stale toggle cannot exceed two module slots")
			picker.campaign_profile.save_preset(0, picker.selection, picker.modules)
			picker.settings_changed.emit()
			picker.module_buttons.hot_tubes.button_pressed = false
			t.check(picker.load_preset(0) and picker.modules == [&"hot_tubes", &"heavy_battery"], "preset restores module selection and controls")
			var disk: MissionProfile = MissionProfile.new()
			t.check(disk.restore(store.load_save().profile) and disk.campaign.presets[0].modules.size() == 2, "preset UI signal persists to atomic storage")
		# Returning from setup preserves the selected mission and working loadout.
		var chosen: Dictionary = picker.selection.duplicate()
		var fitted_modules: Array[StringName] = picker.modules.duplicate()
		var chosen_mission: int = picker.mission_index
		picker.back_requested.emit()
		t.check(boot.campaign_panel.selected_mission == chosen_mission, "setup Back preserves selected station")
		boot.campaign_panel.launch_button.pressed.emit()
		picker = boot.picker
		t.check(picker.selection == chosen and picker.modules == fitted_modules, "setup Back preserves equipment and fitted modules")
		t.check(not picker.details_body.visible and not picker.modules_body.visible and not picker.presets_body.visible, "setup opens with optional information collapsed")
		picker.launch_button.pressed.emit()
		boot.combat.set_process(false)
		t.check(not boot.combat.save_failed and boot.combat.session.campaign != null, "campaign UI launches a valid saved run")
		t.check(not boot.combat.session.is_wiring() and boot.combat.mixer_button != null, "mixer available immediately without forced connection tutorial")
		t.check(boot.combat.session.draft.track(&"main").rank() == 1 and boot.combat.session.draft.normal_count == 0, "launch starts at rank one without previous choices")
		var capacity: float = boot.combat.session.run.shield.capacity
		boot.combat.session.hull = 20
		boot.combat.restart()
		t.check(boot.combat.session.hull == boot.combat.session.maximum_hull() and boot.combat.session.run.shield.capacity == capacity, "Restart preserves selected baseline and clears damage")
		boot.combat.back_requested.emit()
		t.check(boot.continue_button.visible, "real run enables Continue")
		boot.continue_button.pressed.emit()
		boot.combat.set_process(false)
		t.check(not boot.combat.save_failed and boot.combat.session.campaign.cleared == cleared and boot.combat.session.run.shield.capacity == capacity, "Continue restores campaign and module baseline")
		boot.queue_free()
		await tree.process_frame
	var cosmetic: MissionProfile = profile_at(4)
	cosmetic.campaign.mastery["arc_aerial"] = ["m5.arc_aerial.b1cap"]
	cosmetic.campaign.cosmetic = &"arc_aerial"
	t.check(store.save(cosmetic, {}) == OK, "cosmetic-only profile saves")
	var styled: BootScreen = BOOT.instantiate() as BootScreen
	styled.save_path = path
	tree.root.add_child(styled)
	await tree.process_frame
	styled.show_page(BootScreen.Page.CAMPAIGN)
	styled.campaign_panel.launch_button.pressed.emit()
	styled.picker.launch_button.pressed.emit()
	styled.combat.set_process(false)
	t.check(styled.combat.arena.station_color == DraftPanel.ACCENTS[&"arc_aerial"] and styled.combat.session.hull == 100 and styled.combat.session.run.shield.capacity == 65, "provided save restores visible station color with unchanged combat baseline")
	styled.combat.profile.campaign = profile_at(12).campaign
	styled.combat.campaign_modules = [&"long_mast"]
	styled.combat.restart()
	t.check("90 / 90" in styled.combat.hull_caption.text, "combat HUD uses module-adjusted maximum hull")
	styled.combat.session.phase = CombatSession.Phase.DEFEAT
	styled.combat.session.hull = 0
	styled.combat._refresh()
	t.check("0 / 90" in styled.combat.details.text, "results display uses the same module-adjusted maximum hull")
	styled.queue_free()
	await tree.process_frame
	return true
