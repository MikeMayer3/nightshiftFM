class_name AchievementPlatform
extends RefCounted
## Honest offline adapter boundary. M11 supplies actual native implementations.
func available() -> bool: return false
func status_key() -> StringName: return &"M9_NATIVE_UNAVAILABLE"
func submit(_id: StringName, _progress: float) -> Error: return ERR_UNAVAILABLE
