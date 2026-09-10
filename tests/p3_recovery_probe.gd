extends Node
## Accelerated emulator checkpoint driver; no physical performance claims.
var screen: CombatScreen
var action: String="hold"
var command_id: int=-1
var frames: int=0
func _ready() -> void:
	RadioPreferences.current.values.sound=false; RadioPreferences.current.values.music=false
	var boot: BootScreen=preload("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path="user://p3_recovery_mission.json"
	add_child(boot)
	boot._continuing=true; boot.show_page(BootScreen.Page.COMBAT)
	screen=boot.combat; screen.set_process(false)
	write_state()
func _process(_delta: float) -> void:
	frames+=1
	if frames%6==0 and FileAccess.file_exists("user://p3_command.json"):
		var command: Variant=JSON.parse_string(FileAccess.get_file_as_string("user://p3_command.json"))
		if command is Dictionary and int(command.get("id",-1))!=command_id:
			command_id=int(command.id); action=String(command.action)
	var s: CombatSession=screen.session
	match action:
		"combat":
			if s.elapsed<3 and not s.is_deciding(): s.advance(.2)
		"draft":
			if not s.is_deciding() and not s.is_finished(): s.advance(.2)
		"accept":
			if s.is_deciding(): screen._choose_upgrade(s.draft.offers[0])
			action="hold"
		"restart": screen.restart(); action="hold"
		"finish":
			if s.is_deciding():
				var best: int=-999
				var choice: StringName=s.draft.offers[0]
				for id: StringName in s.draft.offers:
					var card: UpgradeDefinition=s.draft.card(id)
					var score: int=0
					if card!=null: score=100 if SignalDraft.is_new(id) else 70 if card.target_id==&"main" else 20 if card.target_id!=&"shield" else 0
					if score>best: best=score;choice=id
				screen._choose_upgrade(choice)
			elif not s.is_finished():
				if s.patchboard.mixer.spent()==0:
					s.paused=true; s.patchboard.mixer.adjust(s,0,3);s.paused=false
				if s.run.shield.current<20: screen.use_shield()
				s.advance(.5)
		"resume": screen.manual_pause=false; screen._sync_pause(); action="hold"
		"pause": screen.manual_pause=true; screen._sync_pause(); action="hold"
		"shield": screen.use_shield(); action="hold"
		"replay": RadioPreferences.current.replay_coaching(); action="hold"
	screen._refresh()
	if frames%6==0: write_state()
func write_state() -> void:
	var s: CombatSession=screen.session
	var data: Dictionary={"phase":s.phase,"elapsed":s.elapsed,"paused":s.paused,"run_id":String(s.run_id),"choices":s.draft.normal_count,"accepted":s.draft.accepted,"completed":screen.profile.completed,"rewarded":screen.profile.rewarded_runs,"hint_seen":RadioPreferences.current.coach_seen,"hint":screen.coach.current_hint,"save_failed":screen.save_failed,"recovery_required":screen.recovery_required,"action":action,"command_id":command_id,"engine":Engine.get_version_info().string}
	FileAccess.open("user://p3_live.json",FileAccess.WRITE).store_string(JSON.stringify(data,"",true,true))
