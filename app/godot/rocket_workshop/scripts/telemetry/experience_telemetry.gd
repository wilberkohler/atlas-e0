extends Node
class_name VS1ExperienceTelemetry

signal session_started(session_id: String)
signal attempt_started(attempt_snapshot: Dictionary)
signal interaction_recorded(event_snapshot: Dictionary)
signal attempt_completed(attempt_snapshot: Dictionary)
signal persisted(path: String, attempt_count: int)
signal telemetry_error(operation: String, detail: String)

const SCHEMA_VERSION := 1
const EXPERIENCE_ID := "vertical_slice_pet_v1"
const STORAGE_DIRECTORY := "user://atlas_e0/vertical_slice_pet_v1"
const ATTEMPT_HISTORY_PATH := STORAGE_DIRECTORY + "/attempt_history.json"
const ATTEMPT_HISTORY_BACKUP_PATH := ATTEMPT_HISTORY_PATH + ".bak"
const AttemptRecordScript := preload("res://scripts/telemetry/attempt_record.gd")

var session_id: String = ""
var session_started_at_unix: float = 0.0
var current_attempt: RefCounted = null
var persisted_attempts: Array[Dictionary] = []
var last_error: String = ""

var _session_started_ticks_msec: int = 0
var _attempt_started_ticks_msec: int = 0
var _attempt_sequence: int = 0
var _last_completed_ticks_msec: int = -1
var _last_completed_attempt_id: String = ""
var _changes_after_flight: int = 0
var _last_read_error: String = ""
var _loaded_from_backup: bool = false


func _ready() -> void:
	load_persisted_history()
	if session_id.is_empty():
		start_session()


func start_session(requested_session_id: String = "") -> String:
	session_id = requested_session_id.strip_edges()
	if session_id.is_empty():
		session_id = _new_id("session")
	session_started_at_unix = Time.get_unix_time_from_system()
	_session_started_ticks_msec = Time.get_ticks_msec()
	_attempt_started_ticks_msec = _session_started_ticks_msec
	_attempt_sequence = 0
	_last_completed_ticks_msec = -1
	_last_completed_attempt_id = ""
	_changes_after_flight = 0
	current_attempt = null
	session_started.emit(session_id)
	return session_id


func begin_attempt(
	configuration: Variant,
	metrics: Dictionary = {},
	wind_seed: int = 0,
	requested_attempt_id: String = ""
) -> RefCounted:
	if session_id.is_empty():
		start_session()
	if not _last_completed_attempt_id.is_empty():
		mark_retry_started(_changes_after_flight)

	_attempt_sequence += 1
	var attempt_id := requested_attempt_id.strip_edges()
	if attempt_id.is_empty():
		attempt_id = "%s_attempt_%03d" % [session_id, _attempt_sequence]
	current_attempt = AttemptRecordScript.new()
	current_attempt.call("begin", session_id, attempt_id, configuration, metrics, wind_seed)
	_attempt_started_ticks_msec = Time.get_ticks_msec()
	_changes_after_flight = 0
	var attempt_snapshot: Dictionary = current_attempt.call("snapshot")
	attempt_started.emit(attempt_snapshot)
	return current_attempt


func record_interaction(piece_id: String, action: String, payload: Dictionary = {}) -> bool:
	if not _has_current_attempt():
		return false
	current_attempt.call("record_interaction", piece_id, action, _attempt_elapsed_seconds(), payload)
	var attempt_snapshot: Dictionary = current_attempt.call("snapshot")
	var interactions: Array = attempt_snapshot.get("interactions", [])
	if not interactions.is_empty():
		interaction_recorded.emit(interactions.back())
	return true


func mark_phase(phase_name: String) -> bool:
	if not _has_current_attempt():
		return false
	current_attempt.call("mark_phase", phase_name, _attempt_elapsed_seconds())
	return true


func mark_launch() -> bool:
	if not _has_current_attempt():
		return false
	current_attempt.call("mark_launch", _attempt_elapsed_seconds())
	return true


func record_trajectory_sample(
	time_normalized: float,
	position_normalized: Vector3,
	rotation_normalized: float = 0.0,
	phase_name: String = ""
) -> bool:
	if not _has_current_attempt():
		return false
	current_attempt.call(
		"record_trajectory_sample",
		time_normalized,
		position_normalized,
		rotation_normalized,
		phase_name
	)
	return true


func complete_attempt(flight_summary: Dictionary, change_count: int = 0) -> Dictionary:
	if not _has_current_attempt():
		_report_error("complete_attempt", "no active attempt")
		return {}
	var before_completion: Dictionary = current_attempt.call("snapshot")
	if float(before_completion.get("time_to_launch_seconds", -1.0)) < 0.0:
		current_attempt.call("mark_launch", _attempt_elapsed_seconds())
	current_attempt.call("set_changes_after_flight", maxi(0, change_count))
	current_attempt.call("finish_flight", flight_summary)
	var completed_snapshot: Dictionary = current_attempt.call("snapshot")
	_store_attempt(completed_snapshot)
	_last_completed_ticks_msec = Time.get_ticks_msec()
	_last_completed_attempt_id = String(completed_snapshot.get("attempt_id", ""))
	_changes_after_flight = maxi(0, change_count)
	current_attempt = null
	if not save_persisted_history():
		# Persistence failures are reported, but the in-memory record remains available.
		pass
	attempt_completed.emit(completed_snapshot)
	return completed_snapshot


func record_change_after_flight() -> int:
	if _last_completed_attempt_id.is_empty():
		return 0
	_changes_after_flight += 1
	_update_last_completed_change_count()
	save_persisted_history()
	return _changes_after_flight


func mark_retry_started(change_count: int = -1) -> bool:
	if _last_completed_attempt_id.is_empty():
		return false
	var index := _find_attempt_index(session_id, _last_completed_attempt_id)
	if index < 0:
		return false
	var record: RefCounted = AttemptRecordScript.from_snapshot(persisted_attempts[index])
	var delay_seconds := 0.0
	if _last_completed_ticks_msec >= 0:
		delay_seconds = float(Time.get_ticks_msec() - _last_completed_ticks_msec) / 1000.0
	else:
		var completed_unix := float(persisted_attempts[index].get("completed_at_unix", 0.0))
		if completed_unix > 0.0:
			delay_seconds = maxf(0.0, Time.get_unix_time_from_system() - completed_unix)
	var final_change_count := _changes_after_flight if change_count < 0 else maxi(0, change_count)
	record.call("mark_retry", delay_seconds, final_change_count)
	persisted_attempts[index] = record.call("snapshot")
	_last_completed_attempt_id = ""
	_changes_after_flight = 0
	return save_persisted_history()


func abandon_current_attempt() -> void:
	current_attempt = null
	_attempt_started_ticks_msec = Time.get_ticks_msec()


func current_attempt_snapshot() -> Dictionary:
	return {} if current_attempt == null else current_attempt.call("snapshot")


func get_all_attempts() -> Array[Dictionary]:
	return persisted_attempts.duplicate(true)


func get_last_attempts(limit: int = 2) -> Array[Dictionary]:
	var safe_limit := maxi(0, limit)
	var start_index := maxi(0, persisted_attempts.size() - safe_limit)
	var output: Array[Dictionary] = []
	for index: int in range(start_index, persisted_attempts.size()):
		output.append(persisted_attempts[index].duplicate(true))
	return output


func snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"experience_id": EXPERIENCE_ID,
		"session_id": session_id,
		"session_started_at_unix": session_started_at_unix,
		"session_elapsed_seconds": _session_elapsed_seconds(),
		"current_attempt": current_attempt_snapshot(),
		"attempt_count": persisted_attempts.size(),
		"last_two_attempts": get_last_attempts(2),
		"storage_directory": STORAGE_DIRECTORY,
		"attempt_history_path": ATTEMPT_HISTORY_PATH,
		"last_error": last_error
	}


func load_persisted_history() -> bool:
	persisted_attempts.clear()
	_loaded_from_backup = false
	if not _ensure_storage_directory():
		return false

	var has_primary := FileAccess.file_exists(ATTEMPT_HISTORY_PATH)
	var has_backup := FileAccess.file_exists(ATTEMPT_HISTORY_BACKUP_PATH)
	if not has_primary and not has_backup:
		last_error = ""
		return true

	var document: Dictionary = {}
	if has_primary:
		document = _read_document(ATTEMPT_HISTORY_PATH)
	if document.is_empty() and has_backup:
		var primary_error := _last_read_error
		document = _read_document(ATTEMPT_HISTORY_BACKUP_PATH)
		if not document.is_empty():
			_loaded_from_backup = true
			last_error = "primary history unavailable; recovered backup"
			push_warning("VS1 telemetry: %s (%s)" % [last_error, primary_error])
	if document.is_empty():
		_report_error("load", _last_read_error if not _last_read_error.is_empty() else "invalid history document")
		return false

	var attempts_value: Variant = document.get("attempts", [])
	if typeof(attempts_value) != TYPE_ARRAY:
		_report_error("load", "history document has no attempts array")
		return false
	for item: Variant in attempts_value:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var record: RefCounted = AttemptRecordScript.from_snapshot(item)
		if bool(record.call("is_valid")):
			persisted_attempts.append(record.call("snapshot"))
	if not _loaded_from_backup:
		last_error = ""
	return true


func save_persisted_history() -> bool:
	if not _ensure_storage_directory():
		return false
	var document := {
		"schema_version": SCHEMA_VERSION,
		"experience_id": EXPERIENCE_ID,
		"value_policy": "normalized_fictional_internal_values",
		"updated_at_utc": Time.get_datetime_string_from_system(true, false),
		"attempts": persisted_attempts
	}
	var serialized := JSON.stringify(AttemptRecordScript.json_safe(document), "\t", false, true)
	var temporary_path := ATTEMPT_HISTORY_PATH + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		_report_error("write", "cannot open temporary file (error %d)" % FileAccess.get_open_error())
		return false
	file.store_string(serialized)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		_report_error("write", "temporary file write failed (error %d)" % write_error)
		return false
	if not _replace_history_file(temporary_path):
		return false
	last_error = ""
	persisted.emit(ATTEMPT_HISTORY_PATH, persisted_attempts.size())
	return true


func _store_attempt(attempt_snapshot: Dictionary) -> void:
	var session_value := String(attempt_snapshot.get("session_id", ""))
	var attempt_value := String(attempt_snapshot.get("attempt_id", ""))
	var index := _find_attempt_index(session_value, attempt_value)
	if index >= 0:
		persisted_attempts[index] = attempt_snapshot.duplicate(true)
	else:
		persisted_attempts.append(attempt_snapshot.duplicate(true))


func _find_attempt_index(session_value: String, attempt_value: String) -> int:
	for index: int in range(persisted_attempts.size()):
		var candidate: Dictionary = persisted_attempts[index]
		if (
			String(candidate.get("session_id", "")) == session_value
			and String(candidate.get("attempt_id", "")) == attempt_value
		):
			return index
	return -1


func _update_last_completed_change_count() -> void:
	var index := _find_attempt_index(session_id, _last_completed_attempt_id)
	if index < 0:
		return
	var record: RefCounted = AttemptRecordScript.from_snapshot(persisted_attempts[index])
	record.call("set_changes_after_flight", _changes_after_flight)
	persisted_attempts[index] = record.call("snapshot")


func _read_document(path: String) -> Dictionary:
	_last_read_error = ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_last_read_error = "cannot open %s (error %d)" % [path, FileAccess.get_open_error()]
		return {}
	var text := file.get_as_text()
	file.close()
	if text.strip_edges().is_empty():
		_last_read_error = "%s is empty" % path
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_last_read_error = "%s contains invalid JSON" % path
		return {}
	return parsed


func _ensure_storage_directory() -> bool:
	var absolute_directory := ProjectSettings.globalize_path(STORAGE_DIRECTORY)
	var error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if error != OK:
		_report_error("mkdir", "cannot create storage directory (error %d)" % error)
		return false
	return true


func _replace_history_file(temporary_path: String) -> bool:
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var target_absolute := ProjectSettings.globalize_path(ATTEMPT_HISTORY_PATH)
	var backup_absolute := ProjectSettings.globalize_path(ATTEMPT_HISTORY_BACKUP_PATH)
	var had_primary := FileAccess.file_exists(ATTEMPT_HISTORY_PATH)

	if had_primary:
		if _loaded_from_backup:
			var corrupt_path := "%s.corrupt_%d" % [target_absolute, Time.get_ticks_usec()]
			var corrupt_error := DirAccess.rename_absolute(target_absolute, corrupt_path)
			if corrupt_error != OK:
				_report_error("replace", "cannot preserve corrupt primary (error %d)" % corrupt_error)
				return false
		else:
			if FileAccess.file_exists(ATTEMPT_HISTORY_BACKUP_PATH):
				var remove_error := DirAccess.remove_absolute(backup_absolute)
				if remove_error != OK:
					_report_error("replace", "cannot rotate history backup (error %d)" % remove_error)
					return false
			var backup_error := DirAccess.rename_absolute(target_absolute, backup_absolute)
			if backup_error != OK:
				_report_error("replace", "cannot create history backup (error %d)" % backup_error)
				return false

	var replace_error := DirAccess.rename_absolute(temporary_absolute, target_absolute)
	if replace_error != OK:
		if not _loaded_from_backup and FileAccess.file_exists(ATTEMPT_HISTORY_BACKUP_PATH):
			DirAccess.rename_absolute(backup_absolute, target_absolute)
		_report_error("replace", "cannot activate history file (error %d)" % replace_error)
		return false
	_loaded_from_backup = false
	return true


func _has_current_attempt() -> bool:
	return current_attempt != null and bool(current_attempt.call("is_valid"))


func _attempt_elapsed_seconds() -> float:
	return maxf(0.0, float(Time.get_ticks_msec() - _attempt_started_ticks_msec) / 1000.0)


func _session_elapsed_seconds() -> float:
	return maxf(0.0, float(Time.get_ticks_msec() - _session_started_ticks_msec) / 1000.0)


func _report_error(operation: String, detail: String) -> void:
	last_error = "%s: %s" % [operation, detail]
	push_warning("VS1 telemetry %s" % last_error)
	telemetry_error.emit(operation, detail)


func _new_id(prefix: String) -> String:
	return "%s_%d_%d" % [prefix, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
