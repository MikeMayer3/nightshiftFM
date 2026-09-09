class_name CampaignRun
extends RefCounted
## Snapshot of the options available when this run began; never shared with a profile.
var expanded: bool = false
var mode: String = "campaign"
var difficulty: int = 0
var contract: String = ""
var mission: int = 1
var cleared: int = 0
var modules: Array[StringName] = []

func to_data() -> Dictionary:
	var data: Dictionary = {"mission": mission, "cleared": cleared, "modules": Array(modules).duplicate()}
	if expanded: data.merge({"mode": mode, "difficulty": difficulty, "contract": contract})
	return data

func restore(value: Variant) -> bool:
	if not value is Dictionary or value.size() not in [3, 6]: return false
	if not SaveChecks.number(value.get("cleared"), 0, 12, true) or not SaveChecks.number(value.get("mission"), 1, 12, true): return false
	if value.mission > value.cleared + 1 or not CampaignContent.valid_modules(value.get("modules"), int(value.cleared)): return false
	expanded = value.size() == 6
	if expanded:
		if value.get("mode") not in BroadcastRules.MODES or not SaveChecks.number(value.get("difficulty"), 0, 2, true): return false
		if not value.get("contract") is String: return false
		mode = value.mode
		difficulty = int(value.difficulty)
		contract = value.contract
		if mode == "contract" and contract not in BroadcastRules.CONTRACTS: return false
		if mode != "contract" and contract != "": return false
		if difficulty > 0 and value.cleared < (4 if difficulty == 1 else 12): return false
		if mode == "contract" and value.cleared < 4 or mode == "endless" and value.cleared < 12: return false
	mission = int(value.mission)
	cleared = int(value.cleared)
	modules.assign(value.modules)
	return true
