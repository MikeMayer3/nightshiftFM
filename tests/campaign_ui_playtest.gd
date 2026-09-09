extends Node
## QA observer: real boot/runtime, read-only control coordinates and save status.
var boot: BootScreen
var wait_time: float = 0
func _ready() -> void:
	boot = (load("res://scenes/boot/boot.tscn") as PackedScene).instantiate() as BootScreen
	add_child(boot)
func point(value: Vector2) -> Array[float]:
	var scaled: Vector2 = value * Vector2(DisplayServer.window_get_size()) / boot.get_viewport_rect().size
	return [scaled.x, scaled.y]
func controls(node: Node, output: Array) -> void:
	if node is BaseButton and node.is_visible_in_tree():
		var center: Vector2 = node.get_global_rect().get_center()
		var item: Dictionary = {"text": node.tr(node.text), "disabled": node.disabled, "point": point(center), "pressed": node.button_pressed}
		var parent: Node = node.get_parent()
		while parent != null:
			if parent is ScrollContainer:
				var bounds: Rect2 = parent.get_global_rect().grow(-24)
				if not bounds.has_point(center):
					var direction: float = 1.0 if center.y > bounds.end.y else -1.0
					item["scroll"] = point(bounds.get_center() + Vector2(0, bounds.size.y * .32 * direction))
					item["end"] = point(bounds.get_center() - Vector2(0, bounds.size.y * .32 * direction))
			parent = parent.get_parent()
		output.append(item)
	for child: Node in node.get_children(): controls(child, output)
func _process(delta: float) -> void:
	wait_time -= delta
	if wait_time > 0: return
	wait_time = .2
	var buttons: Array = []
	controls(boot, buttons)
	var row: Dictionary = {"page": boot.current_page, "buttons": buttons}
	if boot.picker != null: row["modules"] = boot.picker.modules; row["preview"] = boot.picker.preview.text
	if boot.combat != null:
		row["save_failed"] = boot.combat.save_failed
		row["hull"] = boot.combat.session.hull
		row["capacity"] = boot.combat.session.run.shield.capacity
		row["campaign"] = boot.combat.session.campaign.to_data() if boot.combat.session.campaign != null else {}
	var file: FileAccess = FileAccess.open("user://qa_ui.tmp", FileAccess.WRITE)
	file.store_string(JSON.stringify(row, "", true, true))
	file.close()
	DirAccess.rename_absolute("user://qa_ui.tmp", "user://qa_ui.json")
