extends Resource
class_name VS1FlightProfile

@export var preset_id := "stable"
@export_range(0, 3, 1) var fin_count := 3
@export var fin_positions := PackedFloat32Array([0.0, 0.333, 0.667])
@export var fin_tilts := PackedFloat32Array([0.0, 0.0, 0.0])
@export var fin_heights := PackedFloat32Array([0.5, 0.5, 0.5])
@export var fin_orientations := PackedFloat32Array([0.0, 0.0, 0.0])
@export var fixation_quality := PackedFloat32Array([0.86, 0.86, 0.86])
@export var cone_present := true
@export_range(-1.0, 1.0, 0.01) var cone_deviation := 0.0
@export_range(0.0, 1.0, 0.01) var cone_centering := 0.94
@export_range(0.0, 1.0, 0.01) var cone_fixation := 0.82
@export_range(0.0, 1.0, 0.01) var water_level := 0.52
@export_range(0.0, 1.0, 0.01) var energy_level := 0.72
@export var wind_seed := 4242


func to_configuration_snapshot() -> Dictionary:
	var fins: Array[Dictionary] = []
	for index: int in range(fin_count):
		fins.append({
			"fin_id": "fin_%d" % [index + 1],
			"attached": true,
			"angular_position": _sample(fin_positions, index, float(index) / 3.0),
			"tilt": _sample(fin_tilts, index, 0.0),
			"height": _sample(fin_heights, index, 0.5),
			"orientation": _sample(fin_orientations, index, 0.0),
			"reposition_count": 0,
			"attachment_quality": _sample(fixation_quality, index, 0.7),
			"fixed": true,
		})
	return {
		"schema_version": 1,
		"revision": 1,
		"body_present": true,
		"fins": fins,
		"cone": {
			"present": cone_present,
			"angular_deviation": cone_deviation,
			"centering": cone_centering,
			"attachment_quality": cone_fixation,
			"fixed": cone_present,
		},
		"water_level": water_level,
		"energy_level": energy_level,
	}


func _sample(values: PackedFloat32Array, index: int, fallback: float) -> float:
	return float(values[index]) if index >= 0 and index < values.size() else fallback
