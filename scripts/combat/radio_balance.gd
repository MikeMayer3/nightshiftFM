class_name RadioBalance
extends RefCounted
## Current automatic broadcasts: a protected entry corridor and bounded station reach.
const ENTRY_Y: float = 96.0
const SPAWN_Y: float = -80.0
const MAX_REACH: float = 588.0
const SUPPORT_REACH: Dictionary = {&"arc_aerial": 460.0, &"bass_driver": 420.0, &"static_net": 460.0, &"needle_swarm": 540.0, &"reverb_well": 440.0, &"echo_deck": 550.0}
static func enabled(s: CombatSession) -> bool:
	return s.active_combat != null and s.active_combat.automatic_radio
static func entered(s: CombatSession, actor: CombatActor) -> bool:
	return not actor.resolved and actor.health > 0 and (not enabled(s) or actor.position.y - actor.radius >= ENTRY_Y)
static func reach(s: CombatSession, id: StringName) -> float:
	var owned: UpgradeTrack = s.draft.track(id)
	if owned == null: return MAX_REACH
	if not enabled(s): return float(ArsenalStats.parameters(owned).reach) if id == &"main" else INF
	return station_reach(owned, (s.draft as ArsenalDraft).loadout.main)
static func station_reach(owned: UpgradeTrack, chassis: String) -> float:
	var id: StringName = owned.definition.id
	if id == &"main": return minf(MAX_REACH, float(ArsenalStats.parameters(owned).reach) * (.90 if chassis == "pulse" else .86 if chassis == "sweep" else 1.0))
	return minf(MAX_REACH, float(SUPPORT_REACH.get(id, MAX_REACH)) * (1 + ModuleStats.coefficient(owned.modules, &"reach")))
static func can_hit(s: CombatSession, actor: CombatActor, source: StringName) -> bool:
	return entered(s, actor) and (not enabled(s) or actor.position.distance_to(CombatSession.TRANSMITTER) <= reach(s, source))

static func health_scale(wave: int) -> float:
	# Ease the rank-one opening; retain full enemy health once builds mature.
	return minf(1.0, .8 + maxi(0, wave - 1) * .025)
