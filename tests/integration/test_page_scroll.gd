extends RefCounted
var tree: SceneTree
var t: TestContext
var taps: int = 0
func settle() -> void:
	for frame: int in 4: await tree.process_frame
func mouse(point: Vector2, pressed: bool) -> void:
	var e: InputEventMouseButton = InputEventMouseButton.new()
	e.position = point; e.global_position = point; e.button_index = MOUSE_BUTTON_LEFT; e.pressed = pressed
	tree.root.push_input(e, true)
func motion(point: Vector2, relative: Vector2) -> void:
	var e: InputEventMouseMotion = InputEventMouseMotion.new()
	e.position = point; e.global_position = point; e.relative = relative; e.button_mask = MOUSE_BUTTON_MASK_LEFT
	tree.root.push_input(e, true)
func touch(point: Vector2, pressed: bool, index: int = 3, canceled: bool = false) -> void:
	var e: InputEventScreenTouch = InputEventScreenTouch.new()
	e.position = point; e.pressed = pressed; e.index = index; e.canceled = canceled
	tree.root.push_input(e, true)
func drag(point: Vector2, index: int = 3) -> void:
	var e: InputEventScreenDrag = InputEventScreenDrag.new()
	e.position = point; e.index = index; e.relative = Vector2(0, -80)
	tree.root.push_input(e, true)
func run(context: TestContext, scene_tree: SceneTree) -> bool:
	t = context; tree = scene_tree
	var page: PanelContainer = PanelContainer.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tree.root.add_child(page)
	var margin: MarginContainer = MarginContainer.new(); page.add_child(margin)
	for side: String in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 40)
	var scroll: ScrollContainer = ScrollContainer.new(); margin.add_child(scroll)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column: VBoxContainer = VBoxContainer.new(); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(column)
	var card: PanelContainer = PanelContainer.new(); card.custom_minimum_size.y = 300; column.add_child(card)
	var body: VBoxContainer = VBoxContainer.new(); card.add_child(body)
	var label: Label = Label.new(); label.text = "Drag text"; label.custom_minimum_size.y = 90; body.add_child(label)
	var art: TextureRect = RadioUI.art(body, DraftPanel.ICONS.main, 90)
	var meter: ProgressBar = ProgressBar.new(); meter.custom_minimum_size.y = 50; body.add_child(meter)
	var button: Button = Button.new(); button.text = "Tap or drag"; button.custom_minimum_size.y = 80; column.add_child(button)
	button.pressed.connect(func() -> void: taps += 1)
	var option: OptionButton = OptionButton.new(); option.add_item("First"); option.add_item("Second"); option.custom_minimum_size.y = 60; column.add_child(option)
	var fader: VSlider = VSlider.new(); fader.custom_minimum_size = Vector2(100, 160); column.add_child(fader)
	var filler: Control = Control.new(); filler.custom_minimum_size.y = 1800; column.add_child(filler)
	var gesture: PageScroll = PageScroll.attach(page, scroll, true)
	await settle()
	for kind: String in ["mouse", "touch"]:
		for target: Control in [label, art, meter, card, button, option]:
			gesture._cancel(); scroll.scroll_vertical = 0; await settle()
			var p: Vector2 = target.get_global_rect().get_center()
			if target == card: p = card.global_position + Vector2(2, 240)
			if kind == "mouse": mouse(p, true); motion(p - Vector2(0, 100), Vector2(0, -100)); mouse(p - Vector2(0, 100), false)
			else: touch(p, true); drag(p - Vector2(0, 100)); touch(p - Vector2(0, 100), false)
			t.check(scroll.scroll_vertical >= 90, "%s drag starts on %s" % [kind, target.get_class()])
			t.check(taps == 0 and not option.get_popup().visible, "scroll release never activates buttons or selector")
		gesture._cancel(); scroll.scroll_vertical = 0; await settle()
		var edge: Vector2 = Vector2(12, 320)
		if kind == "mouse": mouse(edge, true); motion(edge - Vector2(0, 120), Vector2(0, -120)); mouse(edge - Vector2(0, 120), false)
		else: touch(edge, true); drag(edge - Vector2(0, 120)); touch(edge - Vector2(0, 120), false)
		t.check(scroll.scroll_vertical >= 110, kind + " drag starts in outer page margin")
	gesture._cancel(); scroll.scroll_vertical = 0; await settle()
	var p: Vector2 = button.get_global_rect().get_center()
	mouse(p, true); mouse(p, false)
	t.check(taps == 1, "normal mouse tap fires once")
	touch(p, true); touch(p, false)
	t.check(taps == 2, "normal native touch tap fires once")
	mouse(p, true); motion(p - Vector2(0, 4), Vector2(0, -4)); mouse(p - Vector2(0, 4), false)
	t.check(taps == 3 and scroll.scroll_vertical == 0, "small tap movement stays a click")
	button.disabled = true
	mouse(p, true); motion(p - Vector2(0, 80), Vector2(0, -80)); mouse(p - Vector2(0, 80), false)
	t.check(scroll.scroll_vertical >= 70 and taps == 3, "disabled button still permits scrolling")
	button.disabled = false; gesture._cancel(); scroll.scroll_vertical = 0; await settle()
	p = option.get_global_rect().get_center()
	mouse(p, true); mouse(p, false); await settle()
	t.check(option.get_popup().visible, "selector still opens on an ordinary tap")
	option.get_popup().hide()
	p = fader.get_global_rect().get_center()
	var value: float = fader.value
	mouse(p, true); motion(p - Vector2(0, 45), Vector2(0, -45)); mouse(p - Vector2(0, 45), false)
	t.check(fader.value != value and scroll.scroll_vertical == 0, "vertical fader keeps its gesture and does not scroll")
	touch(p, true); drag(p - Vector2(0, 45)); touch(p - Vector2(0, 45), false)
	t.check(scroll.scroll_vertical == 0 and gesture.pointer == -2, "native touch on fader never starts page scroll")
	p = button.get_global_rect().get_center()
	touch(p,true); drag(Vector2(-20,p.y)); touch(Vector2(-20,p.y),false)
	t.check(taps == 3, "horizontal touch leaving a button does not activate it")
	p = Vector2(12, 320)
	touch(p, true); drag(p - Vector2(0, 80))
	var before: int = scroll.scroll_vertical
	touch(p, true, 4); drag(p - Vector2(0, 180), 4); touch(p, false, 4)
	t.check(scroll.scroll_vertical == before and gesture.pointer == 3, "second finger cannot steal scroll ownership")
	var emulated: InputEventMouseMotion = InputEventMouseMotion.new(); emulated.device = InputEvent.DEVICE_ID_EMULATION; emulated.position = p - Vector2(0, 80); emulated.relative = Vector2(0, -80)
	tree.root.push_input(emulated, true)
	t.check(scroll.scroll_vertical == before, "emulated mouse does not double native scrolling")
	touch(p, false, 3, true)
	t.check(gesture.pointer == -2 and not gesture.dragging, "Android cancellation clears gesture and momentum")
	gesture._cancel(); scroll.scroll_vertical = 0; await settle()
	mouse(p, true); motion(p - Vector2(0, 80), Vector2(0, -80)); page.hide(); mouse(p, false)
	t.check(gesture.pointer == -2 and not gesture.dragging, "hiding a page cancels active scroll")
	page.show(); await settle()
	var overlay: PanelContainer = PanelContainer.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tree.root.add_child(overlay)
	before = scroll.scroll_vertical
	mouse(p, true); motion(p - Vector2(0, 80), Vector2(0, -80)); mouse(p, false)
	t.check(scroll.scroll_vertical == before and gesture.pointer == -2, "covering modal prevents underlying page scroll")
	overlay.queue_free(); await settle()
	page.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT); page.position = Vector2(60,200); page.size = Vector2(600,600)
	await settle(); scroll.scroll_vertical = 0
	p = Vector2(20,160)
	mouse(p,true); motion(p-Vector2(0,80),Vector2(0,-80)); mouse(p-Vector2(0,80),false)
	t.check(scroll.scroll_vertical >= 70, "blank app area outside centered sheet scrolls its content")
	page.queue_free(); await settle()
	return true
