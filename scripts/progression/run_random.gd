class_name RunRandom
extends RefCounted
const STREAMS: Array[String] = ["wave", "draft", "combat", "cosmetic"]
var seed_value: int
var streams: Dictionary = {}

func _init(initial_seed: int = 1) -> void:
	seed_value = initial_seed
	for key: String in STREAMS:
		var generator: RandomNumberGenerator = RandomNumberGenerator.new()
		generator.seed = (str(initial_seed) + ":" + key).hash()
		streams[key] = generator

func rng(key: String) -> RandomNumberGenerator:
	return streams[key] as RandomNumberGenerator

func to_data() -> Dictionary:
	var result: Dictionary = {"seed": str(seed_value)}
	for key: String in STREAMS:
		# JSON numbers are doubles: decimal strings preserve the full signed 64-bit state.
		result[key] = str(rng(key).state)
	return result

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 5:
		return false
	for key: String in ["seed", "wave", "draft", "combat", "cosmetic"]:
		if not data.get(key) is String or not data[key].is_valid_int() or str(int(data[key])) != data[key]:
			return false
	return true

func restore(data: Dictionary) -> void:
	seed_value = int(data.seed)
	for key: String in STREAMS:
		rng(key).seed = (str(seed_value) + ":" + key).hash()
		rng(key).state = int(data[key])
