class_name RadioDial
extends Control
## Presentation-only analog hunting; earned kills still own upgrade timing.
var frequency: float = 100.1
var target: float = (frequency - 88) / 20
var _seed: int = -1
var _cycle: int = -1
var _stations: Array[int] = []
var value: float = 0
var max_value: float = 1
var displayed: float = target
var running: bool = true
var tuning_time: float = 0
var knob_angle: float = 0

func set_cycle(seed_value: int, cycle: int) -> void:
	if _seed == seed_value and _cycle == cycle: return
	if _seed != seed_value or _stations.is_empty():
		# Local presentation RNG: reproducible after restore, no run-stream mutation.
		var cosmetic: RandomNumberGenerator = RandomNumberGenerator.new()
		cosmetic.seed = (str(seed_value) + ":radio-stations").hash()
		_stations.clear()
		for index: int in 100: _stations.append(881 + index * 2)
		for index: int in range(99, 0, -1):
			var pick: int = cosmetic.randi_range(0, index)
			var previous: int = _stations[index]
			_stations[index] = _stations[pick]
			_stations[pick] = previous
	_seed = seed_value
	_cycle = cycle
	frequency = _stations[posmod(cycle, _stations.size())] / 10.0
	target = (frequency - 88) / 20
	tuning_time = 0
	displayed = target
	knob_angle = 0

func frequency_text() -> String:
	return "%.1f FM" % frequency

func _ready() -> void:
	custom_minimum_size.y = 94
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if value >= maxf(1, max_value):
		displayed = target
		knob_angle = 0
	elif running:
		tuning_time += delta
		var progress: float = clampf(value / maxf(1, max_value), 0, 1)
		var amplitude: float = .28 * (1 - progress)
		displayed = clampf(target + sin(tuning_time * 2.4 + sin(tuning_time * .7) * .6) * amplitude, 0, 1)
		knob_angle = (displayed - target) * 9
	queue_redraw()

func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var left: float = 88
	var width: float = maxf(1, size.x - 176)
	draw_style_box(RadioUI.surface("14272d", "49675c"), Rect2(Vector2.ZERO, size))
	for index: int in 41:
		var x: float = left + width * index / 40.0
		var major: bool = index % 10 == 0
		draw_line(Vector2(x, 44), Vector2(x, 64 if major else 56), Color("b7b995"), 2 if major else 1)
		if major: draw_string(font, Vector2(x - 13, 82), str(88 + index / 2), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("cbd0ad"))
	var target_x: float = left + target * width
	draw_line(Vector2(target_x, 34), Vector2(target_x, 69), Color("ffad50"), 4)
	draw_colored_polygon(PackedVector2Array([Vector2(target_x - 6, 30), Vector2(target_x + 6, 30), Vector2(target_x, 37)]), Color("ffad50"))
	var needle_x: float = left + displayed * width
	draw_line(Vector2(needle_x, 39), Vector2(needle_x, 65), Color("f1edd0"), 3)
	draw_circle(Vector2(needle_x, 67), 4, Color("f1edd0"))
	draw_string(font, Vector2(left - 4, 24), tr("M10_LOCKED" if value >= maxf(1, max_value) else "M10_TUNING"), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("9fe1c8"))
	draw_string(font, Vector2(left + width - 84, 24), frequency_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffb665"))
	_knob(Vector2(43, 51), knob_angle)
	_knob(Vector2(size.x - 43, 51), -knob_angle * .8)

func _knob(center: Vector2, angle: float) -> void:
	draw_circle(center + Vector2(0, 3), 34, Color("080f15"))
	draw_circle(center, 30, Color("bc9860"))
	draw_circle(center, 25, Color("131d25"))
	for index: int in 28:
		var direction: Vector2 = Vector2.from_angle(index * TAU / 28 + angle)
		draw_line(center + direction * 17, center + direction * 24, Color("36414a"), 1)
	draw_arc(center, 34, PI * 1.12, PI * 1.88, 20, Color("b8bd83"), 1)
	var pointer: Vector2 = Vector2.from_angle(-PI * .5 + angle)
	draw_line(center + pointer * 13, center + pointer * 24, Color("f1e6bc"), 4)
