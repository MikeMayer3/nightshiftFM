class_name SignalProgress
extends RefCounted
## Only enemy kills count. Overflow remains available for the next choice.
var active_rules: bool = false
var earned: int = 0
var spent: int = 0
var choices: int = 0
var overdrive_left: float = 0.0

func threshold() -> int:
	return cost(choices)

func cost(index: int) -> int:
	return mini(21, 6 + index * 3) if active_rules else mini(13, 5 + index * 2)

func progress() -> int:
	return earned - spent

func ready() -> bool:
	return progress() >= threshold()

func consume() -> bool:
	if not ready(): return false
	spent += threshold()
	choices += 1
	return true

func to_data() -> Dictionary:
	return {"earned": earned, "spent": spent, "choices": choices, "overdrive_left": overdrive_left}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 4: return false
	for key: String in ["earned", "spent", "choices"]:
		if not SaveChecks.number(data.get(key), 0, 10000, true): return false
	if not SaveChecks.number(data.get("overdrive_left"), 0, 20): return false
	var total: int = 0
	for index: int in int(data.choices): total += cost(index)
	if data.spent != total or data.earned < total: return false
	earned = int(data.earned)
	spent = int(data.spent)
	choices = int(data.choices)
	overdrive_left = float(data.overdrive_left)
	return true
