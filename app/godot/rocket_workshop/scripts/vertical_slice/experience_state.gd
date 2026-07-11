extends Node
class_name VS1ExperienceState

signal phase_changed(previous_phase: int, current_phase: int)
signal configuration_changed(snapshot: Dictionary)
signal visual_history_changed(snapshot: Dictionary)
signal attempt_started(attempt_id: String, wind_seed: int)
signal state_changed(snapshot: Dictionary)

enum Phase {
	WORKSHOP,
	TRANSITION_TO_FIELD,
	FIELD_TEST,
	REVIEW,
	TRANSITION_TO_WORKSHOP
}

const PHASE_NAMES := {
	Phase.WORKSHOP: "workshop",
	Phase.TRANSITION_TO_FIELD: "transition_to_field",
	Phase.FIELD_TEST: "field_test",
	Phase.REVIEW: "review",
	Phase.TRANSITION_TO_WORKSHOP: "transition_to_workshop"
}

const RocketConfigurationScript := preload("res://scripts/assembly/rocket_configuration.gd")
const AssemblyMetricsScript := preload("res://scripts/assembly/assembly_metrics.gd")
const AttemptHistoryScript := preload("res://scripts/telemetry/attempt_history.gd")

var configuration: RefCounted
var attempt_history: RefCounted
var session_id: String = ""
var current_attempt_id: String = ""
var current_phase: Phase = Phase.WORKSHOP
var attempt_number: int = 0
var current_wind_seed: int = 0
var keep_wind_for_comparison: bool = true
var changes_after_last_flight: int = 0
var revision: int = 0

var _last_completed_ticks_msec: int = -1


func _init() -> void:
	configuration = RocketConfigurationScript.new()
	attempt_history = AttemptHistoryScript.new()
	configuration.connect("changed", Callable(self, "_on_configuration_changed"))
	attempt_history.connect("changed", Callable(self, "_on_history_changed"))


func start_session(new_session_id: String = "", initial_wind_seed: int = -1) -> String:
	session_id = new_session_id.strip_edges()
	if session_id.is_empty():
		session_id = _new_id("session")
	current_attempt_id = ""
	current_phase = Phase.WORKSHOP
	attempt_number = 0
	current_wind_seed = initial_wind_seed if initial_wind_seed >= 0 else _derive_wind_seed(1)
	changes_after_last_flight = 0
	_last_completed_ticks_msec = -1
	configuration.call("reset", false)
	attempt_history.call("clear", false)
	_touch()
	configuration_changed.emit(configuration.call("snapshot"))
	visual_history_changed.emit(attempt_history.call("snapshot"))
	return session_id


func begin_attempt(requested_attempt_id: String = "", requested_wind_seed: int = -1) -> Dictionary:
	if session_id.is_empty():
		start_session()

	if not bool(attempt_history.call("is_empty")):
		var retry_delay := 0.0
		if _last_completed_ticks_msec >= 0:
			retry_delay = float(Time.get_ticks_msec() - _last_completed_ticks_msec) / 1000.0
		attempt_history.call("mark_latest_retried", retry_delay, changes_after_last_flight)

	attempt_number += 1
	current_attempt_id = requested_attempt_id.strip_edges()
	if current_attempt_id.is_empty():
		current_attempt_id = "%s_attempt_%03d" % [session_id, attempt_number]

	if requested_wind_seed >= 0:
		current_wind_seed = requested_wind_seed
	elif attempt_number == 1 or not keep_wind_for_comparison:
		current_wind_seed = _derive_wind_seed(attempt_number)

	changes_after_last_flight = 0
	_touch()
	attempt_started.emit(current_attempt_id, current_wind_seed)
	return {
		"session_id": session_id,
		"attempt_id": current_attempt_id,
		"attempt_number": attempt_number,
		"wind_seed": current_wind_seed,
		"rocket_configuration": configuration.call("snapshot"),
		"assembly_metrics": get_assembly_metrics()
	}


func complete_attempt(record: Variant) -> bool:
	if record == null:
		return false
	if record.has_method("set_changes_after_flight"):
		record.call("set_changes_after_flight", changes_after_last_flight)
	if not bool(attempt_history.call("add_attempt", record)):
		return false
	_last_completed_ticks_msec = Time.get_ticks_msec()
	changes_after_last_flight = 0
	set_phase(Phase.REVIEW)
	return true


func set_phase(next_phase: Phase) -> bool:
	if not PHASE_NAMES.has(next_phase):
		return false
	if current_phase == next_phase:
		return true
	var previous := current_phase
	current_phase = next_phase
	_touch()
	phase_changed.emit(previous, current_phase)
	return true


func enter_workshop() -> void:
	set_phase(Phase.WORKSHOP)


func transition_to_field() -> void:
	set_phase(Phase.TRANSITION_TO_FIELD)


func enter_field_test() -> void:
	set_phase(Phase.FIELD_TEST)


func enter_review() -> void:
	set_phase(Phase.REVIEW)


func transition_to_workshop() -> void:
	set_phase(Phase.TRANSITION_TO_WORKSHOP)


func get_phase_name() -> String:
	return String(PHASE_NAMES.get(current_phase, "workshop"))


func get_assembly_metrics() -> Dictionary:
	return AssemblyMetricsScript.evaluate(configuration)


func configuration_snapshot() -> Dictionary:
	return configuration.call("snapshot")


func restore_configuration(snapshot_value: Dictionary) -> bool:
	return bool(configuration.call("apply_snapshot", snapshot_value, true))


func is_minimum_test_ready() -> bool:
	return bool(configuration.call("is_minimum_test_ready"))


func visual_attempts() -> Array[Dictionary]:
	return attempt_history.call("get_visual_attempts")


func visual_trajectories() -> Array[Dictionary]:
	return attempt_history.call("get_visual_trajectories")


func set_keep_wind_for_comparison(value: bool) -> void:
	if keep_wind_for_comparison == value:
		return
	keep_wind_for_comparison = value
	_touch()


func snapshot() -> Dictionary:
	return {
		"schema_version": 1,
		"revision": revision,
		"session_id": session_id,
		"current_attempt_id": current_attempt_id,
		"attempt_number": attempt_number,
		"phase": get_phase_name(),
		"phase_id": int(current_phase),
		"wind_seed": current_wind_seed,
		"keep_wind_for_comparison": keep_wind_for_comparison,
		"changes_after_last_flight": changes_after_last_flight,
		"rocket_configuration": configuration.call("snapshot"),
		"assembly_metrics": get_assembly_metrics(),
		"visual_history": attempt_history.call("snapshot")
	}


func apply_snapshot(data: Dictionary) -> bool:
	session_id = String(data.get("session_id", ""))
	current_attempt_id = String(data.get("current_attempt_id", ""))
	attempt_number = maxi(0, int(data.get("attempt_number", 0)))
	current_wind_seed = maxi(0, int(data.get("wind_seed", 0)))
	keep_wind_for_comparison = bool(data.get("keep_wind_for_comparison", true))
	changes_after_last_flight = maxi(0, int(data.get("changes_after_last_flight", 0)))
	revision = maxi(0, int(data.get("revision", 0)))

	var configuration_value: Variant = data.get("rocket_configuration", {})
	if typeof(configuration_value) == TYPE_DICTIONARY:
		configuration.call("apply_snapshot", configuration_value, false)
	var history_value: Variant = data.get("visual_history", {})
	if typeof(history_value) == TYPE_DICTIONARY or typeof(history_value) == TYPE_ARRAY:
		attempt_history.call("apply_snapshot", history_value, false)

	var phase_id := int(data.get("phase_id", Phase.WORKSHOP))
	current_phase = phase_id as Phase if PHASE_NAMES.has(phase_id) else Phase.WORKSHOP
	state_changed.emit(snapshot())
	configuration_changed.emit(configuration.call("snapshot"))
	visual_history_changed.emit(attempt_history.call("snapshot"))
	return true


func _on_configuration_changed(configuration_value: Dictionary) -> void:
	if current_phase == Phase.WORKSHOP and not bool(attempt_history.call("is_empty")):
		changes_after_last_flight += 1
		attempt_history.call("set_latest_change_count", changes_after_last_flight)
	configuration_changed.emit(configuration_value)
	_touch()


func _on_history_changed(history_snapshot: Dictionary) -> void:
	visual_history_changed.emit(history_snapshot)
	_touch()


func _touch() -> void:
	revision += 1
	state_changed.emit(snapshot())


func _derive_wind_seed(attempt_index: int) -> int:
	var value := int(hash("%s:%d" % [session_id, attempt_index])) & 0x7fffffff
	return 1001 if value == 0 else value


func _new_id(prefix: String) -> String:
	return "%s_%d_%d" % [prefix, int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
