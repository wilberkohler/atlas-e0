extends RefCounted
class_name VS1AssemblyMetrics

const EXPECTED_FIN_COUNT := 3

var fin_count: int = 0
var fin_presence_score: float = 0.0
var fin_spacing_score: float = 0.0
var fin_tilt_score: float = 0.0
var fin_orientation_score: float = 0.0
var fin_height_score: float = 0.0
var attachment_score: float = 0.0
var cone_alignment_score: float = 0.0
var stability_score: float = 0.0
var asymmetry_vector: Vector2 = Vector2.ZERO
var asymmetry_magnitude: float = 0.0
var dominant_cause: String = "fin_presence"


func update_from_configuration(configuration: Variant) -> void:
	var configuration_data := _configuration_snapshot(configuration)
	var attached_fins := _attached_fins(configuration_data)
	fin_count = attached_fins.size()
	fin_presence_score = _normalized(float(fin_count) / float(EXPECTED_FIN_COUNT))
	fin_spacing_score = _circular_spacing_score(attached_fins)
	fin_tilt_score = _mean_axis_score(attached_fins, "tilt")
	fin_orientation_score = _mean_axis_score(attached_fins, "orientation")
	fin_height_score = _height_consistency_score(attached_fins)
	attachment_score = _attachment_score(attached_fins)
	cone_alignment_score = _cone_alignment(configuration_data)
	asymmetry_vector = _calculate_asymmetry(attached_fins)
	asymmetry_magnitude = _normalized(asymmetry_vector.length())

	stability_score = _normalized(
		fin_presence_score * 0.23
		+ fin_spacing_score * 0.25
		+ fin_tilt_score * 0.12
		+ fin_orientation_score * 0.10
		+ fin_height_score * 0.08
		+ attachment_score * 0.14
		+ cone_alignment_score * 0.08
	)
	stability_score = _normalized(stability_score * (1.0 - asymmetry_magnitude * 0.28))
	dominant_cause = _find_dominant_cause()


func snapshot() -> Dictionary:
	return {
		"fin_count": fin_count,
		"fin_presence_score": fin_presence_score,
		"fin_spacing_score": fin_spacing_score,
		"fin_tilt_score": fin_tilt_score,
		"fin_orientation_score": fin_orientation_score,
		"fin_height_score": fin_height_score,
		"attachment_score": attachment_score,
		"cone_alignment_score": cone_alignment_score,
		"stability_score": stability_score,
		"asymmetry_vector": {
			"x": asymmetry_vector.x,
			"y": asymmetry_vector.y
		},
		"asymmetry_magnitude": asymmetry_magnitude,
		"dominant_cause": dominant_cause
	}


func to_dict() -> Dictionary:
	return snapshot()


static func evaluate(configuration: Variant) -> Dictionary:
	var metrics: RefCounted = load("res://scripts/assembly/assembly_metrics.gd").new()
	metrics.call("update_from_configuration", configuration)
	return metrics.call("snapshot")


static func from_configuration(configuration: Variant) -> RefCounted:
	var metrics: RefCounted = load("res://scripts/assembly/assembly_metrics.gd").new()
	metrics.call("update_from_configuration", configuration)
	return metrics


func _configuration_snapshot(configuration: Variant) -> Dictionary:
	if typeof(configuration) == TYPE_DICTIONARY:
		return (configuration as Dictionary).duplicate(true)
	if configuration != null and configuration.has_method("snapshot"):
		var value: Variant = configuration.call("snapshot")
		if typeof(value) == TYPE_DICTIONARY:
			return value
	return {}


func _attached_fins(configuration_data: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	var raw_fins: Variant = configuration_data.get("fins", [])
	if typeof(raw_fins) != TYPE_ARRAY:
		return output
	for raw_fin: Variant in raw_fins:
		if typeof(raw_fin) != TYPE_DICTIONARY:
			continue
		var fin: Dictionary = raw_fin
		if bool(fin.get("attached", false)):
			output.append(fin)
	return output


func _circular_spacing_score(attached_fins: Array[Dictionary]) -> float:
	if attached_fins.size() < 2:
		return 0.0
	var positions: Array[float] = []
	for fin: Dictionary in attached_fins:
		positions.append(fposmod(_finite(float(fin.get("angular_position", 0.0))), 1.0))
	positions.sort()

	var expected_gap := 1.0 / float(positions.size())
	var total_error := 0.0
	for index: int in range(positions.size()):
		var next_index := (index + 1) % positions.size()
		var gap := positions[next_index] - positions[index]
		if next_index == 0:
			gap += 1.0
		total_error += absf(gap - expected_gap)
	return _normalized(1.0 - total_error)


func _mean_axis_score(attached_fins: Array[Dictionary], key: String) -> float:
	if attached_fins.is_empty():
		return 0.0
	var total := 0.0
	for fin: Dictionary in attached_fins:
		total += 1.0 - absf(clampf(_finite(float(fin.get(key, 0.0))), -1.0, 1.0))
	return _normalized(total / float(attached_fins.size()))


func _height_consistency_score(attached_fins: Array[Dictionary]) -> float:
	if attached_fins.is_empty():
		return 0.0
	if attached_fins.size() == 1:
		return 0.5
	var minimum := 1.0
	var maximum := 0.0
	for fin: Dictionary in attached_fins:
		var height := _normalized(float(fin.get("height", 0.5)))
		minimum = minf(minimum, height)
		maximum = maxf(maximum, height)
	return _normalized(1.0 - (maximum - minimum))


func _attachment_score(attached_fins: Array[Dictionary]) -> float:
	if attached_fins.is_empty():
		return 0.0
	var total := 0.0
	for fin: Dictionary in attached_fins:
		var quality := _normalized(float(fin.get("attachment_quality", 0.0)))
		var fixed_score := 1.0 if bool(fin.get("fixed", false)) else 0.0
		total += quality * 0.72 + fixed_score * 0.28
	return _normalized(total / float(attached_fins.size()))


func _cone_alignment(configuration_data: Dictionary) -> float:
	var cone_value: Variant = configuration_data.get("cone", {})
	if typeof(cone_value) != TYPE_DICTIONARY:
		return 0.0
	var cone: Dictionary = cone_value
	if not bool(cone.get("present", false)):
		return 0.45
	var centering := _normalized(float(cone.get("centering", 0.0)))
	var deviation := absf(clampf(_finite(float(cone.get("angular_deviation", 0.0))), -1.0, 1.0))
	var attachment := _normalized(float(cone.get("attachment_quality", 0.0)))
	return _normalized(centering * (1.0 - deviation) * (0.65 + attachment * 0.35))


func _calculate_asymmetry(attached_fins: Array[Dictionary]) -> Vector2:
	if attached_fins.is_empty():
		return Vector2.RIGHT
	var average_height := 0.0
	for fin: Dictionary in attached_fins:
		average_height += _normalized(float(fin.get("height", 0.5)))
	average_height /= float(attached_fins.size())

	var placement := Vector2.ZERO
	var faults := Vector2.ZERO
	for fin: Dictionary in attached_fins:
		var angle := fposmod(_finite(float(fin.get("angular_position", 0.0))), 1.0) * TAU
		var radial := Vector2(cos(angle), sin(angle))
		placement += radial
		var tilt := absf(clampf(_finite(float(fin.get("tilt", 0.0))), -1.0, 1.0))
		var orientation := absf(clampf(_finite(float(fin.get("orientation", 0.0))), -1.0, 1.0))
		var quality := _normalized(float(fin.get("attachment_quality", 0.0)))
		var height_delta := absf(_normalized(float(fin.get("height", 0.5))) - average_height)
		var fault_weight := tilt * 0.42 + orientation * 0.22 + (1.0 - quality) * 0.24 + height_delta * 0.12
		faults += radial * fault_weight

	placement /= float(attached_fins.size())
	faults /= float(attached_fins.size())
	var missing_fin_bias := Vector2.RIGHT * (1.0 - fin_presence_score) * 0.30
	var result := placement * 0.72 + faults * 0.58 + missing_fin_bias
	return result.limit_length(1.0)


func _find_dominant_cause() -> String:
	var scores := {
		"fin_presence": fin_presence_score,
		"fin_spacing": fin_spacing_score,
		"fin_tilt": fin_tilt_score,
		"fin_orientation": fin_orientation_score,
		"fin_height": fin_height_score,
		"attachment": attachment_score,
		"cone_alignment": cone_alignment_score
	}
	var cause := "balanced"
	var lowest := 0.72
	for key: Variant in scores.keys():
		var value := float(scores[key])
		if value < lowest:
			lowest = value
			cause = String(key)
	return cause


func _normalized(value: float) -> float:
	return clampf(_finite(value), 0.0, 1.0)


func _finite(value: float) -> float:
	return value if is_finite(value) else 0.0
