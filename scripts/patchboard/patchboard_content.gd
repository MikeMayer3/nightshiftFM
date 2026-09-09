class_name PatchboardContent
extends RefCounted
const VERSION: String = "m6.1"
const RECIPES: Dictionary = {
	&"ball_lightning": preload("res://content/synergies/ball_lightning.tres"),
	&"dead_zone": preload("res://content/synergies/dead_zone.tres"),
	&"b_side": preload("res://content/synergies/b_side.tres"),
	&"live_wire": preload("res://content/synergies/live_wire.tres"),
	&"pressure_drop": preload("res://content/synergies/pressure_drop.tres"),
	&"double_drop": preload("res://content/synergies/double_drop.tres"),
	&"needle_thread": preload("res://content/synergies/needle_thread.tres"),
	&"feedback_loop": preload("res://content/synergies/feedback_loop.tres"),
}
