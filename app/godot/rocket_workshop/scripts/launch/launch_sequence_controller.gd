extends Node
class_name VS1LaunchSequenceController

## Public integration API:
##   configure(config_snapshot, seed, rocket_visual_factory)
##   begin_preparation()
##   add_energy_gesture(amount)
##   request_launch()
## The optional factory receives (normalized_config: Dictionary, seed: int) and
## may return a VS1BottleRocketBody, a PackedScene containing one, or a Node3D
## visual that will be parented below a default body.

signal state_changed(previous_state: StringName, new_state: StringName, context: Dictionary)
signal trajectory_sample(sample: Dictionary)
signal launch_completed(summary: Dictionary)
signal review_ready(summary: Dictionary)
signal jet_visual_requested(amount: float, origin: Vector3, direction: Vector3)
signal energy_feedback_changed(normalized_amount: float)
signal return_to_workshop_requested(config_snapshot: Dictionary, summary: Dictionary)
signal fail_safe_triggered(reason: StringName, context: Dictionary)

const SimulatorScript := preload("res://scripts/launch/bottle_rocket_simulator.gd")
const BodyScript := preload("res://scripts/launch/bottle_rocket_body.gd")
const RecorderScript := preload("res://scripts/launch/trajectory_recorder.gd")

var normalized_config: Dictionary = {}
var flight_seed: int = 1
var current_state: StringName = &"PREPARED"
var rocket_body: Node3D = null
var camera_controller: Node = null
var trajectory_renderer: Node3D = null
var trajectory_recorder: RefCounted = null

var _rocket_visual_factory: Callable = Callable()
var _source_config: Dictionary = {}
var _configured: bool = false
var _preparation_begun: bool = false
var _launch_active: bool = false
var _review_emitted: bool = false
var _return_requested: bool = false
var _launch_elapsed: float = 0.0
var _review_elapsed: float = 0.0
var _review_hold: float = 1.6
var _attempt_id: int = 0
var _last_summary: Dictionary = {}
var _start_transform: Transform3D = Transform3D.IDENTITY
var _ground_height: float = 0.0


func _ready() -> void:
	set_process(true)


func configure(
	config_snapshot: Dictionary,
	seed: int,
	rocket_visual_factory: Callable = Callable()
) -> void:
	_source_config = config_snapshot.duplicate(true)
	normalized_config = SimulatorScript.normalize_config(config_snapshot)
	flight_seed = seed
	_rocket_visual_factory = rocket_visual_factory
	_review_hold = lerpf(0.9, 2.7, clampf(float(config_snapshot.get("review_hold", 0.40)), 0.0, 1.0))
	_configured = true
	_preparation_begun = false
	_launch_active = false
	_review_emitted = false
	_return_requested = false
	_launch_elapsed = 0.0
	_review_elapsed = 0.0
	_last_summary.clear()
	if trajectory_recorder == null:
		trajectory_recorder = RecorderScript.new()
	_bind_recorder_signals()


func begin_preparation() -> bool:
	if not _configured:
		_emit_controller_fail_safe(&"sequence_not_configured")
		return false
	if not _ensure_rocket_body():
		_emit_controller_fail_safe(&"rocket_factory_failed")
		return false

	_start_transform = rocket_body.global_transform
	_ground_height = _start_transform.origin.y
	rocket_body.call("prepare", normalized_config, flight_seed, _start_transform, _ground_height)
	_preparation_begun = true
	_launch_active = false
	_review_emitted = false
	_return_requested = false
	_launch_elapsed = 0.0
	_review_elapsed = 0.0
	_set_state(&"PREPARED", rocket_body.call("get_snapshot"))
	if is_instance_valid(camera_controller):
		camera_controller.call("set_target", rocket_body)
		camera_controller.call("reset_to_prepared", false)
	return true


func add_energy_gesture(amount: float) -> float:
	if not _preparation_begun or current_state != &"PREPARED":
		return float(normalized_config.get("energy_level", 0.0))
	var safe_amount: float = clampf(amount, 0.0, 1.0)
	var energy: float = clampf(float(normalized_config.get("energy_level", 0.0)) + safe_amount, 0.0, 1.0)
	normalized_config["energy_level"] = energy
	_source_config["energy_level"] = energy
	if is_instance_valid(rocket_body):
		rocket_body.call("prepare", normalized_config, flight_seed, _start_transform, _ground_height)
	energy_feedback_changed.emit(energy)
	return energy


func request_launch() -> bool:
	if not _preparation_begun or not is_instance_valid(rocket_body):
		_emit_controller_fail_safe(&"launch_without_preparation")
		return false
	if current_state != &"PREPARED" or _launch_active:
		return false
	if _source_config.has("launch_ready") and not bool(_source_config["launch_ready"]):
		return false

	_attempt_id += 1
	trajectory_recorder.call("begin_attempt", normalized_config, flight_seed, {"attempt_id": _attempt_id})
	trajectory_recorder.call("mark_state", &"PREPARED", rocket_body.call("get_snapshot"))
	_launch_active = true
	_review_emitted = false
	_return_requested = false
	_launch_elapsed = 0.0
	_review_elapsed = 0.0
	var accepted: bool = bool(rocket_body.call("start_anticipation"))
	if not accepted:
		_launch_active = false
		trajectory_recorder.call("cancel_attempt")
		_emit_controller_fail_safe(&"body_rejected_launch")
	return accepted


func set_rocket_body(body: Node3D) -> void:
	_unbind_body_signals()
	rocket_body = body
	_bind_body_signals()
	if is_instance_valid(camera_controller) and is_instance_valid(rocket_body):
		camera_controller.call("set_target", rocket_body)


func set_camera_controller(controller: Node) -> void:
	camera_controller = controller
	if is_instance_valid(camera_controller) and is_instance_valid(rocket_body):
		camera_controller.call("set_target", rocket_body)


func set_trajectory_renderer(renderer: Node3D) -> void:
	trajectory_renderer = renderer


func set_trajectory_recorder(recorder: RefCounted) -> void:
	trajectory_recorder = recorder
	_bind_recorder_signals()


func get_recent_attempts() -> Array[Dictionary]:
	if trajectory_recorder == null or not trajectory_recorder.has_method("get_recent_attempts"):
		return []
	var attempts: Variant = trajectory_recorder.call("get_recent_attempts")
	var output: Array[Dictionary] = []
	if attempts is Array:
		for value: Variant in attempts:
			if value is Dictionary:
				output.append(value)
	return output


func get_last_summary() -> Dictionary:
	return _last_summary.duplicate(true)


func _process(delta: float) -> void:
	if _launch_active:
		_launch_elapsed += maxf(0.0, delta)
		if _launch_elapsed > 16.0 and is_instance_valid(rocket_body):
			rocket_body.call("force_safe_finish", &"sequence_timeout")
	elif current_state == &"REVIEW" and _review_emitted and not _return_requested:
		_review_elapsed += maxf(0.0, delta)
		if _review_elapsed >= _review_hold:
			_return_requested = true
			return_to_workshop_requested.emit(normalized_config.duplicate(true), _last_summary.duplicate(true))


func _ensure_rocket_body() -> bool:
	if is_instance_valid(rocket_body):
		_bind_body_signals()
		return rocket_body.has_method("prepare") and rocket_body.has_method("start_anticipation")

	var factory_result: Variant = null
	if _rocket_visual_factory.is_valid():
		factory_result = _rocket_visual_factory.call(normalized_config.duplicate(true), flight_seed)
	if factory_result is PackedScene:
		factory_result = factory_result.instantiate()

	if factory_result is Node3D and factory_result.has_method("prepare") and factory_result.has_method("start_anticipation"):
		rocket_body = factory_result
	else:
		rocket_body = BodyScript.new()
		rocket_body.name = "VS1BottleRocketBody"
		if factory_result is Node3D:
			if factory_result.get_parent() == null:
				rocket_body.add_child(factory_result)

	if rocket_body.get_parent() == null:
		add_child(rocket_body)
	_bind_body_signals()
	return true


func _bind_body_signals() -> void:
	if not is_instance_valid(rocket_body):
		return
	_connect_once(rocket_body, &"flight_state_changed", Callable(self, "_on_body_state_changed"))
	_connect_once(rocket_body, &"trajectory_sample", Callable(self, "_on_body_trajectory_sample"))
	_connect_once(rocket_body, &"jet_visual_requested", Callable(self, "_on_body_jet_visual_requested"))
	_connect_once(rocket_body, &"review_ready", Callable(self, "_on_body_review_ready"))
	_connect_once(rocket_body, &"fail_safe_triggered", Callable(self, "_on_body_fail_safe"))


func _unbind_body_signals() -> void:
	if not is_instance_valid(rocket_body):
		return
	_disconnect_if_connected(rocket_body, &"flight_state_changed", Callable(self, "_on_body_state_changed"))
	_disconnect_if_connected(rocket_body, &"trajectory_sample", Callable(self, "_on_body_trajectory_sample"))
	_disconnect_if_connected(rocket_body, &"jet_visual_requested", Callable(self, "_on_body_jet_visual_requested"))
	_disconnect_if_connected(rocket_body, &"review_ready", Callable(self, "_on_body_review_ready"))
	_disconnect_if_connected(rocket_body, &"fail_safe_triggered", Callable(self, "_on_body_fail_safe"))


func _bind_recorder_signals() -> void:
	if trajectory_recorder == null:
		return
	_connect_once(trajectory_recorder, &"sample_recorded", Callable(self, "_on_recorder_sample_recorded"))


func _connect_once(source: Object, signal_name: StringName, callback: Callable) -> void:
	if source.has_signal(signal_name) and not source.is_connected(signal_name, callback):
		source.connect(signal_name, callback)


func _disconnect_if_connected(source: Object, signal_name: StringName, callback: Callable) -> void:
	if source.has_signal(signal_name) and source.is_connected(signal_name, callback):
		source.disconnect(signal_name, callback)


func _on_body_state_changed(previous: StringName, next_state: StringName, snapshot: Dictionary) -> void:
	current_state = next_state
	if trajectory_recorder != null and trajectory_recorder.call("is_recording"):
		trajectory_recorder.call("mark_state", next_state, snapshot)
	if is_instance_valid(camera_controller):
		camera_controller.call("set_phase", next_state)
	state_changed.emit(previous, next_state, snapshot.duplicate(true))
	if next_state == &"REVIEW":
		_finish_launch(snapshot)


func _on_body_trajectory_sample(snapshot: Dictionary) -> void:
	if trajectory_recorder != null and trajectory_recorder.call("is_recording"):
		trajectory_recorder.call("record_sample", snapshot)


func _on_recorder_sample_recorded(sample: Dictionary) -> void:
	trajectory_sample.emit(sample.duplicate(true))


func _on_body_jet_visual_requested(amount: float, origin: Vector3, direction: Vector3) -> void:
	jet_visual_requested.emit(amount, origin, direction)


func _on_body_review_ready(snapshot: Dictionary) -> void:
	_finish_launch(snapshot)


func _on_body_fail_safe(reason: StringName, snapshot: Dictionary) -> void:
	if trajectory_recorder != null:
		trajectory_recorder.call("note_fail_safe", reason)
	fail_safe_triggered.emit(reason, snapshot.duplicate(true))


func _finish_launch(snapshot: Dictionary) -> void:
	if _review_emitted:
		return
	_launch_active = false
	_review_emitted = true
	_review_elapsed = 0.0
	if trajectory_recorder != null and trajectory_recorder.call("is_recording"):
		_last_summary = trajectory_recorder.call("finish_attempt", snapshot, {"state": &"REVIEW"})
	else:
		_last_summary = snapshot.duplicate(true)
	_last_summary["seed"] = flight_seed
	_last_summary["config"] = normalized_config.duplicate(true)

	if is_instance_valid(trajectory_renderer):
		trajectory_renderer.call("render_from_recorder", trajectory_recorder)
		if is_instance_valid(camera_controller):
			camera_controller.call("frame_trajectory", trajectory_renderer.call("get_all_points"))
	if is_instance_valid(camera_controller):
		camera_controller.call("set_phase", &"REVIEW")
	launch_completed.emit(_last_summary.duplicate(true))
	review_ready.emit(_last_summary.duplicate(true))


func _set_state(next_state: StringName, context: Dictionary = {}) -> void:
	var previous: StringName = current_state
	current_state = next_state
	if previous != next_state:
		state_changed.emit(previous, next_state, context.duplicate(true))


func _emit_controller_fail_safe(reason: StringName) -> void:
	var context := {
		"state": current_state,
		"seed": flight_seed,
		"config": normalized_config.duplicate(true),
		"reason": reason,
	}
	fail_safe_triggered.emit(reason, context)
