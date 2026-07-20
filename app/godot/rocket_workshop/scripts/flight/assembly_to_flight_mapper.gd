extends RefCounted
class_name AssemblyToFlightMapper

const FlightParametersScript := preload("res://scripts/flight/flight_parameters.gd")


static func map(assembly: Node, flight_seed: int) -> Resource:
	var parameters: Resource = FlightParametersScript.new()
	var fin_qualities: Array[float] = assembly.get_fin_qualities()
	var fin_count: int = fin_qualities.size()
	var fin_average: float = _average(fin_qualities)
	var cone_quality: float = assembly.get_zone_quality("nose")
	var energy_quality: float = assembly.get_energy_score()
	var fin_presence: float = clampf(float(fin_count) / 3.0, 0.0, 1.0)

	parameters.energy = clampf(energy_quality, 0.12, 1.0)
	parameters.fin_count = fin_count
	parameters.fin_alignment = clampf(fin_average, 0.0, 1.0)
	parameters.fin_symmetry = clampf((fin_presence * 0.76) + (fin_average * 0.24), 0.0, 1.0)
	parameters.nose_alignment = clampf(cone_quality, 0.0, 1.0)
	parameters.attachment_quality = clampf(_attachment_average(cone_quality, energy_quality, fin_qualities), 0.0, 1.0)
	parameters.mass_balance = clampf(0.35 + fin_presence * 0.40 + cone_quality * 0.15 + energy_quality * 0.10, 0.0, 1.0)
	parameters.body_drag_factor = clampf(0.24 + (1.0 - cone_quality) * 0.28 + (1.0 - fin_presence) * 0.24, 0.0, 1.0)
	parameters.wind_strength = 0.12 + (1.0 - parameters.fin_symmetry) * 0.20
	parameters.flight_seed = flight_seed
	return parameters


static func _attachment_average(cone_quality: float, energy_quality: float, fin_qualities: Array[float]) -> float:
	var values: Array[float] = []
	values.append(cone_quality)
	values.append(energy_quality)
	for quality: float in fin_qualities:
		values.append(quality)
	return _average(values)


static func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / float(values.size())
