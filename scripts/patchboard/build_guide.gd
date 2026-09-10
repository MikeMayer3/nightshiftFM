class_name BuildGuide
extends RefCounted
## Read-only previews use the same eligibility as actual connections. No RNG/save writes.
static func preview_tracks(session: CombatSession, choice: StringName) -> Array[UpgradeTrack]:
	var tracks: Array[UpgradeTrack] = []
	for owned: UpgradeTrack in session.draft.tracks:
		var copy: UpgradeTrack = UpgradeTrack.new(owned.definition)
		copy.choices = owned.choices.duplicate()
		copy.stats = owned.stats.duplicate(true)
		copy.modules = owned.modules.duplicate()
		copy.mixer = owned.mixer
		tracks.append(copy)
	var option: UpgradeDefinition = session.draft.card(choice)
	if option == null or choice == SignalDraft.OVERDRIVE: return tracks
	if SignalDraft.is_new(choice):
		if session.draft.track(option.target_id) != null or session.draft.support_count() >= GameRules.MAX_SUPPORTS: return tracks
		for definition: TrackDefinition in session.draft.catalog:
			if definition.id == option.target_id and definition.support:
				var added: UpgradeTrack = UpgradeTrack.new(definition)
				added.modules.assign(session.module_ids())
				added.mixer = session.patchboard.mixer if session.patchboard != null else null
				tracks.append(added)
	else:
		for track: UpgradeTrack in tracks:
			if track.definition.id == option.target_id: track.accept(choice, session.draft.banished)
	return tracks

static func track_in(tracks: Array[UpgradeTrack], id: StringName) -> UpgradeTrack:
	for track: UpgradeTrack in tracks:
		if track.definition.id == id: return track
	return null

static func state(session: CombatSession, recipe_id: StringName, choice: StringName = &"") -> Dictionary:
	var tracks: Array[UpgradeTrack] = session.draft.tracks if choice == &"" else preview_tracks(session, choice)
	var recipe: SynergyDefinition = PatchboardContent.RECIPES[recipe_id]
	var missing: Array[StringName] = []
	for endpoint: StringName in recipe.endpoint_ids:
		if track_in(tracks, endpoint) == null: missing.append(endpoint)
	var ready: bool = PatchboardState.eligible_tracks(tracks, recipe_id)
	var before: bool = PatchboardState.eligible(session, recipe_id)
	var connected: bool = session.patchboard != null and recipe_id in session.patchboard.slots
	var key: StringName = &"P1_MISSING_GEAR"
	if missing.is_empty(): key = &"P1_NEEDS_MARK" if recipe.capability == &"marked" else &"P1_NEEDS_SLOW"
	if ready: key = &"P1_CONNECTED" if connected else &"P1_READY" if before else &"P1_READY_AFTER"
	if connected and before and not ready: key = &"P1_BREAKS_CONNECTION"
	var warning_key: StringName = &""
	var net: UpgradeTrack = track_in(tracks, &"static_net")
	if recipe_id == &"dead_zone" and net != null and float(ArsenalStats.parameters(net).get(&"jam", 0)) >= recipe.duration:
		warning_key = &"P1_JAM_OVERLAP"
	return {"id": recipe_id, "tracks": tracks, "missing": missing, "ready": ready, "before": before, "connected": connected, "status_key": key, "warning_key": warning_key}

static func suggestions(session: CombatSession, choice: StringName) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var option: UpgradeDefinition = session.draft.card(choice)
	if session.patchboard == null or session.arsenal == null or option == null or choice == SignalDraft.OVERDRIVE: return rows
	for id: StringName in PatchboardContent.RECIPES:
		if option.target_id not in PatchboardContent.RECIPES[id].endpoint_ids: continue
		rows.append(state(session, id, choice))
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var sa: int = score(a)
		var sb: int = score(b)
		return sa > sb if sa != sb else String(a.id) < String(b.id))
	return rows

static func score(row: Dictionary) -> int:
	if row.connected and row.before and not row.ready: return 500
	if row.ready and not row.before: return 400
	if row.connected: return 300
	if row.ready: return 200
	return 100 - row.missing.size()
