class_name MissionProfile
extends RefCounted
## M3 reward is a local completion record only. No permanent combat power.
var campaign: CampaignProfile = CampaignProfile.new()
var unlocked: Array[StringName] = [&"main", &"shield", &"arc_aerial"]
var next_run: int = 1
var rewarded_runs: Array[StringName] = []
var completed: int = 0
var discovered: Array[StringName] = []

func enable_m4() -> void:
	for id: StringName in [&"bass_driver", &"static_net"]:
		if id not in unlocked: unlocked.append(id)

func commit_reward(run_id: StringName, session: CombatSession = null) -> void:
	if run_id in rewarded_runs: return
	rewarded_runs.append(run_id)
	completed += 1
	if session != null: campaign.record_victory(session)

func to_data() -> Dictionary:
	return {"schema": 3, "campaign": campaign.to_data(), "discovered": Array(discovered), "unlocked": Array(unlocked), "next_run": next_run,
		"rewarded_runs": Array(rewarded_runs), "completed": completed}

func restore(data: Variant) -> bool:
	if not data is Dictionary or not SaveChecks.number(data.get("schema"), 1, 3, true): return false
	if data.size() != (7 if data.schema == 3 else 6 if data.schema == 2 else 5): return false
	if data.schema >= 2:
		if not SaveChecks.ids(data.get("discovered"), 8) or not SaveChecks.unique(data.discovered): return false
		for id: String in data.discovered:
			if not PatchboardContent.RECIPES.has(StringName(id)): return false
	if not SaveChecks.ids(data.get("unlocked"), 5) or not SaveChecks.ids(data.get("rewarded_runs"), 100000): return false
	if not SaveChecks.number(data.get("next_run"), 1, 100000, true) or not SaveChecks.number(data.get("completed"), 0, 100000, true): return false
	if data.completed != data.rewarded_runs.size() or not SaveChecks.unique(data.rewarded_runs): return false
	if data.unlocked.size() not in [3, 5]: return false
	for index: int in data.unlocked.size():
		if String(data.unlocked[index]) != ["main", "shield", "arc_aerial", "bass_driver", "static_net"][index]: return false
	for id: String in data.rewarded_runs:
		if not id.begins_with("run.") or not id.trim_prefix("run.").is_valid_int(): return false
		if int(id.trim_prefix("run.")) < 1 or int(id.trim_prefix("run.")) >= int(data.next_run): return false
	var progression: CampaignProfile = CampaignProfile.new()
	if data.schema == 3 and not progression.restore(data.get("campaign")): return false
	campaign = progression
	discovered.assign(data.get("discovered", []))
	unlocked.assign(data.unlocked)
	rewarded_runs.assign(data.rewarded_runs)
	next_run = int(data.next_run)
	completed = int(data.completed)
	return true
