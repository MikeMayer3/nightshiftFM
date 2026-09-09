class_name BroadcastProfile
extends RefCounted
## Mode records stay separate from campaign unlocks. No record changes combat power.
var best_scores: Dictionary = {}
var medals: Dictionary = {}
var enemies: Array[String] = []
const MEDAL_KEYS: Array[String] = ["clean_air", "fast_track", "interceptor", "steady_signal"]
static func medal_key(mission: int) -> String: return MEDAL_KEYS[(mission - 1) % 4]
static func score_key(context: CampaignRun) -> String:
	return context.mode + ":" + (context.contract if context.mode == "contract" else str(context.mission) if context.mode == "campaign" else "best") + ":" + str(context.difficulty)
func record(session: CombatSession) -> void:
	if not BroadcastRules.expanded(session): return
	var history: AchievementRun = session.achievement_run
	for id: String in history.seen + history.bosses:
		if id not in enemies: enemies.append(id)
	var key: String = score_key(session.campaign)
	if session.campaign.mode == "endless":
		best_scores[key] = maxi(int(best_scores.get(key, 0)), history.cleared_waves * 1000)
	elif session.phase == CombatSession.Phase.VICTORY:
		best_scores[key] = maxi(int(best_scores.get(key, 0)), 10000 + int(session.hull / session.maximum_hull() * 1000) + maxi(0, 1200 - int(session.elapsed)))
		if session.campaign.mode == "campaign":
			var medal: String = medal_key(session.campaign.mission)
			var earned: bool = session.breaches == 0 if medal == "clean_air" else session.elapsed <= 650 if medal == "fast_track" else session.intercepted >= 10 if medal == "interceptor" else history.hull_damage == 0
			if earned: medals[str(session.campaign.mission)] = medal
func to_data() -> Dictionary:
	return {"schema": 1, "best_scores": best_scores.duplicate(), "medals": medals.duplicate(), "enemies": enemies.duplicate()}
func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 4 or data.get("schema") != 1: return false
	if not data.get("best_scores") is Dictionary or data.best_scores.size() > 57 or not data.get("medals") is Dictionary or data.medals.size() > 12: return false
	var allowed: Array[String] = []
	for difficulty: int in 3:
		allowed.append("endless:best:" + str(difficulty))
		for mission: int in range(1, 13): allowed.append("campaign:" + str(mission) + ":" + str(difficulty))
		for contract: String in BroadcastRules.CONTRACTS: allowed.append("contract:" + contract + ":" + str(difficulty))
	for key: Variant in data.best_scores:
		if key not in allowed or not SaveChecks.number(data.best_scores[key], 0, 1000000, true): return false
	for key: Variant in data.medals:
		if not key is String or not key.is_valid_int() or int(key) < 1 or int(key) > 12 or data.medals[key] != medal_key(int(key)): return false
	if not SaveChecks.ids(data.get("enemies"), 12) or not SaveChecks.unique(data.enemies): return false
	for id: String in data.enemies:
		if BroadcastContent.enemy(StringName(id)) == null: return false
	best_scores = data.best_scores.duplicate()
	medals = data.medals.duplicate()
	enemies.assign(data.enemies)
	return true
