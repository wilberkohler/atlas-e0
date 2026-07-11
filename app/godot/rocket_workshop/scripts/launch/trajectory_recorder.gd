extends RefCounted
class_name VS1TrajectoryRecorder

## Records a compact, renderer-friendly trajectory and retains only the two
## latest attempts. Runtime data keeps Vector3 values; to_serializable() creates
## a JSON-safe copy for telemetry storage.

signal attempt_started(attempt_id: int, seed: int)
signal state_marked(state_name: StringName, elapsed: float)
signal sample_recorded(sample: Dictionary)
signal attempt_finished(summary: Dictionary)
signal history_changed(attempts: Array[Dictionary])

const MAX_ATTEMPTS: int = 2
const SAMPLE_INTERVAL: float = 1.0 / 30.0

var history: Array[Dictionary] = []
var current_attempt: Dictionary = {}

var _recording: bool = false
var _attempt_counter: int = 0
var _last_sample_time: float = -INF
var _last_rotation_time: float = 0.0
var _total_rotation: float = 0.0
var _start_position: Vector3 = Vector3.ZERO
var _apex_position: Vector3 = Vector3.ZERO
var _apex_elapsed: float = -1.0
var _max_height: float = 0.0
var _max_lateral_displacement: float = 0.0
var _max_spin: float = 0.0


func begin_attempt(config_snapshot: Dictionary, seed: int, metadata: Dictionary = {}) -> int:
	_attempt_counter += 1
	var requested_id: int = int(metadata.get("attempt_id", _attempt_counter))
	_attempt_counter = maxi(_attempt_counter, requested_id)
	current_attempt = {
		"attempt_id": requested_id,
		"seed": seed,
		"config": config_snapshot.duplicate(true),
		"metadata": metadata.duplicate(true),
		"state_timestamps": {},
		"state_events": [],
		"samples": [],
		"fail_safe_reason": &"",
	}
	_recording = true
	_last_sample_time = -INF
	_last_rotation_time = 0.0
	_total_rotation = 0.0
	_start_position = Vector3.ZERO
	_apex_position = Vector3.ZERO
	_apex_elapsed = -1.0
	_max_height = 0.0
	_max_lateral_displacement = 0.0
	_max_spin = 0.0
	attempt_started.emit(requested_id, seed)
	return requested_id


func mark_state(state_name: StringName, snapshot: Dictionary = {}) -> void:
	if not _recording:
		return
	var elapsed: float = float(snapshot.get("elapsed", 0.0))
	var timestamps: Dictionary = current_attempt["state_timestamps"]
	if not timestamps.has(state_name):
		timestamps[state_name] = elapsed
	var events: Array = current_attempt["state_events"]
	events.append({"state": state_name, "elapsed": elapsed})
	if state_name == &"APEX":
		_apex_position = _snapshot_position(snapshot)
		_apex_elapsed = elapsed
	elif state_name == &"IMPACT":
		current_attempt["impact_position"] = _snapshot_position(snapshot)
	state_marked.emit(state_name, elapsed)
	record_sample(snapshot, true)


func record_sample(snapshot: Dictionary, force: bool = false) -> void:
	if not _recording:
		return
	var elapsed: float = maxf(0.0, float(snapshot.get("elapsed", 0.0)))
	if not force and elapsed - _last_sample_time + 0.000001 < SAMPLE_INTERVAL:
		return

	var position: Vector3 = _snapshot_position(snapshot)
	var velocity: Vector3 = _snapshot_vector(snapshot, "velocity")
	var spin: Vector3 = _snapshot_vector(snapshot, "angular_velocity")
	if not _is_finite_vector(position) or not _is_finite_vector(velocity) or not _is_finite_vector(spin):
		current_attempt["fail_safe_reason"] = &"recorder_rejected_non_finite_sample"
		return

	var samples: Array = current_attempt["samples"]
	if samples.is_empty():
		_start_position = position
		_last_rotation_time = elapsed
	var rotation_delta: float = maxf(0.0, elapsed - _last_rotation_time)
	_last_rotation_time = elapsed
	_total_rotation += spin.length() * rotation_delta
	_last_sample_time = elapsed

	var relative_height: float = position.y - _start_position.y
	var lateral := Vector2(position.x - _start_position.x, position.z - _start_position.z)
	_max_height = maxf(_max_height, relative_height)
	_max_lateral_displacement = maxf(_max_lateral_displacement, lateral.length())
	_max_spin = maxf(_max_spin, spin.length())
	if _apex_elapsed < 0.0 and relative_height >= _max_height:
		_apex_position = position

	var sample := {
		"elapsed": elapsed,
		"state": StringName(snapshot.get("state", &"UNKNOWN")),
		"position": position,
		"velocity": velocity,
		"angular_velocity": spin,
		"jet_amount": clampf(float(snapshot.get("jet_amount", 0.0)), 0.0, 1.0),
		"stability_score": clampf(float(snapshot.get("stability_score", 0.0)), 0.0, 1.0),
	}
	samples.append(sample)
	sample_recorded.emit(sample.duplicate(true))


func note_fail_safe(reason: StringName) -> void:
	if _recording:
		current_attempt["fail_safe_reason"] = reason


func finish_attempt(final_snapshot: Dictionary = {}, metadata: Dictionary = {}) -> Dictionary:
	if not _recording:
		return {}
	if not final_snapshot.is_empty():
		record_sample(final_snapshot, true)
	var samples: Array = current_attempt["samples"]
	var final_position: Vector3 = _snapshot_position(final_snapshot)
	if final_snapshot.is_empty() and not samples.is_empty():
		final_position = samples.back().get("position", _start_position)
	if _apex_elapsed < 0.0:
		_apex_elapsed = _time_at_highest_sample(samples)
	var duration: float = float(final_snapshot.get("elapsed", _last_sample_time if is_finite(_last_sample_time) else 0.0))
	var height_normalized: float = clampf(_max_height / 8.0, 0.0, 1.0)
	var lateral_normalized: float = clampf(_max_lateral_displacement / 4.0, 0.0, 1.0)
	var rotation_normalized: float = clampf(_total_rotation / 4.0, 0.0, 1.0)

	var summary := {
		"attempt_id": int(current_attempt.get("attempt_id", 0)),
		"seed": int(current_attempt.get("seed", 0)),
		"config": current_attempt.get("config", {}).duplicate(true),
		"metadata": current_attempt.get("metadata", {}).duplicate(true),
		"completion_metadata": metadata.duplicate(true),
		"duration": duration,
		"flight_duration": duration,
		"flight_duration_seconds": duration,
		"max_height": _max_height,
		"max_height_normalized": height_normalized,
		"time_to_apex": maxf(0.0, _apex_elapsed),
		"time_to_apex_seconds": maxf(0.0, _apex_elapsed),
		"max_lateral_displacement": _max_lateral_displacement,
		"lateral_displacement": _max_lateral_displacement,
		"lateral_displacement_normalized": lateral_normalized,
		"max_spin": _max_spin,
		"total_rotation": _total_rotation,
		"total_rotation_normalized": rotation_normalized,
		"apex_position": _apex_position,
		"impact_position": final_position,
		"state_timestamps": current_attempt.get("state_timestamps", {}).duplicate(true),
		"phase_timestamps": current_attempt.get("state_timestamps", {}).duplicate(true),
		"state_events": current_attempt.get("state_events", []).duplicate(true),
		"samples": samples.duplicate(true),
		"fail_safe_reason": current_attempt.get("fail_safe_reason", &""),
	}
	_recording = false
	history.append(summary.duplicate(true))
	while history.size() > MAX_ATTEMPTS:
		history.pop_front()
	attempt_finished.emit(summary.duplicate(true))
	history_changed.emit(get_recent_attempts())
	return summary


func cancel_attempt() -> void:
	_recording = false
	current_attempt.clear()


func clear_history() -> void:
	history.clear()
	current_attempt.clear()
	_recording = false
	history_changed.emit([])


func is_recording() -> bool:
	return _recording


func get_recent_attempts() -> Array[Dictionary]:
	var copies: Array[Dictionary] = []
	for attempt: Dictionary in history:
		copies.append(attempt.duplicate(true))
	return copies


func get_current_points() -> PackedVector3Array:
	var points := PackedVector3Array()
	if not _recording:
		return points
	for sample: Dictionary in current_attempt.get("samples", []):
		points.append(sample.get("position", Vector3.ZERO))
	return points


func to_serializable() -> Dictionary:
	return {
		"attempts": _serialize_variant(get_recent_attempts()),
		"current_attempt": _serialize_variant(current_attempt) if _recording else {},
	}


static func _serialize_variant(value: Variant) -> Variant:
	if value is Vector3:
		return {"x": value.x, "y": value.y, "z": value.z}
	if value is Vector2:
		return {"x": value.x, "y": value.y}
	if value is StringName:
		return String(value)
	if value is Dictionary:
		var output: Dictionary = {}
		for key: Variant in value.keys():
			output[String(key)] = _serialize_variant(value[key])
		return output
	if value is Array:
		var output_array: Array = []
		for item: Variant in value:
			output_array.append(_serialize_variant(item))
		return output_array
	return value


func _snapshot_position(snapshot: Dictionary) -> Vector3:
	var value: Variant = snapshot.get("position", Vector3.ZERO)
	if value is Vector3:
		return value
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO


func _snapshot_vector(snapshot: Dictionary, key: String) -> Vector3:
	var value: Variant = snapshot.get(key, Vector3.ZERO)
	if value is Vector3:
		return value
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO


func _time_at_highest_sample(samples: Array) -> float:
	var best_height: float = -INF
	var best_time: float = 0.0
	for sample: Dictionary in samples:
		var position: Vector3 = sample.get("position", _start_position)
		if position.y > best_height:
			best_height = position.y
			best_time = float(sample.get("elapsed", 0.0))
			_apex_position = position
	return best_time


func _is_finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
