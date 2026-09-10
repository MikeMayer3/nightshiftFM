extends RefCounted
## Legal authored gameplay, with a short rolling capture window before Wideband.
static func choice(s: CombatSession) -> StringName:
	s.swap_branch(BassPayoff.BRANCH)
	for id: StringName in s.draft.offers:
		var card: UpgradeDefinition = s.draft.card(id)
		if card != null and card.target_id == &"bass_driver": return id
	return s.draft.offers[0]

static func prepare() -> Dictionary:
	var s: CombatSession = CombatSession.new()
	s.start_campaign(42, &"run.1", {"main":"pulse","shield":"capacitor","support":"bass_driver"}, {"mission":1,"cleared":0,"modules":[],"mode":"campaign","difficulty":0,"contract":""})
	var history: Array[Dictionary] = []
	for step: int in 9000:
		if s.is_finished(): break
		if s.is_deciding():
			var id: StringName = choice(s)
			if id == BassPayoff.BRANCH:
				var decision: Dictionary = s.to_checkpoint().duplicate(true)
				if not s.choose_upgrade(id): return {}
				return {"before":history[0], "decision":decision, "after":s.to_checkpoint().duplicate(true), "upgrade_seconds":s.elapsed, "seed":42}
			s.choose_upgrade(id)
		elif s.is_wiring(): s.launch_wave()
		else:
			if s.draft.track(&"bass_driver").rank() == 2:
				history.append(s.to_checkpoint().duplicate(true))
				if history.size() > 60: history.pop_front()
			if s.run.shield.current < 20: s.activate_shield()
			s.advance(.1)
	return {}
