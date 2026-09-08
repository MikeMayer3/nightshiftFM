class_name SignalContent
extends RefCounted
const VERSION: String = "m4.signal.1"
const ARC: TrackDefinition = preload("res://content/signal/tracks/arc_aerial.tres")
const BASS: TrackDefinition = preload("res://content/signal/tracks/bass_driver.tres")
const NET: TrackDefinition = preload("res://content/signal/tracks/static_net.tres")
const WAVES: Array[WaveDefinition] = [
	preload("res://content/signal/waves/wave_1.tres"),
	preload("res://content/signal/waves/wave_2.tres"),
	preload("res://content/signal/waves/wave_3.tres"),
	preload("res://content/signal/waves/wave_4.tres"),
	preload("res://content/signal/waves/wave_5.tres"),
	preload("res://content/signal/waves/wave_6.tres"),
	preload("res://content/signal/waves/wave_7.tres"),
	preload("res://content/signal/waves/wave_8.tres"),
	preload("res://content/signal/waves/wave_9.tres"),
	preload("res://content/signal/waves/wave_10.tres")
]
static func tracks() -> Array[TrackDefinition]:
	return [M3Content.MAIN, M3Content.SHIELD, ARC, BASS, NET]
