class_name ProbeClock
extends Node
## Actual pausable process node, not a wall-clock timer.

var active_seconds: float = 0.0
var skip_next_frame: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if skip_next_frame:
		skip_next_frame = false
		return
	active_seconds += delta
