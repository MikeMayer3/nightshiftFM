extends SceneTree
## Isolated interactive playtest. Real UI, real clocks, no player-save writes.
var boot: BootScreen
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.title = "Nightshift FM — polish playtest"
	boot = load("res://scenes/boot/boot.tscn").instantiate()
	boot.save_path = "user://polish_interactive.json"
	root.add_child(boot)
