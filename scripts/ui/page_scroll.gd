class_name PageScroll
extends Node
## Own vertical drags across a page, including its cards and outer margins.
## Listen at the actual GUI hit target; hidden pages and covered modals cannot
## steal a press. Native controls still receive taps, wheel and keyboard input.
const DEADZONE: float = 10.0
const FRICTION: float = 2400.0
var surface: Control
var scroll: ScrollContainer
var pointer: int = -2 # -2 idle, -1 mouse, >= 0 native touch index.
var control_touch: int = -1
var origin: Vector2
var previous: Vector2
var dragging: bool = false
var velocity: float = 0.0
var offset: float = 0.0
var last_motion: int = 0
var backdrop: Control

static func attach(page: Control, container: ScrollContainer, fill_viewport: bool = false) -> PageScroll:
	var gesture: PageScroll = PageScroll.new()
	gesture.surface = page
	gesture.scroll = container
	if fill_viewport:
		# Small modal sheets also accept a swipe on the surrounding app area.
		# Insert as a sibling behind the sheet so its controls win GUI hit tests.
		gesture.backdrop = Control.new()
		gesture.backdrop.name = "ScrollBackdrop"
	page.add_child(gesture)
	return gesture

func _ready() -> void:
	_wire(surface)
	get_tree().node_added.connect(_node_added)
	surface.visibility_changed.connect(_visibility_changed)
	scroll.resized.connect(_cancel)
	if backdrop != null:
		_add_backdrop.call_deferred()

func _add_backdrop() -> void:
	if not is_inside_tree(): return
	var parent: Node = surface.get_parent()
	parent.add_child(backdrop)
	parent.move_child(backdrop, surface.get_index())
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.gui_input.connect(_press.bind(backdrop))
	_visibility_changed()

func _visibility_changed() -> void:
	_cancel()
	if is_instance_valid(backdrop): backdrop.visible = surface.is_visible_in_tree()

func _exit_tree() -> void:
	if is_instance_valid(backdrop): backdrop.queue_free()

func _node_added(node: Node) -> void:
	if surface.is_ancestor_of(node): _wire.call_deferred(node)

func _wire(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	if node is Window: return # Popup menus own their separate input surface.
	if node is Control:
		var callback: Callable = _press.bind(node)
		if not node.gui_input.is_connected(callback): node.gui_input.connect(callback)
		# A drag must be distinguishable from a tap before an action opens a page.
		if node is BaseButton: node.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	for child: Node in node.get_children(): _wire(child)

func _press(event: InputEvent, target: Control) -> void:
	if pointer != -2 or control_touch != -1 or not surface.is_visible_in_tree(): return
	if scroll.get_v_scroll_bar().max_value <= scroll.get_v_scroll_bar().page: return
	var owner: Node = surface if target == backdrop else target
	while owner != surface:
		if owner is Slider or owner is ScrollBar:
			if event is InputEventScreenTouch and event.pressed: control_touch = event.index
			velocity = 0.0
			_end_scroll()
			return
		owner = owner.get_parent()
		if owner == null: return
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		pointer = event.index
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		pointer = -1
	else: return
	_end_scroll()
	origin = target.get_global_transform() * event.position
	previous = origin
	velocity = 0.0
	last_motion = Time.get_ticks_msec()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == control_touch and (not event.pressed or event.canceled):
		control_touch = -1
	if pointer == -2: return
	if not surface.is_visible_in_tree():
		_cancel()
		return
	if event is InputEventScreenTouch:
		if event.index != pointer:
			get_viewport().set_input_as_handled()
		elif not event.pressed or event.canceled:
			if event.canceled: _cancel()
			else: _release()
	elif event is InputEventScreenDrag:
		if event.index == pointer: _move(event.position)
		if dragging or event.index != pointer: get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		if pointer == -1: _move(event.position)
		# Touch-to-mouse emulation must not move the page a second time.
		if dragging: get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if pointer == -1 and not event.pressed:
			if event.canceled: _cancel()
			else: _release()

func _move(viewport_point: Vector2) -> void:
	var point: Vector2 = surface.get_canvas_transform().affine_inverse() * viewport_point
	if not dragging:
		if absf(point.y - origin.y) <= DEADZONE: return
		dragging = true
		# The same notification used by Godot's ScrollContainer cancels a button
		# press without changing toggle state or emitting its action.
		surface.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
		scroll.scroll_started.emit()
		offset = scroll.scroll_vertical
	var now: int = Time.get_ticks_msec()
	var distance: float = previous.y - point.y
	velocity = clampf(distance / maxf((now - last_motion) / 1000.0, 0.008), -2200, 2200)
	_apply_offset(offset + distance)
	previous = point
	last_motion = now

func _apply_offset(value: float) -> void:
	var bar: VScrollBar = scroll.get_v_scroll_bar()
	offset = clampf(value, 0, maxf(0, bar.max_value - bar.page))
	scroll.scroll_vertical = roundi(offset)
	if not is_equal_approx(offset, value): velocity = 0.0

func _release() -> void:
	pointer = -2
	if Time.get_ticks_msec() - last_motion > 100: velocity = 0.0
	if not dragging: velocity = 0.0
	if is_zero_approx(velocity): _end_scroll()

func _process(delta: float) -> void:
	if not surface.is_visible_in_tree():
		_cancel()
		return
	if pointer != -2 or not dragging: return
	_apply_offset(offset + velocity * minf(delta, 0.05))
	velocity = move_toward(velocity, 0, FRICTION * delta)
	if is_zero_approx(velocity): _end_scroll()

func _end_scroll() -> void:
	if dragging:
		dragging = false
		surface.propagate_notification(Control.NOTIFICATION_SCROLL_END)
		scroll.scroll_ended.emit()

func _cancel() -> void:
	if pointer != -2: surface.propagate_notification(Control.NOTIFICATION_SCROLL_BEGIN)
	pointer = -2
	control_touch = -1
	velocity = 0.0
	_end_scroll()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_WINDOW_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if is_instance_valid(surface): _cancel()
