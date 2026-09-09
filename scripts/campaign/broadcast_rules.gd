class_name BroadcastRules
extends RefCounted
## Explicit expanded-run rules. Legacy three-field campaign contexts remain unchanged.
const VERSION: String = "m8.broadcast.1"
const CONTRACTS: Array[String] = ["two_channel", "bare_antenna", "fragile_broadcast", "no_repeats", "overcrowded_frequency", "long_distance"]
const MODES: Array[String] = ["campaign", "contract", "endless"]
static func support_limit(context: CampaignRun) -> int:
	return 0 if context.contract == "bare_antenna" else 2 if context.contract == "two_channel" else 5
static func health_scale(context: CampaignRun, wave: int) -> float:
	var scale: float = [1.0, 1.32, 1.65][context.difficulty]
	if context.mode == "endless" and wave > 10: scale *= 1 + (wave - 10) * .06
	return scale
static func damage_scale(context: CampaignRun, wave: int) -> float:
	return [1.0, 1.15, 1.3][context.difficulty] * (1 + maxf(0, wave - 10) * .025 if context.mode == "endless" else 1.0)
static func wave_for(context: CampaignRun, wave: int) -> WaveDefinition:
	var mission: int = context.mission
	if context.mode == "endless": mission = mini(12, 1 + maxi(0, wave - 1) / 5)
	var index: int = (wave - 1) % 10
	if context.mode == "endless" and wave > 10 and wave % 5 == 0:
		mission = [4, 8, 12][((wave / 5) - 3) % 3]
		index = 9
	var source: WaveDefinition = BroadcastWaves.MISSIONS[mission][index]
	if context.contract not in ["overcrowded_frequency", "long_distance"]: return source
	var changed: WaveDefinition = source.duplicate()
	changed.enemy_ids = source.enemy_ids.duplicate()
	for n: int in changed.enemy_ids.size():
		if n % 3 == 1 and BroadcastContent.enemy(changed.enemy_ids[n]).role < EnemyDefinition.Role.CALLER: changed.enemy_ids[n] = &"m2.swarmer" if context.contract == "overcrowded_frequency" else &"m8.mortar"
	if context.contract == "overcrowded_frequency": changed.spawn_interval *= .8
	return changed
static func expanded(session: CombatSession) -> bool:
	return session.campaign != null and session.campaign.expanded
