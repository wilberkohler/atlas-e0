extends RefCounted
class_name WindModel

var seed: int = 1001
var strength: float = 0.15


func configure(new_seed: int, new_strength: float) -> void:
	seed = new_seed
	strength = clampf(new_strength, 0.0, 1.0)


func sample(time_seconds: float) -> Vector3:
	var seed_offset: float = float(seed % 997) * 0.017
	var slow: float = sin(time_seconds * 0.73 + seed_offset)
	var slower: float = cos(time_seconds * 0.41 + seed_offset * 1.7)
	var gust: float = sin(time_seconds * 1.37 + seed_offset * 0.6) * 0.35
	return Vector3(
		(slow * 0.34 + gust * 0.16) * strength,
		0.0,
		(slower * 0.48 + gust * 0.18) * strength
	)
