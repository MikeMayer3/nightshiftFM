extends Node
## Isolated Android QA entry point. Never included in the player APK.
var boot: BootScreen
var screen: CombatScreen
var samples: Array[float] = []
var started: int
var last_sample: int = 0
var runs: int = 0
var frame: int = 0
var rows: Array[Dictionary] = []
var warming: bool = true
var finished: bool = false

func _ready() -> void:
	RadioPreferences.current.values.sound=false
	RadioPreferences.current.values.music=false
	boot=preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path="user://p3_probe_mission.json"
	if not FileAccess.file_exists(boot.save_path):
		var profile: MissionProfile=MissionProfile.new()
		for mission: int in range(1,13):
			var s: CombatSession=CombatSession.new()
			s.start_campaign(42,StringName("run.%d"%mission),ArsenalContent.DEFAULT,{"mission":mission,"cleared":mission-1,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
			s.phase=CombatSession.Phase.VICTORY; s.wave=10; s.elapsed=600
			profile.next_run=mission+1; profile.commit_reward(s.run_id,s)
		MissionStore.new(boot.save_path).save(profile,{})
	add_child(boot)
	boot.mission_index=12
	boot._continuing=true
	boot.show_page(BootScreen.Page.COMBAT)
	screen=boot.combat
	await stress()
	start_run()
	started=Time.get_ticks_msec()
	set_process(true)

func stress() -> void:
	set_process(false)
	screen.set_process(false)
	var s: CombatSession=screen.session
	screen.arena.set_process(false)
	s.actors.clear()
	for index: int in 550:
		var a: CombatActor=CombatActor.from_definition(CombatContent.SWARMER,index+1,Vector2(25+(index%15)*42,90+(index/15%10)*48))
		if index>=150: a.projectile=true; a.radius=5
		s.actors.append(a)
	for low: bool in [false,true]:
		RadioPreferences.current.values.low_effects=low
		var timing: Array[float]=[]
		var previous: int=Time.get_ticks_usec()
		for index: int in 420:
			screen.arena.queue_redraw()
			await RenderingServer.frame_post_draw
			var now: int=Time.get_ticks_usec()
			if index>=120: timing.append((now-previous)/1000.0)
			previous=now
		timing.sort()
		rows.append({"kind":"render_stress","low_effects":low,"enemies":150,"projectiles":400,"frames":timing.size(),"median_ms":timing[150],"p95_ms":timing[284]})
	RadioPreferences.current.values.low_effects=false
	screen.arena.set_process(true)
	screen.set_process(true)
	write_state()

func start_run() -> void:
	screen.restart()
	screen.session.paused=true
	screen.session.patchboard.mixer.adjust(screen.session,0,4)
	screen.session.patchboard.mixer.adjust(screen.session,1,3)
	screen.session.paused=false
	runs+=1

func _process(delta: float) -> void:
	if finished: return
	var s: CombatSession=screen.session
	frame+=1
	if not s.paused and frame>120: samples.append(delta*1000)
	if s.is_finished():
		rows.append({"kind":"result","wave":s.wave,"victory":s.phase==CombatSession.Phase.VICTORY,"seconds":s.elapsed})
		start_run()
	elif s.is_deciding() and not s.paused:
		var best: int=-999
		var choice: StringName=s.draft.offers[0]
		for id: StringName in s.draft.offers:
			var card: UpgradeDefinition=s.draft.card(id)
			var score: int=0
			if card != null: score=100 if card.target_id==&"main" else 80 if SignalDraft.is_new(id) else 60 if card.target_id==&"shield" else 30
			if score>best: best=score; choice=id
		screen._choose_upgrade(choice)
	elif s.is_wiring(): s.launch_wave()
	elif s.run.shield.current<s.run.shield.capacity*.5: screen.use_shield()
	var age: int=Time.get_ticks_msec()-started
	if age-last_sample>=30000:
		last_sample=age
		var ordered: Array[float]=samples.duplicate(); ordered.sort()
		rows.append({"kind":"live","wall_seconds":age/1000.0,"runs":runs,"wave":s.wave,"actors":s.actors.size(),"frames":samples.size(),"p95_ms":ordered[int(ordered.size()*.95)] if not ordered.is_empty() else 0,"fps":Performance.get_monitor(Performance.TIME_FPS),"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"save_failed":screen.save_failed,"coach":screen.coach.current_hint})
		print("P3_SOAK ",JSON.stringify(rows[-1])); write_state()
	if warming and age>=30000:
		warming=false
		cleanup_sample("warm_cleanup")
	if age>=1230000:
		finished=true
		cleanup_sample("end_cleanup")
		screen.manual_pause=true; screen._sync_pause()
		write_state()

func cleanup_sample(label: String) -> void:
	# Same fresh-run cleanup at warm baseline and after 20 more minutes.
	start_run()
	rows.append({"kind":label,"static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)})

func write_state() -> void:
	FileAccess.open("user://p3_probe.json",FileAccess.WRITE).store_string(JSON.stringify({"finished":finished,"rows":rows,"engine":Engine.get_version_info().string,"scope":"Physical Android QA: render stress followed by normal-speed authored mission 12 loops; scripted legal drafts, not human play"},"\t"))
