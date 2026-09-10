class_name RadioAudio
extends Node
## Bounded original cues. Audio/haptics are optional and never drive simulation.
const SHOT: AudioStream = preload("res://assets/audio/radio/transmit.wav")
const HIT: AudioStream = preload("res://assets/audio/radio/hit.wav")
const TUNE: AudioStream = preload("res://assets/audio/radio/tune.wav")
const BED: AudioStream = preload("res://assets/audio/radio/station.wav")
const WARNING: AudioStream = preload("res://assets/audio/radio/warning.wav")
const SHIELD: AudioStream = preload("res://assets/audio/radio/shield.wav")
const STINGS: Dictionary = {
	"station": preload("res://assets/audio/radio/sign_on.wav"),
	"caller": preload("res://assets/audio/radio/line_open.wav"),
	"warning": preload("res://assets/audio/radio/ridge_alert.wav"),
}
var broadcast_player: AudioStreamPlayer
var warning_wait: float = 0
var shield_was_active: bool = false
var effects: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var session: CombatSession
var _shot_wait: float = 0
var _haptic_wait: float = 0

func _ready() -> void:
	for index: int in 4:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		effects.append(player)
	broadcast_player = AudioStreamPlayer.new()
	add_child(broadcast_player)
	music = AudioStreamPlayer.new()
	music.stream = BED
	add_child(music)
	music.finished.connect(func() -> void:
		if RadioPreferences.current.enabled("music") and session != null and not session.is_finished(): music.play())
	RadioPreferences.current.changed.connect(_preferences_changed)

func _process(delta: float) -> void:
	if session == null: return
	# Headless validation has no listener/audio device. Avoid creating dummy
	# playback voices, which Godot can retain across rapid test-scene teardown.
	if DisplayServer.get_name() == "headless": return
	if session.is_finished():
		music.stop()
		broadcast_player.stop()
		for player: AudioStreamPlayer in effects: player.stop()
		return
	var stopped: bool = session.paused or session.is_deciding() or session.is_wiring() or session.is_finished()
	broadcast_player.stream_paused = stopped
	music.volume_db = -6.0 if broadcast_player.playing else 0.0
	music.stream_paused = stopped
	for player: AudioStreamPlayer in effects: player.stream_paused = stopped
	if stopped: return
	warning_wait = maxf(0, warning_wait - delta)
	if BroadcastRules.expanded(session) and warning_wait <= 0 and session.actors.any(func(a: CombatActor) -> bool: return a.role >= EnemyDefinition.Role.CASTER and EncounterDirector.channel(a)):
		cue(WARNING)
		warning_wait = 2
	if session.ability_left > 0 and not shield_was_active: cue(SHIELD)
	shield_was_active = session.ability_left > 0
	_shot_wait = maxf(0, _shot_wait - delta)
	_haptic_wait = maxf(0, _haptic_wait - delta)
	if RadioPreferences.current.enabled("music") and not music.playing: music.play()

func _exit_tree() -> void:
	if is_instance_valid(broadcast_player):
		broadcast_player.stop()
		broadcast_player.stream = null
	# Release paused playback too, including rapid menu/restart transitions.
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for player: AudioStreamPlayer in effects:
		if is_instance_valid(player):
			player.stop()
			player.stream = null

func _preferences_changed() -> void:
	if not RadioPreferences.current.enabled("music"): music.stop()
	if not RadioPreferences.current.enabled("sound"):
		broadcast_player.stop()
		for player: AudioStreamPlayer in effects: player.stop()

func cue(stream: AudioStream) -> void:
	if DisplayServer.get_name() == "headless": return
	if not RadioPreferences.current.enabled("sound") or session == null or session.paused: return
	if broadcast_player.playing and stream in [TUNE, WARNING]: return
	for player: AudioStreamPlayer in effects:
		if not player.playing:
			player.stream = stream
			player.play()
			return

func shot(_target: Vector2) -> void:
	if _shot_wait > 0: return
	_shot_wait = .12
	cue(SHOT)

func hit(_amount: float) -> void:
	cue(HIT)
	if RadioPreferences.current.enabled("haptics") and _haptic_wait <= 0 and OS.has_feature("android"):
		Input.vibrate_handheld(35)
		_haptic_wait = .3

func wave_started(number: int) -> void:
	if RadioBroadcast.enabled(session) and number in [1, 4, 7]: return
	cue(TUNE)

func chain(points: PackedVector2Array, support: bool) -> void:
	if not support and not points.is_empty(): shot(points[-1])

func broadcast_cue(kind: String) -> void:
	if DisplayServer.get_name() == "headless" or not STINGS.has(kind): return
	if not RadioPreferences.current.enabled("sound") or session == null or session.paused or session.is_deciding() or session.is_wiring() or session.is_finished(): return
	for player: AudioStreamPlayer in effects:
		if player.stream in [TUNE, WARNING]: player.stop()
	# One dedicated voice: boss priority replaces, rather than overlaps, a sting.
	broadcast_player.stop()
	broadcast_player.stream_paused = false
	broadcast_player.stream = STINGS[kind]
	broadcast_player.play()
