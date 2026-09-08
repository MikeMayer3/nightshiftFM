class_name StatusState
extends RefCounted
## Wave-local statuses. Strongest wins; reapplications refresh, never add durations.
const SLOW_CAP: float = 0.6
const ELITE_SLOW_CAP: float = 0.25
var charged: int = 0
var charge_left: float = 0.0
var slow_source: StringName = &"static_net"
var slow: float = 0.0
var slow_left: float = 0.0
var exposure: float = 0.0
var exposure_left: float = 0.0
var jam_left: float = 0.0
var jam_cooldown: float = 0.0
var fallback_left: float = 0.0

func advance(delta: float) -> void:
	charge_left = maxf(0, charge_left - delta)
	slow_left = maxf(0, slow_left - delta)
	exposure_left = maxf(0, exposure_left - delta)
	jam_left = maxf(0, jam_left - delta)
	jam_cooldown = maxf(0, jam_cooldown - delta)
	fallback_left = maxf(0, fallback_left - delta)
	if charge_left == 0: charged = 0
	if slow_left == 0: slow = 0
	if exposure_left == 0: exposure = 0

func charge() -> void:
	charged = mini(3, charged + 1)
	charge_left = 3.0

func apply_slow(strength: float, elite: bool, source: StringName = &"static_net") -> void:
	if strength >= slow: slow_source = source
	slow = maxf(slow, clampf(strength, 0, ELITE_SLOW_CAP if elite else SLOW_CAP))
	slow_left = 0.6

func expose(amount: float) -> void:
	exposure = maxf(exposure, clampf(amount, 0, 100))
	exposure_left = 3.0

func jam(duration: float, elite: bool, immune: bool) -> bool:
	fallback_left = 0.6
	if immune or jam_cooldown > 0: return false
	jam_left = minf(duration, 0.2 if elite else 1.0)
	jam_cooldown = 4.0 if elite else 2.0
	return true

func ability_rate() -> float:
	if jam_left > 0: return 0.0
	return 0.8 if fallback_left > 0 else 1.0
