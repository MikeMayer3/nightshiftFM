class_name CombatCoach
extends PanelContainer
## Presentation-only coaching. Appearing once is remembered independently of runs.
var current_hint: String = ""
var caption: Label
var icon: TextureRect
var dismiss: Button
var preferences: RadioPreferences

func _ready() -> void:
	preferences = RadioPreferences.current
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", RadioUI.surface("162d38", "6aa79b"))
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(42,42)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.add_theme_font_size_override("font_size", 22)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(caption)
	dismiss = Button.new()
	dismiss.text = "×"
	dismiss.tooltip_text = tr("P3_DISMISS")
	dismiss.custom_minimum_size = Vector2(64,64)
	dismiss.set_meta("radio_touch_minimum",64)
	RadioUI.button(dismiss)
	row.add_child(dismiss)
	dismiss.pressed.connect(func() -> void: current_hint = ""; hide())
	preferences.changed.connect(func() -> void:
		if preferences.coach_seen.is_empty(): current_hint = ""; hide())
	hide()

static func relevant(s: CombatSession, id: String) -> bool:
	if not RadioBalance.enabled(s) or s.paused or s.is_finished() or s.is_deciding() or s.is_wiring(): return false
	match id:
		"shield":
			if s.ability_wait > 0: return false
			for actor: CombatActor in s.actors:
				if RadioBalance.entered(s,actor) and actor.position.y > 360: return true
		"boost": return RadioShieldVisual.reserve(s) > 0
		"mixer": return s.patchboard != null and s.patchboard.mixer != null and s.draft.normal_count > 0
	return false

func refresh(s: CombatSession) -> void:
	if not current_hint.is_empty() and not relevant(s,current_hint): current_hint = ""
	if current_hint.is_empty():
		for id: String in ["boost", "shield", "mixer"]:
			if id not in preferences.coach_seen and relevant(s,id):
				current_hint = id
				preferences.remember_coach(id)
				break
	visible = not current_hint.is_empty()
	if not visible: return
	var key: String = "P3_" + current_hint.to_upper()
	if current_hint == "shield": key += "_" + String((s.draft as ArsenalDraft).loadout.shield).to_upper()
	caption.text = tr(key)
	icon.texture = preload("res://assets/art/equipment/shield.svg") if current_hint != "mixer" else preload("res://assets/art/radio/mixer_fader.svg")
	icon.modulate = Color("cfb4ff") if current_hint == "boost" else Color.WHITE
