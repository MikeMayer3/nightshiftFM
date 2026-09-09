class_name AchievementRun
extends RefCounted
## Run-only history. It travels with the checkpoint, never directly into the profile.
var expanded: bool = false
var cleared_waves: int = 0
var seen: Array[String] = []
var wave_seen: Array[String] = []
var bosses: Array[String] = []
var wave_bosses: Array[String] = []
var reflected: int = 0
var wave_reflections: Array[int] = []
var activation_hits: Array[int] = []
var best_activation: int = 0
var eligible: bool = false
var hull_damage: float = 0.0
var max_supports: int = 0
var broken: bool = false
var recovered: bool = false
var completed: bool = false

static func production_build() -> bool:
	return not OS.has_feature("editor") and not OS.is_debug_build() and not OS.has_feature("qa")

func observe(session: CombatSession) -> void:
	max_supports = maxi(max_supports, session.draft.support_count())
	if broken and session.run.shield.current >= session.run.shield.capacity and session.run.shield.capacity > 0:
		recovered = true

func to_data() -> Dictionary:
	var data: Dictionary = {"eligible": eligible, "hull_damage": hull_damage, "max_supports": max_supports, "broken": broken, "recovered": recovered, "completed": completed}
	if expanded:
		data["broadcast"] = {"cleared_waves": cleared_waves, "seen": seen.duplicate(), "wave_seen": wave_seen.duplicate(), "bosses": bosses.duplicate(), "wave_bosses": wave_bosses.duplicate(), "reflected": reflected, "wave_reflections": wave_reflections.duplicate(), "activation_hits": activation_hits.duplicate(), "best_activation": best_activation}
	return data

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() not in [6, 7]: return false
	for key: String in ["eligible", "broken", "recovered", "completed"]:
		if not data.get(key) is bool: return false
	if not SaveChecks.number(data.get("hull_damage"), 0, 10000000) or not SaveChecks.number(data.get("max_supports"), 0 if data.size() == 7 else 1, 5, true): return false
	if data.recovered and not data.broken: return false
	expanded = data.size() == 7
	if expanded:
		var b: Variant = data.get("broadcast")
		if not b is Dictionary or b.size() != 9: return false
		for key: String in ["cleared_waves", "reflected", "best_activation"]:
			if not SaveChecks.number(b.get(key), 0, 100000, true): return false
		for key: String in ["seen", "wave_seen", "bosses", "wave_bosses"]:
			if not SaveChecks.ids(b.get(key), 16) or not SaveChecks.unique(b[key]): return false
			for id: String in b[key]:
				if BroadcastContent.enemy(StringName(id)) == null: return false
		for key: String in ["wave_reflections", "activation_hits"]:
			if not b.get(key) is Array or b[key].size() > 1000 or not SaveChecks.unique(b[key]): return false
			for id: Variant in b[key]:
				if not SaveChecks.number(id, 1, 10000000, true): return false
		cleared_waves = int(b.cleared_waves)
		reflected = int(b.reflected)
		best_activation = int(b.best_activation)
		seen.assign(b.seen)
		wave_seen.assign(b.wave_seen)
		bosses.assign(b.bosses)
		wave_bosses.assign(b.wave_bosses)
		wave_reflections.assign(b.wave_reflections)
		activation_hits.assign(b.activation_hits)
	eligible = data.eligible
	hull_damage = float(data.hull_damage)
	max_supports = int(data.max_supports)
	broken = data.broken
	recovered = data.recovered
	completed = data.completed
	return true

func encounter(actor: CombatActor) -> void:
	if not expanded or actor.projectile: return
	var family: String = String(actor.definition_id)
	if family.begins_with("m8.elite_"): family = "m2." + family.trim_prefix("m8.elite_")
	if actor.role >= EnemyDefinition.Role.CALLER: return
	if family not in wave_seen: wave_seen.append(family)

func complete_wave(session: CombatSession) -> void:
	if not expanded or session.wave <= cleared_waves: return
	cleared_waves = session.wave
	for id: String in wave_seen:
		if id not in seen: seen.append(id)
	for id: String in wave_bosses:
		if id not in bosses: bosses.append(id)
	reflected += wave_reflections.size()
	wave_seen.clear()
	wave_bosses.clear()
	wave_reflections.clear()
