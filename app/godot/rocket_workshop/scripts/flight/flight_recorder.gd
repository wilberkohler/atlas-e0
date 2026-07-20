extends RefCounted
class_name FlightRecorder

var launch_id: int = 0
var session_id: String = ""
var flight_seed: int = 0
var parameters_snapshot: Dictionary = {}
var launch_time: float = 0.0
var state_timestamps: Dictionary = {}
var samples: Array[Dictionary] = []
var max_height: float = 0.0
var horizontal_displacement: float = 0.0
var max_angular_velocity: float = 0.0
var mean_angular_velocity: float = 0.0
var rotation_count: float = 0.0
var impact_position: Vector3 = Vector3.ZERO

var _start_position: Vector3 = Vector3.ZERO
var _angular_total: float = 0.0
var _last_sample_time: float = 0.0


func begin(new_launch_id: int, new_session_id: String, parameters: Resource, start_position: Vector3) -> void:
	launch_id = new_launch_id
	session_id = new_session_id
	flight_seed = int(parameters.flight_seed)
	parameters_snapshot = parameters.to_dict()
	launch_time = Time.get_unix_time_from_system()
	state_timestamps.clear()
	samples.clear()
	max_height = start_position.y
	horizontal_displacement = 0.0
	max_angular_velocity = 0.0
	mean_angular_velocity = 0.0
	rotation_count = 0.0
	impact_position = start_position
	_start_position = start_position
	_angular_total = 0.0
	_last_sample_time = 0.0


func mark_state(state_name: String, time_seconds: float) -> void:
	if not state_timestamps.has(state_name):
		state_timestamps[state_name] = snappedf(time_seconds, 0.001)


func sample(time_seconds: float, position: Vector3, velocity: Vector3, angular_velocity: Vector3) -> void:
	var angular_speed: float = angular_velocity.length()
	var sample_delta: float = maxf(0.0, time_seconds - _last_sample_time)
	_last_sample_time = time_seconds
	max_height = maxf(max_height, position.y)
	var horizontal_delta: Vector2 = Vector2(position.x - _start_position.x, position.z - _start_position.z)
	horizontal_displacement = maxf(horizontal_displacement, horizontal_delta.length())
	max_angular_velocity = maxf(max_angular_velocity, angular_speed)
	_angular_total += angular_speed
	mean_angular_velocity = _angular_total / float(maxi(1, samples.size() + 1))
	rotation_count += angular_speed * 0.159154943 * sample_delta
	impact_position = position
	samples.append({
		"t": snappedf(time_seconds, 0.001),
		"height": snappedf(position.y - _start_position.y, 0.001),
		"speed": snappedf(velocity.length(), 0.001),
		"angularSpeed": snappedf(angular_speed, 0.001),
		"position": _vec3(position)
	})


func finish(duration: float, position: Vector3) -> Dictionary:
	impact_position = position
	return {
		"launch_id": launch_id,
		"session_id": session_id,
		"flight_seed": flight_seed,
		"parameters_snapshot": parameters_snapshot,
		"launch_time": launch_time,
		"flight_duration": snappedf(duration, 0.001),
		"max_height": snappedf(max_height - _start_position.y, 0.001),
		"horizontal_displacement": snappedf(horizontal_displacement, 0.001),
		"max_angular_velocity": snappedf(max_angular_velocity, 0.001),
		"mean_angular_velocity": snappedf(mean_angular_velocity, 0.001),
		"rotation_count": snappedf(rotation_count, 0.001),
		"impact_position": _vec3(impact_position),
		"state_timestamps": state_timestamps,
		"samples": samples
	}


func height_graph(width: int = 28) -> String:
	return _graph("height", width)


func speed_graph(width: int = 28) -> String:
	return _graph("speed", width)


func _graph(key: String, width: int) -> String:
	if samples.is_empty():
		return ""
	var values: Array[float] = []
	var max_value: float = 0.001
	for sample_data: Dictionary in samples:
		var value: float = maxf(0.0, float(sample_data.get(key, 0.0)))
		values.append(value)
		max_value = maxf(max_value, value)
	var step: float = maxf(1.0, float(values.size()) / float(width))
	var bars := " ▁▂▃▄▅▆▇█"
	var output := ""
	var index := 0.0
	while index < values.size():
		var value_index: int = mini(values.size() - 1, int(index))
		var normalized: float = clampf(values[value_index] / max_value, 0.0, 1.0)
		var bar_index: int = mini(bars.length() - 1, int(round(normalized * float(bars.length() - 1))))
		output += bars.substr(bar_index, 1)
		index += step
	return output


func _vec3(value: Vector3) -> Dictionary:
	return {
		"x": snappedf(value.x, 0.001),
		"y": snappedf(value.y, 0.001),
		"z": snappedf(value.z, 0.001)
	}
