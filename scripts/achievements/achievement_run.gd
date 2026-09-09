class_name AchievementRun
extends RefCounted
## Run-only history. It travels with the checkpoint, never directly into the profile.
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
	return {"eligible": eligible, "hull_damage": hull_damage, "max_supports": max_supports, "broken": broken, "recovered": recovered, "completed": completed}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 6: return false
	for key: String in ["eligible", "broken", "recovered", "completed"]:
		if not data.get(key) is bool: return false
	if not SaveChecks.number(data.get("hull_damage"), 0, 10000000) or not SaveChecks.number(data.get("max_supports"), 1, 5, true): return false
	if data.recovered and not data.broken: return false
	eligible = data.eligible
	hull_damage = float(data.hull_damage)
	max_supports = int(data.max_supports)
	broken = data.broken
	recovered = data.recovered
	completed = data.completed
	return true
