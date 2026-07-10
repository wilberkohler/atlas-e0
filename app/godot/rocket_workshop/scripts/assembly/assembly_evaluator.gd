extends RefCounted
class_name AssemblyEvaluator


static func evaluate(assembly: Node) -> Dictionary:
	var fin_qualities: Array[float] = assembly.get_fin_qualities()
	var fin_count: int = fin_qualities.size()
	var fin_average: float = _average(fin_qualities)
	var fin_presence_score: float = clampf(float(fin_count) / 3.0, 0.0, 1.0)
	var symmetry_score: float = clampf((fin_average * 0.68) + (fin_presence_score * 0.32), 0.0, 1.0)
	var nose_alignment_score: float = assembly.get_zone_quality("nose")
	var energy_score: float = assembly.get_energy_score()
	var combined: float = clampf((symmetry_score * 0.42) + (nose_alignment_score * 0.30) + (energy_score * 0.28), 0.0, 1.0)
	var trajectory: String = "short_unstable"
	if fin_count >= 3 and nose_alignment_score > 0.0 and energy_score > 0.0:
		trajectory = "stable"
	elif combined >= 0.48:
		trajectory = "reasonable_spin"

	return {
		"symmetryScore": symmetry_score,
		"noseAlignmentScore": nose_alignment_score,
		"energyScore": energy_score,
		"combinedScore": combined,
		"finCount": fin_count,
		"trajectory": trajectory
	}


static func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / float(values.size())
