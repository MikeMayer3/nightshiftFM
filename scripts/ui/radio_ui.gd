class_name RadioUI
extends RefCounted
## Shared radio-console surfaces for the setup flow.
static func surface(color: String = "142735", accent: String = "314956") -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(color)
	box.border_color = Color(accent)
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	return box

static func skin(control: Control) -> void:
	control.add_theme_stylebox_override("panel", surface("0c1822", "0c1822"))

static func button(node: Button, primary: bool = false) -> void:
	node.add_theme_stylebox_override("normal", surface("234d4b" if primary else "142735", "78cfbc" if primary else "314956"))
	node.add_theme_stylebox_override("hover", surface("294b55", "78cfbc"))
	node.add_theme_stylebox_override("pressed", surface("305d58", "b5efdc"))
	node.add_theme_stylebox_override("hover_pressed", surface("305d58", "b5efdc"))
	node.add_theme_stylebox_override("disabled", surface("101e29", "23343e"))
	node.add_theme_stylebox_override("focus", surface("234d4b", "e8bb7a"))
	node.add_theme_color_override("font_color", Color("e5eee8"))
	node.mouse_filter = Control.MOUSE_FILTER_PASS

static func fold(parent: Node, title: String) -> VBoxContainer:
	var toggle: Button = Button.new()
	toggle.text = "+  " + title
	toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	toggle.toggle_mode = true
	toggle.add_theme_font_size_override("font_size", 25)
	button(toggle)
	parent.add_child(toggle)
	var body: VBoxContainer = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	parent.add_child(body)
	body.visible = false
	toggle.toggled.connect(func(open: bool) -> void:
		body.visible = open
		toggle.text = ("−  " if open else "+  ") + title)
	return body

static func art(parent: Node, texture: Texture2D, extent: float = 110) -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(extent, extent)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
