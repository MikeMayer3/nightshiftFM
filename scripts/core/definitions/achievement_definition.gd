class_name AchievementDefinition
extends ContentDefinition
## Immutable local goal contract. Pending content is visible but never awards progress.
@export var category: String = ""
@export var progress_kind: StringName = &"flag"
@export var threshold: int = 1
@export var condition_id: StringName = &""
@export var condition_parameters: Dictionary = {}
@export var eligible_modes: Array[StringName] = [&"campaign"]
@export var minimum_difficulty: int = 0
@export var reward_id: StringName = &""
@export var available: bool = false
@export var pending_key: StringName = &""
@export var ios_achievement_id: String = ""
@export var android_achievement_id: String = ""

func validate() -> PackedStringArray:
	var errors: PackedStringArray = super.validate()
	if category.is_empty() or condition_id != id: errors.append("achievement category and stable condition required")
	if progress_kind not in [&"flag", &"counter", &"set"] or threshold < 1 or threshold > 100000: errors.append("invalid progress contract")
	if minimum_difficulty not in [0, 1, 2] or eligible_modes.is_empty() or not SaveChecks.unique(eligible_modes): errors.append("invalid eligibility")
	for mode: StringName in eligible_modes:
		if mode not in [&"campaign", &"contract", &"endless"]: errors.append("unknown mode")
	if reward_id != StringName("cosmetic.achievement." + String(id)): errors.append("stable cosmetic-only reward required")
	if not available and pending_key.is_empty(): errors.append("pending goal requires an explanation")
	if category == "Weapon mastery":
		if condition_parameters.size() != 1 or String(condition_parameters.get(&"family", "")) not in ArsenalContent.FAMILIES: errors.append("unknown mastery family")
	elif not condition_parameters.is_empty(): errors.append("unsupported condition parameters")
	return errors
