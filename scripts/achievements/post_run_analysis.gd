class_name PostRunAnalysis
extends RefCounted
## Recipe damage has its own source; assistance and Burst subtotals are not additive.
static func effective_damage(session: CombatSession) -> float:
	var amount: float = 0.0
	if session.supports != null:
		for row: Dictionary in session.supports.report.totals.values(): amount += float(row.damage)
	if session.patchboard != null:
		for row: Dictionary in session.patchboard.totals.values(): amount += float(row.damage)
	return amount

## Explain recorded health loss, never infer a cause from the final attacker.
static func loss_key(session: CombatSession) -> StringName:
	if session.phase != CombatSession.Phase.DEFEAT: return &"P2_SURVIVED"
	var history: AchievementRun = session.achievement_run
	if history == null or not history.expanded or not history.loss_history.complete: return &"P2_LOSS_UNKNOWN"
	var loss: Dictionary = history.loss_history
	var total: float = float(loss.breach) + float(loss.projectile) + float(loss.other)
	if total <= 0 or not is_equal_approx(total, history.hull_damage): return &"P2_LOSS_UNKNOWN"
	if float(loss.breach) > total * .5: return &"P2_LOSS_BREACH"
	if float(loss.projectile) > total * .5: return &"P2_LOSS_PROJECTILE"
	return &"P2_LOSS_MIXED"
