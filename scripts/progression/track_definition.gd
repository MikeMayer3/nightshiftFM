class_name TrackDefinition
extends Resource
@export var attack_kind: StringName = &"direct"
## Read-only catalog data. Runtime state never writes this Resource or its children.
@export var id: StringName
@export var name_key: StringName
@export var preview_key: StringName
@export var support: bool = false
@export var baseline: Dictionary = {}
@export var options: Array[UpgradeDefinition] = []
