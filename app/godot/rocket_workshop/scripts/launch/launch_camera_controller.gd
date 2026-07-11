extends Node
class_name VS1LaunchCameraController

## Phase-based camera rig with world-up framing. Configuration is normalized;
## all actual offsets are internal presentation values.

signal camera_phase_changed(previous_phase: StringName, new_phase: StringName)

const VALID_PHASES := [
	&"PREPARED",
	&"ANTICIPATION",
	&"THRUST",
	&"COAST",
	&"APEX",
	&"DESCENT",
	&"IMPACT",
	&"REVIEW",
]

var camera: Camera3D = null
var target: Node3D = null
var camera_phase: StringName = &"PREPARED"
var normalized_config: Dictionary = {}
var camera_seed: int = 1

var _prepared_transform: Transform3D = Transform3D.IDENTITY
var _prepared_fov: float = 70.0
var _initial_target_position: Vector3 = Vector3.ZERO
var _view_direction: Vector3 = Vector3(1.0, 0.0, 1.0).normalized()
var _phase_elapsed: float = 0.0
var _shake_phase_a: float = 0.0
var _shake_phase_b: float = 0.0
var _review_center: Vector3 = Vector3.ZERO
var _review_extent: float = 0.0
var _has_review_frame: bool = false


func configure(
	camera_node: Camera3D,
	target_node: Node3D = null,
	config_snapshot: Dictionary = {},
	seed_value: int = 1
) -> void:
	camera = camera_node
	normalized_config = {
		"follow_distance": clampf(float(config_snapshot.get("follow_distance", 0.58)), 0.0, 1.0),
		"follow_height": clampf(float(config_snapshot.get("follow_height", 0.56)), 0.0, 1.0),
		"smoothing": clampf(float(config_snapshot.get("smoothing", 0.66)), 0.0, 1.0),
		"shake": clampf(float(config_snapshot.get("shake", 0.48)), 0.0, 1.0),
		"horizon_weight": clampf(float(config_snapshot.get("horizon_weight", 0.82)), 0.0, 1.0),
	}
	camera_seed = seed_value
	_configure_seeded_motion()
	set_target(target_node)
	if camera != null:
		_prepared_transform = camera.global_transform
		_prepared_fov = camera.fov
		_update_view_direction()
	set_process(true)


func set_target(target_node: Node3D) -> void:
	if is_instance_valid(target) and target.has_signal("flight_state_changed"):
		var old_callable := Callable(self, "_on_target_state_changed")
		if target.is_connected("flight_state_changed", old_callable):
			target.disconnect("flight_state_changed", old_callable)
	target = target_node
	if is_instance_valid(target):
		_initial_target_position = target.global_position
		if target.has_signal("flight_state_changed"):
			var new_callable := Callable(self, "_on_target_state_changed")
			if not target.is_connected("flight_state_changed", new_callable):
				target.connect("flight_state_changed", new_callable)
	_update_view_direction()


func set_phase(next_phase: StringName) -> void:
	if not VALID_PHASES.has(next_phase) or camera_phase == next_phase:
		return
	var previous: StringName = camera_phase
	camera_phase = next_phase
	_phase_elapsed = 0.0
	camera_phase_changed.emit(previous, next_phase)


func frame_trajectory(points: PackedVector3Array) -> void:
	if points.is_empty():
		_has_review_frame = false
		return
	var minimum: Vector3 = points[0]
	var maximum: Vector3 = points[0]
	for point: Vector3 in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	_review_center = (minimum + maximum) * 0.5
	_review_extent = maxf(1.0, (maximum - minimum).length())
	_has_review_frame = true


func reset_to_prepared(immediate: bool = false) -> void:
	set_phase(&"PREPARED")
	_has_review_frame = false
	if immediate and camera != null:
		camera.global_transform = _prepared_transform
		camera.fov = _prepared_fov


func _process(delta: float) -> void:
	if camera == null:
		return
	_phase_elapsed += maxf(0.0, delta)
	var target_position: Vector3 = _initial_target_position
	if is_instance_valid(target):
		target_position = target.global_position

	var desired_position: Vector3 = _prepared_transform.origin
	var look_target: Vector3 = target_position
	var desired_fov: float = _prepared_fov
	var distance: float = lerpf(4.4, 8.4, float(normalized_config.get("follow_distance", 0.58)))
	var height: float = lerpf(2.2, 5.2, float(normalized_config.get("follow_height", 0.56)))

	match camera_phase:
		&"PREPARED":
			desired_position = _prepared_transform.origin
			look_target = _initial_target_position
		&"ANTICIPATION":
			desired_position = _prepared_transform.origin + _view_direction * 0.12
			look_target = target_position + Vector3.UP * 0.16
		&"THRUST":
			desired_position = target_position + _view_direction * distance + Vector3.UP * height
			look_target = target_position + Vector3.UP * 0.35
			desired_fov = _prepared_fov + 4.0
		&"COAST":
			desired_position = target_position + _view_direction * (distance * 1.08) + Vector3.UP * (height * 0.92)
			look_target = target_position + Vector3.UP * 0.12
			desired_fov = _prepared_fov + 2.0
		&"APEX":
			desired_position = target_position + _view_direction * (distance * 1.12) + Vector3.UP * (height * 0.70)
			look_target = target_position
			desired_fov = _prepared_fov + 1.0
		&"DESCENT":
			desired_position = target_position + _view_direction * (distance * 1.16) + Vector3.UP * (height * 0.62)
			look_target = target_position - Vector3.UP * 0.12
		&"IMPACT":
			desired_position = target_position + _view_direction * (distance * 0.82) + Vector3.UP * (height * 0.52)
			look_target = target_position
			desired_fov = _prepared_fov - 2.0
		&"REVIEW":
			var center: Vector3 = _review_center if _has_review_frame else target_position
			var framing_distance: float = maxf(distance, _review_extent * 1.12) if _has_review_frame else distance
			desired_position = center + _view_direction * framing_distance + Vector3.UP * maxf(height, _review_extent * 0.34)
			look_target = center
			desired_fov = _prepared_fov + 3.0

	var shake_offset: Vector3 = _camera_shake()
	desired_position += shake_offset
	var desired_transform := Transform3D(Basis.IDENTITY, desired_position).looking_at(look_target, Vector3.UP)
	var smoothing: float = lerpf(3.2, 8.8, float(normalized_config.get("smoothing", 0.66)))
	if camera_phase == &"APEX":
		smoothing *= 0.62
	elif camera_phase == &"THRUST":
		smoothing *= 1.22
	var alpha: float = 1.0 - exp(-smoothing * maxf(0.0, delta))
	camera.global_transform = camera.global_transform.interpolate_with(desired_transform, alpha)
	camera.fov = lerpf(camera.fov, desired_fov, alpha)


func _on_target_state_changed(_previous: StringName, next_state: StringName, _snapshot: Dictionary) -> void:
	set_phase(next_state)


func _camera_shake() -> Vector3:
	var strength: float = lerpf(0.012, 0.055, float(normalized_config.get("shake", 0.48)))
	var phase_strength: float = 0.0
	if camera_phase == &"ANTICIPATION":
		phase_strength = clampf(_phase_elapsed / 0.45, 0.0, 1.0) * 0.36
	elif camera_phase == &"THRUST":
		phase_strength = exp(-_phase_elapsed * 2.4)
	elif camera_phase == &"IMPACT":
		phase_strength = exp(-_phase_elapsed * 8.0) * 0.72
	if phase_strength <= 0.0:
		return Vector3.ZERO
	return Vector3(
		sin(_phase_elapsed * 39.0 + _shake_phase_a),
		cos(_phase_elapsed * 43.0 + _shake_phase_b),
		sin(_phase_elapsed * 31.0 + _shake_phase_b)
	) * strength * phase_strength


func _configure_seeded_motion() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = camera_seed
	_shake_phase_a = rng.randf_range(-PI, PI)
	_shake_phase_b = rng.randf_range(-PI, PI)


func _update_view_direction() -> void:
	if camera == null:
		return
	var reference_position: Vector3 = _initial_target_position
	if is_instance_valid(target):
		reference_position = target.global_position
	var flat_offset: Vector3 = camera.global_position - reference_position
	flat_offset.y = 0.0
	if flat_offset.length_squared() > 0.0001:
		_view_direction = flat_offset.normalized()
