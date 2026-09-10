extends SceneTree
## Controlled mechanism evidence; these actors and ranks are staged, not campaign wins.
const FIXTURE: Script=preload("res://tests/unit/test_patchboard.gd")
var t: TestContext=TestContext.new()
func _initialize() -> void: run.call_deferred()
func prepare(id: StringName, count: int) -> CombatSession:
	var s: CombatSession=FIXTURE.new().fixture(id)
	s.active_combat.automatic_radio=true
	s.actors.resize(count)
	for index: int in s.actors.size():
		var actor: CombatActor=s.actors[index]
		actor.position=Vector2(320,450-index*20)
		actor.elite=false; actor.jam_immune=false; actor.armor=0
	return s
func run() -> void:
	var rows: Array[Dictionary]=[]
	for count: int in [1,6]:
		for overlap: bool in [false,true]:
			var s: CombatSession=prepare(&"pressure_drop",count)
			if overlap: FIXTURE.new().deploy(s,&"reverb_well",s.actors[0].position)
			FIXTURE.new().deploy(s,&"bass_driver",s.actors[0].position)
			var damage: float=s.patchboard.totals.pressure_drop.damage
			t.check(damage>0 if overlap else damage==0,"Bass bonus requires Well overlap")
			rows.append({"build":"bass","targets":count,"overlap":overlap,"bonus_damage":damage})
	t.check(rows[3].bonus_damage/6 > rows[1].bonus_damage,"crowded overlap increases Bass bonus per target")
	for slowed: bool in [false,true]:
		for already_jammed: bool in [false,true]:
			var s: CombatSession=prepare(&"dead_zone",6)
			for actor: CombatActor in s.actors:
				if slowed: actor.status.apply_slow(.3,false,&"static_net")
				if already_jammed: actor.status.jam(.6,false,false)
			FIXTURE.new().deploy(s,&"bass_driver",s.actors[0].position)
			s.arsenal._tick_zones(s,.01)
			var control: float=s.patchboard.totals.dead_zone.control_seconds
			t.check(control>0 if slowed and not already_jammed else control==0,"Dead Zone requires slow and adds no jam during jam cooldown")
			rows.append({"build":"control","slowed":slowed,"already_jammed":already_jammed,"added_control_seconds":control,"bonus_damage":s.patchboard.totals.dead_zone.damage})
	for marked: bool in [false,true]:
		var s: CombatSession=prepare(&"needle_thread",2)
		if marked: s.arsenal.marks.append({"target":s.actors[0].serial,"strength":.2,"left":3.0})
		s.arsenal.fire_main(s,s.actors[0])
		var hits: int=s.actors.filter(func(actor: CombatActor) -> bool: return actor.health<actor.max_health).size()
		t.check(hits==(2 if marked else 1),"marked Pulse shot gains one aligned target")
		rows.append({"build":"precision","marked":marked,"targets_hit":hits})
	for id: StringName in [&"pressure_drop",&"dead_zone",&"needle_thread"]:
		var s: CombatSession=prepare(id,1)
		var actor: CombatActor=s.actors[0]
		actor.position.y=RadioBalance.ENTRY_Y-1
		var health: float=actor.health
		FIXTURE.new().exercise(s,id)
		t.check(actor.health==health,"connection cannot hit Incoming Signals approach")
	FileAccess.open("res://docs/evidence/P1-builds/mechanisms.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":t.checks,"failures":t.failures,"scenarios":rows},"\t"))
	print("RESULT: %d mechanism checks; %d failures" % [t.checks,t.failures])
	quit(0 if t.failures==0 else 1)
