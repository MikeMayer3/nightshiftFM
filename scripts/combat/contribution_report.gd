class_name ContributionReport
extends RefCounted
## Effective output only. Exposure bonus is assistance, never added to damage totals.
const SOURCES: Array[StringName] = [&"main", &"shield", &"arc_aerial", &"bass_driver", &"static_net"]
const METRICS: Array[StringName] = [&"damage", &"slow_seconds", &"push_distance", &"intercepts", &"healing", &"exposure_bonus", &"interrupts", &"absorbed", &"breaks"]
var source_ids: Array[StringName] = SOURCES.duplicate()
var totals: Dictionary = {}

func _init(ids: Array[StringName] = SOURCES) -> void:
	source_ids = ids.duplicate()
	for source: StringName in source_ids:
		totals[String(source)] = {}
		for metric: StringName in METRICS: totals[String(source)][String(metric)] = 0.0

func add(source: StringName, metric: StringName, amount: float) -> void:
	if source in source_ids and metric in METRICS and is_finite(amount) and amount > 0:
		totals[String(source)][String(metric)] += amount

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != source_ids.size(): return false
	for source: StringName in source_ids:
		var row: Variant = data.get(String(source))
		if not row is Dictionary or row.size() != METRICS.size(): return false
		for metric: StringName in METRICS:
			if not SaveChecks.number(row.get(String(metric)), 0, 100000000): return false
	totals = data.duplicate(true)
	return true
