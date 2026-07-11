extends RefCounted
class_name VS1AttemptRecord

const SCHEMA_VERSION := 1
const MAX_TRAJECTORY_SAMPLES := 1200

var session_id: String = ""
var attempt_id: String = ""
var timestamp_utc: String = ""
var timestamp_unix: float = 0.0
var completed_at_utc: String = ""
var completed_at_unix: float = 0.0
var assembly_time_seconds: float = 0.0
var first_piece_touched: String = ""
var interaction_order: Array[String] = []
var interactions: Array[Dictionary] = []
var configuration_snapshot: Dictionary = {}
var metrics_snapshot: Dictionary = {}
var wind_seed: int = 0
var phase_timestamps: Dictionary = {}
var time_to_launch_seconds: float = -1.0
var trajectory: Array[Dictionary] = []
var max_height: float = 0.0
var time_to_apex_seconds: float = -1.0
var lateral_displacement: float = 0.0
var total_rotation: float = 0.0
var impact_position: Dictionary = {"x": 0.0, "y": 0.0, "z": 0.0}
var flight_duration_seconds: float = 0.0
var changes_after_flight: int = 0
var time_to_next_attempt_seconds: float = -1.0
var launched_again: bool = false
var flight_completed: bool = false


func begin(
	new_session_id: String,
	new_attempt_id: String,
	configuration: Variant,
	metrics: Dictionary = {},
	new_wind_seed: int = 0
) -> void:
	reset()
	session_id = new_session_id.strip_edges()
	attempt_id = new_attempt_id.strip_edges()
	timestamp_unix = Time.get_unix_time_from_system()
	timestamp_utc = Time.get_datetime_string_from_system(true, false)
	configuration_snapshot = _snapshot_from(configuration)
	metrics_snapshot = _safe_dictionary(metrics)
	wind_seed = new_wind_seed


func reset() -> void:
	session_id = ""
	attempt_id = ""
	timestamp_utc = ""
	timestamp_unix = 0.0
	completed_at_utc = ""
	completed_at_unix = 0.0
	assembly_time_seconds = 0.0
	first_piece_touched = ""
	interaction_order.clear()
	interactions.clear()
	configuration_snapshot.clear()
	metrics_snapshot.clear()
	wind_seed = 0
	phase_timestamps.clear()
	time_to_launch_seconds = -1.0
	trajectory.clear()
	max_height = 0.0
	time_to_apex_seconds = -1.0
	lateral_displacement = 0.0
	total_rotation = 0.0
	impact_position = {"x": 0.0, "y": 0.0, "z": 0.0}
	flight_duration_seconds = 0.0
	changes_after_flight = 0
	time_to_next_attempt_seconds = -1.0
	launched_again = false
	flight_completed = false


func record_interaction(
	piece_id: String,
	action: String,
	elapsed_seconds: float,
	payload: Dictionary = {}
) -> void:
	var safe_piece_id := piece_id.strip_edges()
	if first_piece_touched.is_empty() and not safe_piece_id.is_empty():
		first_piece_touched = safe_piece_id
	if not safe_piece_id.is_empty():
		interaction_order.append(safe_piece_id)
	interactions.append({
		"order": interactions.size() + 1,
		"piece_id": safe_piece_id,
		"action": action.strip_edges(),
		"elapsed_seconds": _seconds(elapsed_seconds),
		"payload": _safe_dictionary(payload)
	})


func mark_phase(phase_name: String, elapsed_seconds: float) -> void:
	var safe_name := phase_name.strip_edges().to_lower()
	if safe_name.is_empty() or phase_timestamps.has(safe_name):
		return
	phase_timestamps[safe_name] = _seconds(elapsed_seconds)


func mark_launch(elapsed_seconds: float) -> void:
	var elapsed := _seconds(elapsed_seconds)
	time_to_launch_seconds = elapsed
	assembly_time_seconds = elapsed
	mark_phase("prepared", elapsed)


func set_assembly_time(elapsed_seconds: float) -> void:
	assembly_time_seconds = _seconds(elapsed_seconds)


func record_trajectory_sample(
	time_normalized: float,
	position_normalized: Vector3,
	rotation_normalized: float = 0.0,
	phase_name: String = ""
) -> void:
	append_trajectory_sample({
		"t": time_normalized,
		"position": position_normalized,
		"rotation": rotation_normalized,
		"phase": phase_name
	})


func append_trajectory_sample(sample: Dictionary) -> void:
	if trajectory.size() >= MAX_TRAJECTORY_SAMPLES:
		return
	trajectory.append({
		"t": _normalized(float(sample.get("t", sample.get("time", 0.0)))),
		"position": _normalized_vector3_dictionary(sample.get("position", {})),
		"rotation": _normalized(float(sample.get("rotation", sample.get("rotation_normalized", 0.0)))),
		"phase": String(sample.get("phase", "")).to_lower()
	})


func finish_flight(summary: Dictionary) -> void:
	max_height = _normalized(float(summary.get("max_height_normalized", summary.get("max_height", 0.0))))
	time_to_apex_seconds = _optional_seconds(summary.get("time_to_apex_seconds", summary.get("time_to_apex", -1.0)))
	lateral_displacement = _normalized(float(summary.get(
		"lateral_displacement_normalized",
		summary.get("lateral_displacement", summary.get("horizontal_displacement", 0.0))
	)))
	total_rotation = _normalized(float(summary.get(
		"total_rotation_normalized",
		summary.get("total_rotation", summary.get("rotation_count", 0.0))
	)))
	impact_position = _normalized_vector3_dictionary(summary.get("impact_position", impact_position))
	flight_duration_seconds = _seconds(float(summary.get("flight_duration_seconds", summary.get("flight_duration", 0.0))))

	var source_trajectory: Variant = summary.get("trajectory", summary.get("samples", []))
	if typeof(source_trajectory) == TYPE_ARRAY and not (source_trajectory as Array).is_empty():
		trajectory = _normalize_trajectory(source_trajectory)

	var summary_phases: Variant = summary.get("phase_timestamps", summary.get("state_timestamps", {}))
	if typeof(summary_phases) == TYPE_DICTIONARY:
		for raw_phase: Variant in (summary_phases as Dictionary).keys():
			mark_phase(String(raw_phase), float((summary_phases as Dictionary)[raw_phase]))

	completed_at_unix = Time.get_unix_time_from_system()
	completed_at_utc = Time.get_datetime_string_from_system(true, false)
	flight_completed = true


func mark_retry(retry_delay_seconds: float, change_count: int) -> void:
	launched_again = true
	time_to_next_attempt_seconds = _seconds(retry_delay_seconds)
	changes_after_flight = maxi(0, change_count)


func set_changes_after_flight(change_count: int) -> void:
	changes_after_flight = maxi(0, change_count)


func increment_changes_after_flight() -> void:
	changes_after_flight += 1


func is_valid() -> bool:
	return not session_id.is_empty() and not attempt_id.is_empty()


func is_complete() -> bool:
	return is_valid() and flight_completed


func snapshot() -> Dictionary:
	var fin_fields := _fin_telemetry_fields()
	var output := {
		"schema_version": SCHEMA_VERSION,
		"session_id": session_id,
		"attempt_id": attempt_id,
		"timestamp_utc": timestamp_utc,
		"timestamp_unix": timestamp_unix,
		"completed_at_utc": completed_at_utc,
		"completed_at_unix": completed_at_unix,
		"assembly_time_seconds": assembly_time_seconds,
		"first_piece_touched": first_piece_touched,
		"interaction_order": interaction_order,
		"interactions": interactions,
		"fin_positions": fin_fields.get("positions", []),
		"fin_angles": fin_fields.get("angles", []),
		"fin_heights": fin_fields.get("heights", []),
		"fin_attachment_quality": fin_fields.get("attachments", []),
		"cone_alignment": _configuration_cone_alignment(),
		"water_level": _normalized(float(configuration_snapshot.get("water_level", 0.0))),
		"energy_level": _normalized(float(configuration_snapshot.get("energy_level", 0.0))),
		"time_to_launch_seconds": time_to_launch_seconds,
		"trajectory_space": "attempt_local_normalized",
		"trajectory": trajectory,
		"max_height": max_height,
		"time_to_apex_seconds": time_to_apex_seconds,
		"lateral_displacement": lateral_displacement,
		"total_rotation": total_rotation,
		"impact_position": impact_position,
		"flight_duration_seconds": flight_duration_seconds,
		"changes_after_flight": changes_after_flight,
		"time_to_next_attempt_seconds": time_to_next_attempt_seconds,
		"launched_again": launched_again,
		"wind_seed": wind_seed,
		"phase_timestamps": phase_timestamps,
		"rocket_configuration": configuration_snapshot,
		"assembly_metrics": metrics_snapshot,
		"flight_completed": flight_completed
	}
	return json_safe(output)


func to_dict() -> Dictionary:
	return snapshot()


func apply_snapshot(data: Dictionary) -> bool:
	reset()
	session_id = String(data.get("session_id", "")).strip_edges()
	attempt_id = String(data.get("attempt_id", "")).strip_edges()
	timestamp_utc = String(data.get("timestamp_utc", ""))
	timestamp_unix = _seconds(float(data.get("timestamp_unix", 0.0)))
	completed_at_utc = String(data.get("completed_at_utc", ""))
	completed_at_unix = _seconds(float(data.get("completed_at_unix", 0.0)))
	assembly_time_seconds = _seconds(float(data.get("assembly_time_seconds", 0.0)))
	first_piece_touched = String(data.get("first_piece_touched", ""))
	interaction_order = _string_array(data.get("interaction_order", []))
	interactions = _dictionary_array(data.get("interactions", []))
	configuration_snapshot = _safe_dictionary(data.get("rocket_configuration", {}))
	metrics_snapshot = _safe_dictionary(data.get("assembly_metrics", {}))
	wind_seed = int(data.get("wind_seed", 0))
	phase_timestamps.clear()
	var phases_value: Variant = data.get("phase_timestamps", {})
	if typeof(phases_value) == TYPE_DICTIONARY:
		for raw_phase: Variant in (phases_value as Dictionary).keys():
			mark_phase(String(raw_phase), float((phases_value as Dictionary)[raw_phase]))
	time_to_launch_seconds = _optional_seconds(data.get("time_to_launch_seconds", -1.0))
	trajectory.clear()
	var trajectory_value: Variant = data.get("trajectory", [])
	if typeof(trajectory_value) == TYPE_ARRAY:
		for sample: Variant in trajectory_value:
			if typeof(sample) == TYPE_DICTIONARY:
				append_trajectory_sample(sample)
	max_height = _normalized(float(data.get("max_height", 0.0)))
	time_to_apex_seconds = _optional_seconds(data.get("time_to_apex_seconds", -1.0))
	lateral_displacement = _normalized(float(data.get("lateral_displacement", 0.0)))
	total_rotation = _normalized(float(data.get("total_rotation", 0.0)))
	impact_position = _normalized_vector3_dictionary(data.get("impact_position", {}))
	flight_duration_seconds = _seconds(float(data.get("flight_duration_seconds", 0.0)))
	changes_after_flight = maxi(0, int(data.get("changes_after_flight", 0)))
	time_to_next_attempt_seconds = _optional_seconds(data.get("time_to_next_attempt_seconds", -1.0))
	launched_again = bool(data.get("launched_again", false))
	flight_completed = bool(data.get("flight_completed", false))
	return is_valid()


static func from_snapshot(data: Dictionary) -> RefCounted:
	var record: RefCounted = load("res://scripts/telemetry/attempt_record.gd").new()
	record.apply_snapshot(data)
	return record


static func json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING:
			return value
		TYPE_FLOAT:
			var number := float(value)
			return number if is_finite(number) else 0.0
		TYPE_STRING_NAME:
			return String(value)
		TYPE_VECTOR2:
			var vector2_value: Vector2 = value
			return {"x": _safe_number(vector2_value.x), "y": _safe_number(vector2_value.y)}
		TYPE_VECTOR2I:
			var vector2i_value: Vector2i = value
			return {"x": vector2i_value.x, "y": vector2i_value.y}
		TYPE_VECTOR3:
			var vector3_value: Vector3 = value
			return {
				"x": _safe_number(vector3_value.x),
				"y": _safe_number(vector3_value.y),
				"z": _safe_number(vector3_value.z)
			}
		TYPE_VECTOR3I:
			var vector3i_value: Vector3i = value
			return {"x": vector3i_value.x, "y": vector3i_value.y, "z": vector3i_value.z}
		TYPE_COLOR:
			var color_value: Color = value
			return {
				"r": _safe_number(color_value.r),
				"g": _safe_number(color_value.g),
				"b": _safe_number(color_value.b),
				"a": _safe_number(color_value.a)
			}
		TYPE_ARRAY:
			var output_array: Array = []
			for item: Variant in value:
				output_array.append(json_safe(item))
			return output_array
		TYPE_DICTIONARY:
			var output_dictionary: Dictionary = {}
			for key: Variant in (value as Dictionary).keys():
				output_dictionary[String(key)] = json_safe((value as Dictionary)[key])
			return output_dictionary
		_:
			return String(value)


static func _safe_number(value: float) -> float:
	return value if is_finite(value) else 0.0


func _snapshot_from(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return _safe_dictionary(value)
	if value != null and value.has_method("snapshot"):
		var snapshot_value: Variant = value.call("snapshot")
		if typeof(snapshot_value) == TYPE_DICTIONARY:
			return _safe_dictionary(snapshot_value)
	return {}


func _fin_telemetry_fields() -> Dictionary:
	var positions: Array[Dictionary] = []
	var angles: Array[Dictionary] = []
	var heights: Array[Dictionary] = []
	var attachments: Array[Dictionary] = []
	var raw_fins: Variant = configuration_snapshot.get("fins", [])
	if typeof(raw_fins) == TYPE_ARRAY:
		for raw_fin: Variant in raw_fins:
			if typeof(raw_fin) != TYPE_DICTIONARY:
				continue
			var fin: Dictionary = raw_fin
			if not bool(fin.get("attached", false)):
				continue
			var fin_id := String(fin.get("fin_id", ""))
			positions.append({
				"fin_id": fin_id,
				"angular_position": _normalized(float(fin.get("angular_position", 0.0)))
			})
			angles.append({
				"fin_id": fin_id,
				"tilt": _normalized_signed(float(fin.get("tilt", 0.0))),
				"orientation": _normalized_signed(float(fin.get("orientation", 0.0)))
			})
			heights.append({
				"fin_id": fin_id,
				"height": _normalized(float(fin.get("height", 0.0)))
			})
			attachments.append({
				"fin_id": fin_id,
				"quality": _normalized(float(fin.get("attachment_quality", 0.0))),
				"fixed": bool(fin.get("fixed", false)),
				"reposition_count": maxi(0, int(fin.get("reposition_count", 0)))
			})
	return {
		"positions": positions,
		"angles": angles,
		"heights": heights,
		"attachments": attachments
	}


func _configuration_cone_alignment() -> float:
	if configuration_snapshot.has("cone_alignment"):
		return _normalized(float(configuration_snapshot.get("cone_alignment", 0.0)))
	var cone_value: Variant = configuration_snapshot.get("cone", {})
	if typeof(cone_value) != TYPE_DICTIONARY:
		return 0.0
	var cone: Dictionary = cone_value
	if not bool(cone.get("present", false)):
		return 0.0
	var centering := _normalized(float(cone.get("centering", 0.0)))
	var deviation := absf(_normalized_signed(float(cone.get("angular_deviation", 0.0))))
	return _normalized(centering * (1.0 - deviation))


func _normalize_trajectory(raw_trajectory: Array) -> Array[Dictionary]:
	var raw_samples: Array[Dictionary] = []
	var stride := maxi(1, ceili(float(raw_trajectory.size()) / float(MAX_TRAJECTORY_SAMPLES)))
	for index: int in range(0, raw_trajectory.size(), stride):
		var item: Variant = raw_trajectory[index]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var sample: Dictionary = item
		raw_samples.append({
			"t": _finite(float(sample.get("t", sample.get("time", 0.0)))),
			"position": _raw_vector3(sample.get("position", {})),
			"rotation": _normalized(float(sample.get(
				"rotation_normalized",
				sample.get("rotation", sample.get("angular_speed", 0.0))
			))),
			"phase": String(sample.get("phase", sample.get("state", ""))).to_lower()
		})
	if raw_samples.is_empty():
		return []

	var origin: Vector3 = raw_samples[0]["position"]
	var max_time := 0.0
	var spatial_scale := 0.001
	for sample: Dictionary in raw_samples:
		max_time = maxf(max_time, float(sample["t"]))
		var delta: Vector3 = sample["position"] - origin
		spatial_scale = maxf(spatial_scale, absf(delta.x))
		spatial_scale = maxf(spatial_scale, absf(delta.y))
		spatial_scale = maxf(spatial_scale, absf(delta.z))
	max_time = maxf(max_time, 0.001)

	var output: Array[Dictionary] = []
	for sample: Dictionary in raw_samples:
		var delta: Vector3 = (sample["position"] as Vector3) - origin
		output.append({
			"t": _normalized(float(sample["t"]) / max_time),
			"position": {
				"x": _normalized_signed(delta.x / spatial_scale),
				"y": _normalized_signed(delta.y / spatial_scale),
				"z": _normalized_signed(delta.z / spatial_scale)
			},
			"rotation": float(sample["rotation"]),
			"phase": String(sample["phase"])
		})
	return output


func _raw_vector3(value: Variant) -> Vector3:
	if typeof(value) == TYPE_VECTOR3:
		var vector: Vector3 = value
		return Vector3(_finite(vector.x), _finite(vector.y), _finite(vector.z))
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = value
		return Vector3(
			_finite(float(dictionary.get("x", 0.0))),
			_finite(float(dictionary.get("y", 0.0))),
			_finite(float(dictionary.get("z", 0.0)))
		)
	return Vector3.ZERO


func _normalized_vector3_dictionary(value: Variant) -> Dictionary:
	var vector := _raw_vector3(value)
	return {
		"x": _normalized_signed(vector.x),
		"y": _normalized_signed(vector.y),
		"z": _normalized_signed(vector.z)
	}


func _safe_dictionary(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var safe_value: Variant = json_safe(value)
	return safe_value if typeof(safe_value) == TYPE_DICTIONARY else {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item: Variant in value:
		if typeof(item) == TYPE_DICTIONARY:
			output.append(_safe_dictionary(item))
	return output


func _string_array(value: Variant) -> Array[String]:
	var output: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item: Variant in value:
		output.append(String(item))
	return output


func _normalized(value: float) -> float:
	return clampf(_finite(value), 0.0, 1.0)


func _normalized_signed(value: float) -> float:
	return clampf(_finite(value), -1.0, 1.0)


func _seconds(value: float) -> float:
	return snappedf(maxf(0.0, _finite(value)), 0.001)


func _optional_seconds(value: Variant) -> float:
	var number := _finite(float(value))
	return -1.0 if number < 0.0 else _seconds(number)


func _finite(value: float) -> float:
	return value if is_finite(value) else 0.0
