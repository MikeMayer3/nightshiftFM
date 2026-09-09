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
