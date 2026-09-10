class_name RadioBroadcast
extends RefCounted
## Authored presentation only: observes simulation time; never consumes RNG or saves.
signal cue_started(kind: String)
const BOSS: StringName = &"m8.caller"
const HOLD: float = 7.0
const GAP: float = 24.0
var key: String = ""
var left: float = 0
var quiet_left: float = 0
var approaching: bool = false
var _wave: int = 0
var _resume_wave: int = -1
var _elapsed: float = 0
var _warned: bool = false
var _arrived: bool = false

static func enabled(s: CombatSession) -> bool:
	return RadioBalance.enabled(s) and BroadcastRules.expanded(s) and s.campaign.mode == "campaign" and s.campaign.mission <= 4

func attach(s: CombatSession, resumed: bool = false) -> void:
	key = ""
	left = 0
	quiet_left = 0
	approaching = false
	_wave = s.wave
	_elapsed = s.elapsed
	# A saved wave restarts at its checkpoint. Skip its speech, including anything
	# heard after that checkpoint, but retain the live visual threat indicator.
	_resume_wave = s.wave if resumed else -1
	_warned = false
	_arrived = false

func update(s: CombatSession) -> void:
	var delta: float = maxf(0, s.elapsed - _elapsed)
	_elapsed = s.elapsed
	if not enabled(s) or s.is_finished():
		key = ""
		left = 0
		approaching = false
		return
	if s.paused or s.is_deciding() or s.is_wiring(): return
	left = maxf(0, left - delta)
	quiet_left = maxf(0, quiet_left - delta)
	if left == 0: key = ""
	approaching = false
	if s.phase != CombatSession.Phase.COMBAT: return
	if s.wave != _wave:
		_wave = s.wave
		if quiet_left == 0 and s.wave in [1, 4, 7]:
			play("P4_M%d_W%d" % [s.campaign.mission, s.wave], "caller" if s.wave == 4 else "station")
	var boss_entered: bool = false
	for actor: CombatActor in s.actors:
		if actor.definition_id == BOSS and not actor.resolved and actor.health > 0:
			if RadioBalance.entered(s, actor): boss_entered = true
			else: approaching = true
	var definition: WaveDefinition = s.wave_definition()
	var index: int = definition.enemy_ids.find(BOSS)
	if index >= s.spawn_index and index >= 0:
		var groups: int = index / definition.group_size - s.spawn_index / definition.group_size
		var until_spawn: float = s.spawn_time + groups * definition.spawn_interval
		approaching = until_spawn <= 5.0
	if s.wave <= _resume_wave: return
	if approaching and not _warned:
		_warned = true
		# A real boss warning can replace an ambient line; nothing is queued.
		play("P4_CALLER_WARNING", "warning")
	if boss_entered and not _arrived:
		_arrived = true
		play("P4_CALLER_ARRIVED", "caller")

func play(caption_key: String, kind: String) -> void:
	key = caption_key
	left = HOLD
	quiet_left = GAP
	cue_started.emit(kind)
