extends RefCounted
static func fixture() -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42, &"run.1", {"main":"pulse","shield":"relay","support":"arc_aerial"}, {"mission":1,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	s.advance(.1)
	return s
func run(t: TestContext) -> bool:
	var capacitor: CombatSession = CombatSession.new()
	capacitor.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	capacitor.run.shield.current = 10
	capacitor.hit_station(20,&"M2_SWARMER_NAME")
	t.check(is_equal_approx(float(capacitor.achievement_run.loss_history.breach),9),"passive mitigation is excluded from health-loss history")
	var boosted: CombatSession = CombatSession.new()
	boosted.start_campaign(42,&"run.2",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	boosted.run.shield.current = 10
	t.check(boosted.activate_shield(),"shield can be timed before an approaching threat")
	boosted.hit_station(20,&"M2_SWARMER_NAME")
	t.check(boosted.achievement_run.hull_damage==0 and capacitor.achievement_run.hull_damage==9,"timed shield prevents health loss for the same incoming hit")
	t.check(boosted.supports.report.totals.shield.absorbed==19,"shield contribution records effective absorption once")
	var s: CombatSession = fixture()
	s.run.shield.current = 10
	s.supports.overshield = 5
	s.hit_station(25, &"M2_SWARMER_NAME")
	t.check(s.achievement_run.loss_history.breach == 10.0, "loss history excludes regular and temporary shields")
	s.hit_station(20, &"COMBAT_PROJECTILE", &"COMBAT_PROJECTILE_HIT")
	t.check(s.achievement_run.loss_history.projectile == 20.0, "projectile health damage attributed independently")
	var snapshot: Dictionary = s.to_checkpoint()
	var restored: CombatSession = CombatSession.new()
	t.check(restored.restore_checkpoint(JSON.parse_string(JSON.stringify(snapshot,"",true,true))), "mid-wave health history survives JSON checkpoint")
	t.check(restored.achievement_run.loss_history == s.achievement_run.loss_history, "checkpoint keeps both damage categories")
	for run_session: CombatSession in [s, restored]:
		run_session.hit_station(10000, &"M2_SWARMER_NAME")
		t.check(run_session.achievement_run.loss_history.breach == 80.0, "overkill is clipped to actual health loss")
		t.check(PostRunAnalysis.loss_key(run_session) == &"P2_LOSS_BREACH", "majority health loss determines explanation")
	t.check(restored.achievement_run.loss_history == s.achievement_run.loss_history and restored.achievement_run.hull_damage == s.achievement_run.hull_damage, "replayed hit keeps exact result history")
	var end: CombatSession = CombatSession.new()
	t.check(end.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(),"",true,true))), "defeat report checkpoint restores")
	t.check(PostRunAnalysis.loss_key(end) == PostRunAnalysis.loss_key(s), "restored defeat keeps explanation")
	var legacy: Dictionary = s.to_checkpoint()
	legacy.achievements.broadcast.erase("loss_history")
	t.check(end.restore_checkpoint(legacy), "pre-P2 checkpoint remains accepted")
	t.check(PostRunAnalysis.loss_key(end) == &"P2_LOSS_UNKNOWN", "legacy loss does not invent damage history")
	var migrated: CombatSession = CombatSession.new()
	t.check(migrated.restore_checkpoint(JSON.parse_string(JSON.stringify(end.to_checkpoint(),"",true,true))), "migrated partial history remains valid")
	t.check(PostRunAnalysis.loss_key(migrated) == &"P2_LOSS_UNKNOWN", "partial flag survives another save")
	for corruption: Dictionary in [{"version":2}, {"breach":-1}, {"projectile":INF}, {"other":1000}, {"complete":1}, {"extra":1}]:
		var bad: Dictionary = s.to_checkpoint()
		bad.achievements.broadcast.loss_history.merge(corruption,true)
		t.check(not CombatSession.new().restore_checkpoint(bad), "invalid loss history rejected: " + str(corruption))
	var projectile: CombatSession = fixture()
	projectile.run.shield.current = 0
	projectile.hit_station(90,&"COMBAT_PROJECTILE",&"COMBAT_PROJECTILE_HIT")
	projectile.hit_station(10,&"M2_SWARMER_NAME")
	t.check(PostRunAnalysis.loss_key(projectile) == &"P2_LOSS_PROJECTILE", "last attacker cannot override majority")
	var mixed: CombatSession = fixture()
	mixed.run.shield.current = 0
	mixed.hit_station(50,&"COMBAT_PROJECTILE",&"COMBAT_PROJECTILE_HIT")
	mixed.hit_station(50,&"M2_SWARMER_NAME")
	t.check(PostRunAnalysis.loss_key(mixed) == &"P2_LOSS_MIXED", "tie has no invented majority")
	mixed.start_campaign(42,&"run.2",ArsenalContent.DEFAULT,{"mission":1,"cleared":12,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	t.check(mixed.achievement_run.hull_damage == 0.0, "new run resets health damage")
	t.check(mixed.achievement_run.loss_history.breach == 0.0, "new run resets cause history")
	t.check(mixed.actors.is_empty() and mixed.supports.overshield==0 and mixed.ability_left==0 and not mixed.focus_active,"restart clears temporary combat state")
	return true
