class_name ArsenalRuntime
extends RefCounted
## Explicit numeric-only effect envelopes. No object or callable deserialization.
const SCALARS: Dictionary = {"restore_wait": 2, "reservoir": 20, "overshield": 40, "overshield_left": 10, "echo_count": 10000, "shield_charge": 80, "emergency_wait": 30, "peak_pending": 256}
const BOUNDS: Dictionary = {
	"damage": [0, 200], "interval": [.08, 20], "crit": [0, .5], "reach": [40, 1000], "width": [4, 250], "targets": [1, 12], "pierce": [0, 10], "penetration": [0, 200], "duration": [.5, 10], "mode": [0, 3], "modifier": [0, 2], "capstone": [0, 1],
	"radius": [20, 400], "pull": [0, 150], "push": [0, 100], "speed": [100, 1000], "steering": [0, 20], "residual": [.1, 2], "slow": [0, .6], "charges": [0, 12], "pulses": [0, 8], "exposure": [0, 100], "jam": [0, 1], "projectiles": [1, 12], "copy_index": [0, 11], "retarget": [40, 1000]
}
const PARAMS: Array[String] = ["damage", "interval", "damage_bonus", "cadence", "crit", "reach", "width", "targets", "pierce", "penetration", "duration", "mode", "modifier", "capstone", "m5_marker", "elite_bonus", "healing", "reserve", "overheal", "echo_damage", "attacks", "delay", "copies", "priority", "distinct", "copy_index", "retarget", "radius", "push", "exposure", "pulses", "steering", "projectiles", "speed", "falloff", "mark", "pull", "slow", "orbit", "terminal", "release", "charges", "residual", "jam", "tick_rate", "bounce", "stagger"]

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 15: return false
	for key: String in SCALARS:
		if not SaveChecks.number(data.get(key), 0, SCALARS[key], key in ["echo_count", "peak_pending"]): return false
	if not data.get("timers") is Dictionary or data.timers.size() != 6: return false
	for id: StringName in ArsenalContent.FAMILIES:
		if not SaveChecks.number(data.timers.get(String(id)), 0, 20): return false
	for key: String in ["packets", "needles", "zones", "marks", "recordings"]:
		if not data.get(key) is Array or data[key].size() > (12 if key == "recordings" else 24 if key == "zones" else 128): return false
	for packet: Variant in data.packets + data.recordings:
		if not packet is Dictionary or packet.size() != 8 or packet.get("source") not in ["main", "echo_deck"] or packet.get("kind") not in ArsenalContent.MAINS: return false
		if not envelope(packet, ["root", "target", "left", "x", "y"]): return false
		if not parameters(packet.get("p")): return false
		if not packet.p.has("projectiles"): return false
		if packet.source == "echo_deck":
			for key: String in ["retarget", "distinct", "priority", "copy_index"]:
				if not packet.p.has(key): return false
	for needle: Variant in data.needles:
		if not needle is Dictionary or needle.size() != 9 or not envelope(needle, ["root", "target", "left", "x", "y"]): return false
		if not SaveChecks.number(needle.get("dx"), -1, 1) or not SaveChecks.number(needle.get("dy"), -1, 1): return false
		if not needle.get("hits") is Array or needle.hits.size() > 11 or not SaveChecks.unique(needle.hits): return false
		for id: Variant in needle.hits:
			if not SaveChecks.number(id, 1, 10000000, true): return false
		if not parameters(needle.get("p")): return false
		for key: String in ["steering", "speed", "projectiles"]:
			if not needle.p.has(key): return false
	for zone: Variant in data.zones:
		if not zone is Dictionary or zone.size() != 9 or zone.get("source") not in ["bass_driver", "static_net", "reverb_well"]: return false
		if not envelope(zone, ["root", "left", "x", "y", "tick", "remaining", "charges"]) or not parameters(zone.get("p")): return false
		for key: String in (["radius", "slow", "residual"] if zone.source == "static_net" else ["radius", "push"] if zone.source == "bass_driver" else ["radius", "pull"]):
			if not zone.p.has(key): return false
	for mark: Variant in data.marks:
		if not mark is Dictionary or mark.size() != 3 or not SaveChecks.number(mark.get("target"), 1, 10000000, true) or not SaveChecks.number(mark.get("strength"), 0, .5) or not SaveChecks.number(mark.get("left"), 0, 10): return false
	return true

static func envelope(item: Dictionary, keys: Array[String]) -> bool:
	for key: String in keys:
		var maximum: float = 10000000 if key in ["root", "target"] else 640 if key == "x" else 720 if key == "y" else 20
		if not SaveChecks.number(item.get(key), 0, maximum, key in ["root", "target", "remaining", "charges"]): return false
	return true

static func parameters(p: Variant) -> bool:
	if not p is Dictionary: return false
	for key: Variant in p:
		if String(key) not in PARAMS or not SaveChecks.number(p[key], -1000, 1000): return false
	for key: String in BOUNDS:
		if p.has(key) and not SaveChecks.number(p[key], BOUNDS[key][0], BOUNDS[key][1], key in ["targets", "pierce", "mode", "modifier", "capstone", "charges", "pulses", "projectiles", "copy_index"]): return false
	for key: String in ["damage", "interval", "crit", "reach", "width", "targets", "pierce", "penetration", "duration", "mode"]:
		if not p.has(key) or float(p[key]) < 0: return false
	if p.interval < .08 or p.interval > 20 or p.damage > 200 or p.duration > 10 or p.targets > 12 or p.pierce > 10: return false
	if p.has("projectiles") and not SaveChecks.number(p.projectiles, 1, 12, true): return false
	return true

static func references(session: CombatSession) -> bool:
	var runtime: ArsenalCombat = session.supports as ArsenalCombat
	for items: Array in [runtime.packets, runtime.recordings, runtime.needles, runtime.zones]:
		for item: Dictionary in items:
			if int(item.root) < 1 or int(item.root) > session.attack_serial: return false
			if item.has("target") and (int(item.target) < 1 or int(item.target) > session._serial): return false
			var source: StringName = StringName(item.get("source", "needle_swarm"))
			if session.draft.track(source) == null: return false
			if source == &"echo_deck" and item.kind != (session.draft as ArsenalDraft).loadout.main: return false
	for needle: Dictionary in runtime.needles:
		for id: Variant in needle.hits:
			if int(id) > session._serial: return false
	for mark: Dictionary in runtime.marks:
		if int(mark.target) > session._serial or session.draft.track(&"needle_swarm") == null: return false
	if session.phase in [CombatSession.Phase.INTERMISSION, CombatSession.Phase.VICTORY, CombatSession.Phase.DEFEAT]:
		if not runtime.packets.is_empty() or not runtime.recordings.is_empty() or not runtime.needles.is_empty() or not runtime.zones.is_empty() or not runtime.marks.is_empty(): return false
	return true
