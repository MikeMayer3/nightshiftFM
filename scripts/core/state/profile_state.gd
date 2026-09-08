class_name ProfileState
extends RefCounted
## Permanent data contains options/cosmetics only, with no combat stat or rank fields.
## This is a data boundary, not a persistence/progression implementation.

var unlocked_equipment_ids: Array[StringName] = []
var unlocked_cosmetic_ids: Array[StringName] = []
