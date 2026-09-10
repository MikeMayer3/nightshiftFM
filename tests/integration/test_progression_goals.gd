extends RefCounted
const CAMPAIGN = preload("res://tests/integration/test_campaign_screen.gd")
const ACHIEVEMENTS = preload("res://tests/unit/test_achievements.gd")

func run(t: TestContext, tree: SceneTree) -> bool:
	for cleared: int in 13:
		var profile: MissionProfile = CAMPAIGN.new().profile_at(cleared)
		var before: Dictionary = profile.to_data()
		var goal: Dictionary = ProgressionGoals.next(profile)
		t.check(not goal.is_empty() and goal.state == "locked", "unearned reward remains at campaign progress %d" % cleared)
		if goal.kind == "color":
			t.check(goal.id in CampaignContent.options(cleared, "support"), "color goal's support is actually available")
		else:
			t.check(goal.id not in CampaignContent.options(cleared, goal.kind) and goal.id in CampaignContent.options(goal.target, goal.kind), "goal describes actual unlock threshold")
		for row: Dictionary in ProgressionGoals.equipment(profile.campaign, ArsenalContent.DEFAULT):
			t.check((row.state != "locked") == (row.id in CampaignContent.options(cleared, row.kind)), "reward state matches authoritative equipment eligibility")
			t.check((row.state == "equipped") == (ArsenalContent.DEFAULT[row.kind] == row.id), "equipped and earned equipment remain distinct")
		t.check(profile.to_data() == before, "reward queries never mutate progression")
	var complete: MissionProfile = CAMPAIGN.new().profile_at(12)
	for family: String in ArsenalContent.FAMILIES: complete.campaign.mastery[family] = ["m5.%s.b1cap" % family]
	t.check(ProgressionGoals.next(complete).is_empty(), "all-earned catalogue stops recommending completed goals")
	var profile: MissionProfile = CAMPAIGN.new().profile_at(1)
	profile.achievements.track(&"first_broadcast")
	var before_ids: Array[String] = ProgressionGoals.earned_ids(profile)
	var s: CombatSession = CombatSession.new()
	s.start_campaign(11, &"run.2", ArsenalContent.DEFAULT, {"mission": 2, "cleared": 1, "modules": []})
	profile.next_run = 3
	# Synthetic evaluator fixture; never player progress or production eligibility.
	s.achievement_run.eligible = true
	ACHIEVEMENTS.new().capstone(s, &"arc_aerial")
	s.wave = 10
	s._finish(true)
	profile.commit_reward(s.run_id, s)
	var rewards: Array[Dictionary] = ProgressionGoals.newly_earned(profile, before_ids, ArsenalContent.DEFAULT)
	t.check(rewards.any(func(row: Dictionary) -> bool: return row.id == "echo_deck" and row.state == "earned"), "mission 2 result exposes newly earned Tape Deck")
	t.check(rewards.any(func(row: Dictionary) -> bool: return row.kind == "color" and row.id == "arc_aerial"), "capstone win exposes actual station color reward")
	t.check(profile.achievements.tracked.is_empty(), "completed tracked goal transitions out")
	t.check(ProgressionGoals.next(profile).target == 3, "next reward advances after victory")
	var committed: Dictionary = profile.to_data()
	profile.commit_reward(s.run_id, s)
	ProgressionGoals.newly_earned(profile, before_ids, ArsenalContent.DEFAULT)
	t.check(profile.to_data() == committed, "repeated result commit and presentation do not duplicate rewards")
	var copy: MissionProfile = MissionProfile.new()
	t.check(copy.restore(JSON.parse_string(JSON.stringify(committed))), "earned rewards restore through real schema")
	t.check(ProgressionGoals.earned_ids(copy) == ProgressionGoals.earned_ids(profile), "reward availability survives reload")
	var practice: Dictionary = ProgressionGoals.achievement(MissionProfile.new().achievements, &"first_broadcast", false)
	t.check(TranslationServer.translate("P6_PRACTICE") in practice.requirement, "debug tracked goal explains unavailable progress")
	# Exercise actual tracking/equipping signals through Boot's atomic profile save.
	var path: String = "user://p6_goal_ui.json"
	var store: MissionStore = MissionStore.new(path)
	t.check(store.save(profile, {}) == OK, "P6 isolated profile fixture saves")
	var boot: BootScreen = preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = path; tree.root.add_child(boot)
	boot.show_page(BootScreen.Page.CAMPAIGN)
	boot.campaign_panel.show_rewards()
	for node: Node in boot.campaign_panel.column.get_children():
		if node is Button and node.get_meta("color_id", "") == "arc_aerial": node.pressed.emit(); break
	var restored: MissionProfile = MissionProfile.new()
	t.check(restored.restore(store.load_save().profile) and restored.campaign.cosmetic == &"arc_aerial", "color equip button persists existing reward selection")
	boot.campaign_panel.show_achievements()
	for node: Node in boot.campaign_panel.column.get_children():
		if node is Button and node.get_meta("achievement_id", &"") == &"first_broadcast": node.pressed.emit(); break
	t.check(restored.restore(store.load_save().profile) and restored.achievements.title == &"first_broadcast", "title equip button persists earned title")
	boot.campaign_panel.show_achievements()
	for node: Node in boot.campaign_panel.column.get_children():
		if node is Button and node.get_meta("achievement_id", &"") == &"endless_three": node.pressed.emit(); break
	t.check(restored.restore(store.load_save().profile) and &"endless_three" in restored.achievements.tracked, "user-selected next goal persists through UI")
	boot.queue_free(); await tree.process_frame
	return true
