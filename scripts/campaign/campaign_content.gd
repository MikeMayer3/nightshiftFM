class_name CampaignContent
extends RefCounted
const VERSION: String = "m7.1"
const MODULES: Dictionary = {
	&"hot_tubes": preload("res://content/modules/hot_tubes.tres"),
	&"long_mast": preload("res://content/modules/long_mast.tres"),
	&"heavy_battery": preload("res://content/modules/heavy_battery.tres"),
	&"fast_fuse": preload("res://content/modules/fast_fuse.tres"),
	&"signal_booster": preload("res://content/modules/signal_booster.tres"),
	&"quiet_room": preload("res://content/modules/quiet_room.tres"),
	&"wideband_module": preload("res://content/modules/wideband_module.tres"),
	&"narrowband_module": preload("res://content/modules/narrowband_module.tres"),
	&"counterweight": preload("res://content/modules/counterweight.tres"),
	&"thin_wire": preload("res://content/modules/thin_wire.tres"),
	&"night_ledger": preload("res://content/modules/night_ledger.tres"),
	&"glass_tower": preload("res://content/modules/glass_tower.tres"),
}
const MISSIONS: Array[MissionDefinition] = [
	preload("res://content/missions/campaign_01.tres"),
	preload("res://content/missions/campaign_02.tres"),
	preload("res://content/missions/campaign_03.tres"),
	preload("res://content/missions/campaign_04.tres"),
	preload("res://content/missions/campaign_05.tres"),
	preload("res://content/missions/campaign_06.tres"),
	preload("res://content/missions/campaign_07.tres"),
	preload("res://content/missions/campaign_08.tres"),
	preload("res://content/missions/campaign_09.tres"),
	preload("res://content/missions/campaign_10.tres"),
	preload("res://content/missions/campaign_11.tres"),
	preload("res://content/missions/campaign_12.tres"),
]
static func options(cleared: int, category: String) -> Array:
	if category == "main":
		var ids: Array = ["pulse"]
		if cleared >= 4: ids.append("sweep")
		if cleared >= 6: ids.append("burst")
		return ids
	if category == "shield":
		var ids: Array = ["capacitor"]
		if cleared >= 3: ids.append("relay")
		if cleared >= 8: ids.append("feedback")
		return ids
	if category == "support":
		var ids: Array = ["arc_aerial", "bass_driver", "static_net"]
		if cleared >= 2: ids.append("echo_deck")
		if cleared >= 3: ids.append("reverb_well")
		if cleared >= 4: ids.append("needle_swarm")
		return ids
	var ids: Array = []
	for id: StringName in MODULES:
		if cleared >= MODULES[id].unlock_mission: ids.append(String(id))
	return ids

static func valid_modules(value: Variant, cleared: int = 12) -> bool:
	if not SaveChecks.ids(value, 2) or not SaveChecks.unique(value): return false
	for id: Variant in value:
		if String(id) not in options(cleared, "modules"): return false
	return true

static func valid_selection(loadout: Variant, modules: Variant, cleared: int) -> bool:
	if not ArsenalContent.valid_loadout(loadout) or not valid_modules(modules, cleared): return false
	for category: String in ["main", "shield", "support"]:
		if loadout[category] not in options(cleared, category): return false
	return true
