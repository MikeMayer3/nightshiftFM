class_name CampaignRun
extends RefCounted
## Snapshot of the options available when this run began; never shared with a profile.
var mission: int = 1
var cleared: int = 0
var modules: Array[StringName] = []

func to_data() -> Dictionary:
	return {"mission": mission, "cleared": cleared, "modules": Array(modules).duplicate()}

func restore(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 3: return false
	if not SaveChecks.number(value.get("cleared"), 0, 12, true) or not SaveChecks.number(value.get("mission"), 1, 12, true): return false
	if value.mission > value.cleared + 1 or not CampaignContent.valid_modules(value.get("modules"), int(value.cleared)): return false
	mission = int(value.mission)
	cleared = int(value.cleared)
	modules.assign(value.modules)
	return true
