class_name ArsenalContent
extends RefCounted
const VERSION: String = "m5.1"
const FAMILIES: Array[StringName] = [&"arc_aerial", &"bass_driver", &"static_net", &"echo_deck", &"needle_swarm", &"reverb_well"]
const MAINS: Array[String] = ["pulse", "sweep", "burst"]
const SHIELDS: Array[String] = ["capacitor", "relay", "feedback"]
const DEFAULT: Dictionary = {"main": "pulse", "shield": "capacitor", "support": "arc_aerial"}
const DEFINITIONS: Dictionary = {
	"pulse": preload("res://content/arsenal/tracks/pulse.tres"),
	"sweep": preload("res://content/arsenal/tracks/sweep.tres"),
	"burst": preload("res://content/arsenal/tracks/burst.tres"),
	"capacitor": preload("res://content/arsenal/tracks/capacitor.tres"),
	"relay": preload("res://content/arsenal/tracks/relay.tres"),
	"feedback": preload("res://content/arsenal/tracks/feedback.tres"),
	"arc_aerial": preload("res://content/arsenal/tracks/arc_aerial.tres"),
	"bass_driver": preload("res://content/arsenal/tracks/bass_driver.tres"),
	"static_net": preload("res://content/arsenal/tracks/static_net.tres"),
	"echo_deck": preload("res://content/arsenal/tracks/echo_deck.tres"),
	"needle_swarm": preload("res://content/arsenal/tracks/needle_swarm.tres"),
	"reverb_well": preload("res://content/arsenal/tracks/reverb_well.tres"),
}
static func valid_loadout(value: Variant) -> bool:
	return value is Dictionary and value.size() == 3 and value.get("main") in MAINS and value.get("shield") in SHIELDS and value.get("support") in FAMILIES

static func tracks(loadout: Dictionary) -> Array[TrackDefinition]:
	var result: Array[TrackDefinition] = [DEFINITIONS[loadout.main], DEFINITIONS[loadout.shield]]
	for id: StringName in FAMILIES: result.append(DEFINITIONS[String(id)])
	return result
