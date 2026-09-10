extends RefCounted
func run(t: TestContext) -> bool:
	var prefs: RadioPreferences = RadioPreferences.new()
	prefs.path="user://p3_unit_%d.json" % Time.get_ticks_usec()
	var legacy: Dictionary = {"schema":1,"options":RadioPreferences.DEFAULTS.duplicate()}
	t.check(RadioPreferences.valid(legacy),"pre-P3 preferences still validate")
	FileAccess.open(prefs.path,FileAccess.WRITE).store_string(JSON.stringify(legacy))
	prefs.load_preferences()
	t.check(prefs.coach_seen.is_empty(),"legacy options initialize unshown hints")
	prefs.remember_coach("shield"); prefs.remember_coach("shield")
	prefs.values.sound=false; prefs.save_preferences()
	prefs.coach_seen.clear(); prefs.load_preferences()
	t.check(prefs.coach_seen==["shield"] and not prefs.enabled("sound"),"hint state persists once while retaining settings")
	var bad: Dictionary = legacy.duplicate(true)
	for value: Variant in [["unknown"],["shield","shield"],[1],"shield"]:
		bad.coaching=value
		t.check(not RadioPreferences.valid(bad),"malformed coaching history rejected")
	prefs.replay_coaching(); prefs.load_preferences()
	t.check(prefs.coach_seen.is_empty() and not prefs.enabled("sound"),"replay resets hints without resetting options")
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42,&"run.1",ArsenalContent.DEFAULT,{"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	t.check(not CombatCoach.relevant(s,"shield") and not CombatCoach.relevant(s,"mixer"),"no coaching before threats or first upgrade")
	s.phase=CombatSession.Phase.COMBAT
	var actor: CombatActor = CombatActor.from_definition(CombatContent.SWARMER,1,Vector2(320,420))
	s.actors.append(actor)
	t.check(CombatCoach.relevant(s,"shield"),"shield coaching responds to approaching threat")
	s.paused=true
	t.check(not CombatCoach.relevant(s,"shield"),"coaching hides during pause")
	s.paused=false; s.activate_shield()
	t.check(CombatCoach.relevant(s,"boost"),"boost coaching follows actual live reserve")
	s.supports.overshield=0
	t.check(not CombatCoach.relevant(s,"boost"),"depleted reserve cannot claim a visible boost")
	s.draft.normal_count=1
	t.check(CombatCoach.relevant(s,"mixer"),"mixer introduced after first gear upgrade")
	prefs.free()
	return true
