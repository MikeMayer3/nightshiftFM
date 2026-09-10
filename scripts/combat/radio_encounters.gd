class_name RadioEncounters
extends RefCounted
## Presentation reads combat clocks; it never rolls gameplay RNG or changes actors.
static func environment(canvas: CombatArena, era: int, low: bool) -> void:
	var shade: Color = RadioArt.TRIMS[era].darkened(.68)
	if low: return
	# Architecture stays at the edges, leaving the targeting corridor clear.
	for side: int in [0, 1]:
		var x: float = 8 if side == 0 else 572
		for floor_index: int in 4:
			var y: float = 90 + floor_index * 122
			if era == 0:
				canvas.draw_rect(Rect2(x, y, 60, 110), shade)
				for window: int in 3: canvas.draw_rect(Rect2(x + 10 + window * 17, y + 20, 7, 14), Color("554735"))
			elif era == 1:
				canvas.draw_rect(Rect2(x, y, 60, 110), shade, false, 2)
				for slat: int in 5: canvas.draw_line(Vector2(x + 6, y + 15 + slat * 18), Vector2(x + 54, y + 15 + slat * 18), shade, 3)
			else:
				canvas.draw_line(Vector2(x + 10, y), Vector2(x + 10, y + 70), shade, 3)
				canvas.draw_line(Vector2(x + 10, y + 70), Vector2(x + 49, y + 96), shade, 3)
				canvas.draw_circle(Vector2(x + 49, y + 96), 5, shade, false, 2)

static func actor(canvas: CombatArena, value: CombatActor) -> void:
	if value.projectile or value.role == EnemyDefinition.Role.BASIC: return
	var p: Vector2 = value.position
	var radius: float = value.radius + 12
	var s: CombatSession = canvas.session
	var amber: Color = Color("f4b985")
	var mint: Color = Color("9fe8da")
	var label_key: String = ""
	var guard: bool = EncounterDirector.protection(s, value) < 1
	if value.role in [EnemyDefinition.Role.CORE, EnemyDefinition.Role.SILENCE, EnemyDefinition.Role.MIMIC]:
		label_key = "BROADCAST_GUARDED" if guard else "BROADCAST_OPEN"
		# A compact shield badge changes to a broken shield while vulnerable.
		var badge: Vector2 = p + Vector2(-7, -radius - 9)
		var shield: PackedVector2Array = PackedVector2Array([badge, badge + Vector2(14, 0), badge + Vector2(12, 8), badge + Vector2(7, 12), badge + Vector2(2, 8), badge])
		canvas.draw_polyline(shield, amber if guard else mint, 2, true)
		if not guard: canvas.draw_line(badge + Vector2(3, -2), badge + Vector2(11, 13), Color("14272d"), 4)
	if value.role == EnemyDefinition.Role.AERIAL:
		canvas.draw_polyline(PackedVector2Array([p + Vector2(-6, -radius - 3), p + Vector2(0, -radius + 3), p + Vector2(6, -radius - 3)]), mint, 3)
	if EncounterDirector.channel(value):
		var fraction: float = clampf((value.ability_time - value.ability_interval + 1.25) / 1.25, 0, 1)
		canvas.draw_rect(Rect2(p + Vector2(-21, radius + 5), Vector2(42, 4)), Color("35434e"))
		canvas.draw_rect(Rect2(p + Vector2(-21, radius + 5), Vector2(42 * fraction, 4)), amber)
		if value.role in [EnemyDefinition.Role.CASTER, EnemyDefinition.Role.JAMMER]:
			label_key = "BROADCAST_CHANNEL"
			if value.role == EnemyDefinition.Role.CASTER:
				# Short directional links show which neighbors are actually protected.
				var links: int = 0
				for neighbor: CombatActor in s.actors:
					if neighbor == value or neighbor.projectile or neighbor.resolved or p.distance_to(neighbor.position) >= 150: continue
					var toward: Vector2 = p.direction_to(neighbor.position)
					canvas.draw_line(p + toward * radius, p + toward * (radius + 14), Color(mint, .7), 2)
					links += 1
					if links == 3: break
		else:
			label_key = "BROADCAST_VOLLEY"
			for lane: int in ([-1, 0, 1] if EncounterDirector.boss(value) else [0]):
				var x: float = p.x + lane * 36
				canvas.draw_polyline(PackedVector2Array([Vector2(x - 6, p.y + radius + 12), Vector2(x, p.y + radius + 22), Vector2(x + 6, p.y + radius + 12)]), amber, 3)
	if label_key != "":
		canvas.draw_string(ThemeDB.fallback_font, p + Vector2(-45, -radius - 17), canvas.tr(label_key), HORIZONTAL_ALIGNMENT_CENTER, 90, 14, amber if guard else mint)
	if EncounterDirector.boss(value):
		canvas.draw_rect(Rect2(p + Vector2(-48, radius + 12), Vector2(96, 6)), Color("35434e"))
		canvas.draw_rect(Rect2(p + Vector2(-48, radius + 12), Vector2(96 * value.health / value.max_health, 6)), amber)

static func hardware(canvas: CombatArena, track: UpgradeTrack, tint: Color, main: bool = false) -> void:
	if track == null: return
	var rank: int = track.rank()
	# Three visibly fitted hardware tiers, independent of rank-number/color recognition.
	for tier: int in [3, 6, 8]:
		if rank < tier: continue
		var x: float = -23 + ([3, 6, 8].find(tier) * 23)
		canvas.draw_rect(Rect2(x - 6, 15 if main else 8, 12, 8), tint.darkened(.3))
		canvas.draw_line(Vector2(x, 15 if main else 8), Vector2(x, -5 if main else -9), tint, 2)
	if rank >= 6:
		canvas.draw_arc(Vector2.ZERO, 31 if not main else 43, PI * 1.1, PI * 1.9, 20, Color(tint, .65), 2)
