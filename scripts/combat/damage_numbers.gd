class_name DamageNumbers
extends RefCounted
## Cosmetic hit snapshots, independent of actor lifetime, checkpoints and gameplay RNG.
const LIMIT: int = 48
const MERGE_WINDOW: float = .12
var entries: Array[Dictionary] = []
var serial: int = 0

func hit(event: CombatEvent, actor: CombatActor) -> void:
	if event.kind != CombatEvent.Kind.DAMAGE or event.amount <= 0 or not is_finite(event.amount) or actor.projectile: return
	# Rapid ticks on one target add up; normal hits never acquire a false critical style.
	for entry: Dictionary in entries:
		if entry.target == event.target_id and entry.critical == event.critical and entry.age < MERGE_WINDOW:
			entry.amount += event.amount
			return
	if entries.size() >= LIMIT: entries.pop_front()
	serial += 1
	entries.append({"target": event.target_id, "position": actor.position,
		"radius": actor.radius, "amount": event.amount, "critical": event.critical,
		"age": 0.0, "life": 1.05 if event.critical else .85, "lane": serial % 3 - 1})

func advance(delta: float) -> void:
	for entry: Dictionary in entries: entry.age += delta
	entries = entries.filter(func(entry: Dictionary) -> bool: return entry.age < entry.life)

func clear() -> void:
	entries.clear(); serial = 0

static func number(amount: float) -> String:
	# Do not turn positive fractional damage into a misleading zero.
	if amount < 1: return "%.1f" % maxf(.1, amount)
	return str(roundi(amount))

func draw(canvas: CombatArena) -> void:
	var font: Font = ThemeDB.fallback_font
	var calm: bool = RadioPreferences.current.enabled("low_effects") or RadioPreferences.current.enabled("reduced_flash")
	var large: float = 1.15 if RadioPreferences.current.enabled("large_text") else 1.0
	var scale: float = canvas.arena_scale()
	var offset: Vector2 = canvas.arena_offset()
	var bounds: Rect2 = Rect2(offset + Vector2(6, 46) * canvas.deck_stretch(), Vector2(628, 548) * canvas.deck_stretch())
	if bounds.size.x < 100 or bounds.size.y < 60: return
	canvas.draw_set_transform(Vector2.ZERO)
	for entry: Dictionary in entries:
		var age: float = entry.age
		var critical: bool = entry.critical
		var pop: float = 1.0 if calm else 1.0 + (.42 if critical else .16) * pow(maxf(0, 1 - age / .18), 2)
		var font_size: int = roundi(maxf(18, (40 if critical else 28) * scale) * large * pop)
		var label: String = number(entry.amount) + ("!" if critical else "")
		var extent: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var at: Vector2 = offset + Vector2(entry.position) * canvas.arena_stretch()
		at += Vector2(float(entry.lane) * 4, -float(entry.radius) * .25 - age * (8 if calm else 30)) * scale
		var rect: Rect2 = Rect2(at - Vector2(extent.x * .5, extent.y * .5), extent).grow(3)
		rect.position = rect.position.clamp(bounds.position, bounds.end - rect.size)
		var baseline: Vector2 = rect.position + Vector2(3, 3 + font.get_ascent(font_size))
		var fade: float = clampf((float(entry.life) - age) / .24, 0, 1)
		var tint: Color = Color("ffcf62" if critical else "f4eee0", fade)
		canvas.draw_string_outline(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5 if critical else 4, Color("101621", fade))
		canvas.draw_string(font, baseline, label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)
