class_name RunState
extends RefCounted
## M0 shape only. No mission lifecycle, recruitment, saves, or RNG service yet.
## A new instance has no inherited combat upgrades. Loadout validation comes with M3.

var main_weapon: WeaponState
var shield: ShieldState
var supports: Array[WeaponState] = []
var temporary_modifier_ids: Array[StringName] = []
var content_version: String = GameRules.CONTENT_VERSION
