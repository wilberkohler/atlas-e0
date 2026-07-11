extends RefCounted
class_name VS1AttemptHistory

signal changed(snapshot: Dictionary)

const VISUAL_CAPACITY := 2
const AttemptRecordScript := preload("res://scripts/telemetry/attempt_record.gd")

var _attempts: Array[RefCounted] = []


func clear(emit_change: bool = true) -> void:
	_attempts.clear()
	if emit_change:
		changed.emit(snapshot())


func add_attempt(record: Variant) -> bool:
	var record_snapshot := _record_snapshot(record)
	if record_snapshot.is_empty():
		return false
	var stored: RefCounted = AttemptRecordScript.from_snapshot(record_snapshot)
	if not bool(stored.call("is_valid")):
		return false

	var existing_index := _find_index(
		String(record_snapshot.get("session_id", "")),
		String(record_snapshot.get("attempt_id", ""))
	)
	if existing_index >= 0:
		_attempts[existing_index] = stored
	else:
		_attempts.append(stored)
	while _attempts.size() > VISUAL_CAPACITY:
		_attempts.pop_front()
	changed.emit(snapshot())
	return true


func size() -> int:
	return _attempts.size()


func is_empty() -> bool:
	return _attempts.is_empty()


func latest() -> RefCounted:
	return null if _attempts.is_empty() else _attempts.back()


func previous() -> RefCounted:
	return null if _attempts.size() < 2 else _attempts[_attempts.size() - 2]


func latest_snapshot() -> Dictionary:
	var record := latest()
	return {} if record == null else _record_snapshot(record)


func previous_snapshot() -> Dictionary:
	var record := previous()
	return {} if record == null else _record_snapshot(record)


func get_visual_attempts() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for record: RefCounted in _attempts:
		output.append(_record_snapshot(record))
	return output


func get_visual_trajectories() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for index: int in range(_attempts.size()):
		var attempt := _record_snapshot(_attempts[index])
		output.append({
			"visual_index": index,
			"attempt_id": String(attempt.get("attempt_id", "")),
			"trajectory_space": String(attempt.get("trajectory_space", "attempt_local_normalized")),
			"trajectory": _dictionary_array(attempt.get("trajectory", [])),
			"max_height": float(attempt.get("max_height", 0.0)),
			"impact_position": _dictionary(attempt.get("impact_position", {}))
		})
	return output


func mark_latest_retried(retry_delay_seconds: float, change_count: int) -> bool:
	var record := latest()
	if record == null:
		return false
	record.call("mark_retry", retry_delay_seconds, change_count)
	changed.emit(snapshot())
	return true


func set_latest_change_count(change_count: int) -> bool:
	var record := latest()
	if record == null:
		return false
	record.call("set_changes_after_flight", change_count)
	changed.emit(snapshot())
	return true


func apply_snapshot(value: Variant, emit_change: bool = true) -> bool:
	var source: Variant = value
	if typeof(value) == TYPE_DICTIONARY:
		source = (value as Dictionary).get("attempts", [])
	if typeof(source) != TYPE_ARRAY:
		return false

	_attempts.clear()
	var source_array: Array = source
	var start_index := maxi(0, source_array.size() - VISUAL_CAPACITY)
	for index: int in range(start_index, source_array.size()):
		var item: Variant = source_array[index]
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var record: RefCounted = AttemptRecordScript.from_snapshot(item)
		if bool(record.call("is_valid")):
			_attempts.append(record)
	if emit_change:
		changed.emit(snapshot())
	return true


func snapshot() -> Dictionary:
	return {
		"visual_capacity": VISUAL_CAPACITY,
		"count": _attempts.size(),
		"attempts": get_visual_attempts()
	}


func to_dict() -> Dictionary:
	return snapshot()


func _find_index(session_id: String, attempt_id: String) -> int:
	for index: int in range(_attempts.size()):
		var candidate := _record_snapshot(_attempts[index])
		if (
			String(candidate.get("session_id", "")) == session_id
			and String(candidate.get("attempt_id", "")) == attempt_id
		):
			return index
	return -1


func _record_snapshot(record: Variant) -> Dictionary:
	if typeof(record) == TYPE_DICTIONARY:
		return (record as Dictionary).duplicate(true)
	if record != null and record.has_method("snapshot"):
		var value: Variant = record.call("snapshot")
		if typeof(value) == TYPE_DICTIONARY:
			return (value as Dictionary).duplicate(true)
	return {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for item: Variant in value:
		if typeof(item) == TYPE_DICTIONARY:
			output.append((item as Dictionary).duplicate(true))
	return output


func _dictionary(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}
