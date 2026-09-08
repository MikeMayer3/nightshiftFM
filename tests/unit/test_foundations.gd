extends RefCounted

const VALID_WEAPON: WeaponDefinition = preload("res://tests/fixtures/valid_weapon.tres")
const VALID_SHIELD: ShieldDefinition = preload("res://tests/fixtures/valid_shield.tres")
const INVALID_WEAPON: WeaponDefinition = preload("res://tests/fixtures/invalid_weapon.tres")
const MISSING_REFERENCE: WaveDefinition = preload("res://tests/fixtures/missing_reference.tres")

func run(context: TestContext) -> bool:
	var valid: Array[ContentDefinition] = [VALID_WEAPON, VALID_SHIELD]
	context.check(ContentValidator.validate(valid).is_empty(), "valid .tres fixtures accepted")
	var invalid: Array[ContentDefinition] = [INVALID_WEAPON, MISSING_REFERENCE]
	var errors: PackedStringArray = ContentValidator.validate(invalid)
	for error: String in errors:
		print("EXPECTED INVALID FIXTURE: ", error)
	context.check(errors.size() == 2, "invalid fixtures produce exactly two errors")
	context.check(_contains(errors, "fixture.invalid_weapon", "attack_interval"), "interval error identifies content and field")
	context.check(_contains(errors, "fixture.missing_reference", "fixture.unknown_enemy"), "reference error identifies owner and missing ID")
	var duplicate: Array[ContentDefinition] = [VALID_WEAPON, VALID_WEAPON]
	context.check(_contains(ContentValidator.validate(duplicate), "fixture.main", "duplicate id"), "duplicate IDs rejected")
	context.check(_contains(ContentDefinition.new().validate(), "id:", "empty"), "empty stable ID rejected")
	var malformed: ContentDefinition = ContentDefinition.new()
	malformed.id = &"Not A Stable ID"
	context.check(_contains(malformed.validate(), "id:", "lowercase"), "malformed stable ID rejected")
	var absent: Array[ContentDefinition] = [null]
	context.check(_contains(ContentValidator.validate(absent), "entry[0]", "null"), "null definition reported safely")
	var nonfinite: WeaponDefinition = VALID_WEAPON.duplicate() as WeaponDefinition
	nonfinite.attack_interval = NAN
	context.check(_contains(nonfinite.validate(), "attack_interval", "finite"), "NaN attack interval rejected")

	# Instantiate all skeletons to ensure their scripts participate in engine checks.
	var skeletons: Array[ContentDefinition] = [WeaponDefinition.new(), ShieldDefinition.new(),
		UpgradeDefinition.new(), EnemyDefinition.new(), WaveDefinition.new(), MissionDefinition.new(),
		ModuleDefinition.new(), SynergyDefinition.new(), AchievementDefinition.new()]
	context.check(skeletons.size() == 9, "all nine typed definition skeletons instantiate")
	for definition: ContentDefinition in skeletons:
		context.check(not definition.validate().is_empty(), "unauthored definition rejected: %s" % definition.get_script().resource_path)

	var first: WeaponState = WeaponState.from_definition(VALID_WEAPON)
	first.rank = 8
	first.damage = 999.0
	var second: WeaponState = WeaponState.from_definition(VALID_WEAPON)
	context.check(second.rank == 1 and second.damage == 10.0, "new weapon state uses rank-1 definition baseline")
	context.check(VALID_WEAPON.base_damage == 10.0, "runtime mutation leaves cached weapon resource unchanged")
	context.check(second.to_data()["definition_id"] == "fixture.main", "state serialization exposes stable ID")
	var shield: ShieldState = ShieldState.from_definition(VALID_SHIELD)
	shield.current = 0.0
	shield.capacity = 999.0
	shield.rank = 8
	var next_shield: ShieldState = ShieldState.from_definition(VALID_SHIELD)
	context.check(next_shield.rank == 1 and next_shield.current == 30.0, "new shield state starts at baseline")
	context.check(VALID_SHIELD.base_capacity == 30.0, "runtime mutation leaves shield resource unchanged")
	var old_run: RunState = RunState.new()
	old_run.supports.append(first)
	old_run.temporary_modifier_ids.append(&"fixture.temporary")
	var new_run: RunState = RunState.new()
	context.check(new_run.supports.is_empty() and new_run.temporary_modifier_ids.is_empty(), "run instances own independent collections")
	var profile: ProfileState = ProfileState.new()
	profile.unlocked_equipment_ids.append(VALID_WEAPON.id)
	profile.unlocked_cosmetic_ids.append(&"fixture.cosmetic")
	var another_profile: ProfileState = ProfileState.new()
	context.check(another_profile.unlocked_equipment_ids.is_empty() and another_profile.unlocked_cosmetic_ids.is_empty(), "profile instances own independent option collections")
	context.check(GameRules.MAIN_WEAPON_SLOTS == 1 and GameRules.SHIELD_SLOTS == 1, "one separate main slot and shield slot")
	context.check(GameRules.MAX_SUPPORTS == 5 and GameRules.SupportFamily.size() == 6, "support contract is five slots from six families")
	return true

func _contains(errors: PackedStringArray, first: String, second: String) -> bool:
	for error: String in errors:
		if first in error and second in error:
			return true
	return false
