extends RefCounted
func session(mission: int = 4) -> CombatSession:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42, &"run.1", ArsenalContent.DEFAULT, {"mission":mission,"cleared":mission-1,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	return s

func run(t: TestContext) -> bool:
	var s: CombatSession = session()
	var b: RadioBroadcast = RadioBroadcast.new()
	var cues: Array[String] = []
	b.cue_started.connect(func(kind: String) -> void: cues.append(kind))
	b.attach(s)
	s.advance(.1)
	var checkpoint: Dictionary = s.to_checkpoint()
	b.update(s)
	t.check(b.key == "P4_M4_W1" and cues == ["station"], "first-region opening plays once at real wave start")
	t.check(s.to_checkpoint() == checkpoint, "broadcast observer preserves simulation, saves and RNG")
	b.update(s)
	t.check(cues.size() == 1, "refresh does not repeat a cue")
	var hold: float = b.left
	for phase: CombatSession.Phase in [CombatSession.Phase.DRAFT, CombatSession.Phase.RECRUIT]:
		s.phase = phase; s.elapsed += 10; b.update(s)
		t.check(b.left == hold, "upgrade/recruit interruptions freeze captions")
	s.phase = CombatSession.Phase.COMBAT; s.paused = true
	s.elapsed += 10; b.update(s)
	t.check(b.left == hold, "pause freezes caption clock")
	s.paused = false; b.update(s)
	t.check(b.left == hold and cues.size() == 1, "resume neither advances nor repeats dialogue")
	s.elapsed += 8; s.wave = 4; b.update(s)
	t.check(b.key.is_empty() and cues.size() == 1, "rapid wave skips ambient chatter during minimum gap; no queue")
	s.elapsed += 25; s.wave = 7; b.update(s)
	t.check(b.key == "P4_M4_W7", "emergency notice follows authored wave event")
	s.wave = 10; s.spawn_index = 12; s.spawn_time = 5.1; b.update(s)
	t.check(not b.approaching, "no premature boss warning")
	s.spawn_time = 5; b.update(s)
	t.check(b.approaching and b.key == "P4_CALLER_WARNING" and cues[-1] == "warning", "warning preempts ambient line exactly five seconds before authored Caller spawn")
	var emitted: int = cues.size()
	b.update(s)
	t.check(cues.size() == emitted, "boss warning cannot repeat during approach")
	var boss: CombatActor = s.spawn_enemy(s.enemy_definition(RadioBroadcast.BOSS), 320)
	s.spawn_index = 13; b.update(s)
	t.check(b.approaching, "offscreen Caller retains visual warning")
	boss.position.y = RadioBalance.ENTRY_Y + boss.radius; b.update(s)
	t.check(not b.approaching and b.key == "P4_CALLER_ARRIVED", "arrival line follows actual combat entry, not wave number")
	boss.resolved = true; b.update(s)
	t.check(not b.approaching, "resolved boss cannot show a threat indicator")
	for wave: int in [1,4,7,10]:
		s.wave = wave; s.spawn_index = 12 if wave == 10 else 0; s.spawn_time = 2
		var resumed: RadioBroadcast = RadioBroadcast.new(); resumed.attach(s, true)
		resumed.update(s)
		t.check(resumed.key.is_empty(), "checkpoint restore skips current-wave dialogue")
		if wave == 10:
			t.check(resumed.approaching, "checkpoint restore preserves live boss warning even with speech suppressed")
			boss.resolved = false; s.spawn_index = 13; resumed.update(s)
			t.check(resumed.key.is_empty(), "restored wave cannot replay boss arrival speech")
	s.phase = CombatSession.Phase.DEFEAT; b.update(s)
	t.check(b.key.is_empty() and not b.approaching, "results clear presentation")
	s = session(5); b.attach(s); s.advance(.1); b.update(s)
	t.check(not RadioBroadcast.enabled(s) and b.key.is_empty(), "later regions stay outside P4 scope")
	s.campaign.mission = 4; s.campaign.mode = "endless"
	t.check(not RadioBroadcast.enabled(s), "campaign story cues do not leak into Endless")
	s.campaign.mode = "contract"
	t.check(not RadioBroadcast.enabled(s), "campaign story cues do not leak into Contracts")
	# Observe a real authored boss wave alongside an identical unobserved simulation.
	var observed: CombatSession = session()
	var control: CombatSession = session()
	for item: CombatSession in [observed, control]:
		item.wave = 10; item.phase = CombatSession.Phase.COMBAT
		item.auto_fire = false
	b.attach(observed)
	var warning_at: float = -1
	var spawn_at: float = -1
	for frame: int in 1500:
		observed.advance(CombatSession.STEP); control.advance(CombatSession.STEP)
		b.update(observed)
		if b.approaching and warning_at < 0: warning_at = observed.elapsed
		if observed.spawn_index == 13 and spawn_at < 0: spawn_at = observed.elapsed
	t.check(warning_at > 0 and spawn_at > 0 and absf((spawn_at-warning_at)-5) < .04, "real authored spawn timing gives five-second advance notice")
	t.check(observed.to_checkpoint() == control.to_checkpoint(), "1500 matched combat steps prove presentation leaves actors, damage and every RNG stream unchanged")
	return true
