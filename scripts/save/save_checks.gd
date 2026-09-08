class_name SaveChecks
extends RefCounted
static func number(value: Variant, low: float, high: float, integer: bool = false) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= low and float(value) <= high and (not integer or float(value) == floor(float(value)))

static func ids(value: Variant, limit: int = 100) -> bool:
	if not value is Array or value.size() > limit: return false
	for entry: Variant in value:
		if not (entry is String or entry is StringName) or entry.length() > 100: return false
	return true

static func unique(values: Array) -> bool:
	var seen: Dictionary = {}
	for value: Variant in values:
		if seen.has(value): return false
		seen[value] = true
	return true
