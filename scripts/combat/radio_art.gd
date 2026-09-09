class_name RadioArt
extends RefCounted
## Immutable presentation lookup. Era never changes stats, IDs or collisions.
const ENEMIES: Array = [
	[preload("res://assets/art/radio/swarmer_1.svg"), preload("res://assets/art/radio/diver_1.svg"), preload("res://assets/art/radio/carrier_1.svg")],
	[preload("res://assets/art/radio/swarmer_2.svg"), preload("res://assets/art/radio/diver_2.svg"), preload("res://assets/art/radio/carrier_2.svg")],
	[preload("res://assets/art/radio/swarmer_3.svg"), preload("res://assets/art/radio/diver_3.svg"), preload("res://assets/art/radio/carrier_3.svg")],
]
const MAIN: Dictionary = {
	"pulse": preload("res://assets/art/radio/pulse.svg"),
	"sweep": preload("res://assets/art/radio/sweep.svg"),
	"burst": preload("res://assets/art/radio/burst.svg"),
}
const BACKGROUNDS: Array[Color] = [Color("201e26"), Color("18232e"), Color("12282d")]
const TRIMS: Array[Color] = [Color("80684d"), Color("566a82"), Color("467a7a")]

static func era(session: CombatSession) -> int:
	return clampi((session.campaign.mission - 1) / 4, 0, 2) if session.campaign != null else 0

static func enemy(actor: CombatActor, era_index: int) -> Texture2D:
	return ENEMIES[clampi(era_index, 0, 2)][int(actor.path_kind)]

static func main_texture(session: CombatSession) -> Texture2D:
	var key: String = session.draft.loadout.main if session.draft is ArsenalDraft else "pulse"
	return MAIN.get(key, MAIN.pulse)
