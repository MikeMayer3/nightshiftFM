extends SceneTree
## Legal offered choices and branch swaps; fixed policies, not human win-rate estimates.
const COHERENT: Dictionary = {"id":"coherent","main":"pulse","support":"needle_swarm","recipes":[&"needle_thread",&"b_side"],"branches":[&"m5.needle_swarm.b3",&"m5.echo_deck.b3",&"m5.pulse.b1"],"mix":[4,3,0]}
var checks: TestContext = TestContext.new()
func _initialize() -> void: run.call_deferred()

static func desired(build: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for recipe: StringName in build.recipes:
		for endpoint: StringName in PatchboardContent.RECIPES[recipe].endpoint_ids:
			if endpoint not in ids: ids.append(endpoint)
	return ids

static func choose(s: CombatSession, build: Dictionary) -> StringName:
	if build.id not in ["weak", "mixed"]:
		for branch: StringName in build.branches: s.swap_branch(branch)
	var chosen: StringName = s.draft.offers[0]
	var best: int = -999
	var wants: Array[StringName] = desired(build)
	for id: StringName in s.draft.offers:
		var card: UpgradeDefinition = s.draft.card(id)
		var score: int = 0
		if card != null:
			var owned: UpgradeTrack = s.draft.track(card.target_id)
			score = 30 if card.target_id in wants else 0
			if card.target_id == &"main": score += 15
			if SignalDraft.is_new(id): score += 120 if card.target_id in wants else -150
			if id in build.branches: score += 100
			if owned != null and card.target_id in wants and owned.rank() < 3: score += 60
			if card.target_id == &"shield" and s.run.shield.current < 20: score += 35
		if score > best: best = score; chosen = id
	return chosen

func run() -> void:
	var rows: Array[Dictionary] = []
	var builds: Array[Dictionary] = []
	for policy: String in ["coherent", "weak", "mixed", "no_shield", "no_focus", "no_mixer"]:
		var build: Dictionary = COHERENT.duplicate(true)
		build.id = policy
		if policy == "no_mixer": build.mix = [0,0,0]
		builds.append(build)
	for build: Dictionary in builds:
		for encounter: Array in [[1,0],[6,0],[12,0],[12,2]]:
			for seed_value: int in [11,42]:
				for connected: bool in [true]:
					var s: CombatSession = CombatSession.new()
					checks.check(s.start_campaign(seed_value, &"run.1", {"main": build.main, "shield": "capacitor", "support": build.support}, {"mission": encounter[0], "cleared": 12, "modules": [], "mode": "campaign", "difficulty": encounter[1], "contract": ""}), "valid comparison campaign")
					var restores: int = 0
					for step: int in 6000:
						if s.is_finished(): break
						s.paused = true
						for channel: int in 3:
							if s.patchboard.mixer.levels[channel] != build.mix[channel]: checks.check(s.patchboard.mixer.adjust(s,channel,build.mix[channel]), "legal mix")
						if connected:
							for slot: int in 2:
								var recipe: StringName = build.recipes[slot]
								if PatchboardState.eligible(s,recipe) and s.patchboard.slots[slot] != recipe: checks.check(s.patchboard.rewire(s,slot,recipe), "legal connection")
						s.paused = false
						if s.is_deciding():
							var choice: StringName = choose(s,build)
							if build.id == "mixed": choice = s.draft.offers[(seed_value + restores * 7) % s.draft.offers.size()]
							if build.id == "weak":
								# Legal defensive-first policy; passes on damage upgrades when possible.
								var priority: int = -999
								for offer: StringName in s.draft.offers:
									var card: UpgradeDefinition = s.draft.card(offer)
									var score: int = 100 if card != null and card.target_id == &"shield" else 50 if SignalDraft.is_new(offer) else 10 if card != null and card.target_id != &"main" else 0
									if score > priority: priority = score; choice = offer
							var snapshot: Dictionary = s.to_checkpoint()
							var hints: Array[Dictionary] = BuildGuide.suggestions(s,choice)
							checks.check(s.to_checkpoint() == snapshot,"preview does not change choices, RNG or saves")
							var restored: CombatSession = CombatSession.new()
							if not restored.restore_checkpoint(JSON.parse_string(JSON.stringify(snapshot,"",true,true))):
								checks.check(false,"legal decision checkpoint restores"); break
							s = restored; restores += 1
							checks.check(s.choose_upgrade(choice),"offered upgrade accepted")
							for hint: Dictionary in hints:
								checks.check(PatchboardState.eligible(s,hint.id) == hint.ready,"preview matches actual accepted build")
						elif s.is_wiring(): checks.check(s.launch_wave(),"legal launch")
						else:
							# Same simple focus policy; precision seeks existing marks when safe.
							var target: CombatActor = s.target()
							if build.id not in ["weak", "mixed"]:
								for actor: CombatActor in s.actors:
									if RadioBalance.can_hit(s,actor,&"main") and s.arsenal.mark_strength(actor.serial)>0: target=actor; break
							if target != null and build.id != "no_focus": s.focus_point = target.position; s.focus_active = true
							if build.id != "no_shield" and s.run.shield.current < s.run.shield.capacity*.3: s.activate_shield()
							s.advance(.2)
					checks.check(s.is_finished(),"comparison finished")
					var row: Dictionary = {"build":build.id,"mission":encounter[0],"difficulty":encounter[1],"seed":seed_value,"connected":connected,"victory":s.phase==CombatSession.Phase.VICTORY,"finished":s.is_finished(),"wave":s.wave,"hull":s.hull,"breaches":s.breaches,"seconds":s.elapsed,"restores":restores,"choices":s.draft.accepted,"loss_key":String(PostRunAnalysis.loss_key(s)),"loss_history":s.achievement_run.loss_history,"contributions":s.arsenal.report.totals,"connections":s.patchboard.to_data()}
					var end: CombatSession = CombatSession.new()
					checks.check(end.restore_checkpoint(JSON.parse_string(JSON.stringify(s.to_checkpoint(),"",true,true))),"finished report restores")
					checks.check(PostRunAnalysis.loss_key(end)==PostRunAnalysis.loss_key(s),"finished explanation survives restore")
					for category: String in ["breach", "projectile", "other"]:
						checks.check(is_equal_approx(float(end.achievement_run.loss_history[category]),float(s.achievement_run.loss_history[category])),"finished damage breakdown survives restore")
					checks.check(is_equal_approx(s.achievement_run.hull_damage,float(s.achievement_run.loss_history.breach)+float(s.achievement_run.loss_history.projectile)+float(s.achievement_run.loss_history.other)),"health loss reconciles without double counting")
					rows.append(row)
					print("%s m%d d%d seed%d connected=%s win=%s hull=%.1f" % [build.id,encounter[0],encounter[1],seed_value,connected,row.victory,s.hull])
	FileAccess.open("res://docs/evidence/P2-losses/comparison.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks.checks,"failures":checks.failures,"runs":rows},"\t",true,true))
	print("RESULT: %d runs; %d checks; %d failures" % [rows.size(),checks.checks,checks.failures])
	quit(0 if checks.failures==0 else 1)
