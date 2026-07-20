extends RefCounted
class_name FlightModel

const WindModelScript := preload("res://scripts/flight/wind_model.gd")
const FlightRecorderScript := preload("res://scripts/flight/flight_recorder.gd")

enum FlightState {
	ON_STAND,
	PREPARING,
	THRUST,
	COAST,
	APOGEE,
	DESCENT,
	IMPACTED,
	RESETTING
}

var state: FlightState = FlightState.ON_STAND
var parameters: Resource = null
var wind: RefCounted = null
var recorder: RefCounted = null
var position: Vector3 = Vector3.ZERO
var velocity: Vector3 = Vector3.ZERO
var rotation: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO
var start_position: Vector3 = Vector3.ZERO
var start_rotation: Vector3 = Vector3.ZERO
var ground_y: float = 0.0
var elapsed: float = 0.0
var phase_elapsed: float = 0.0
var thrust_duration: float = 0.8
var prepare_duration: float = 0.42
var apogee_hold: float = 0.12
var impacted: bool = false

var _launch_id: int = 0
var _previous_vertical_velocity: float = 0.0
var _noise_phase: float = 0.0


func setup(new_launch_id: int, session_id: String, new_parameters: Resource, new_start_position: Vector3, new_start_rotation: Vector3) -> void:
	_launch_id = new_launch_id
	parameters = new_parameters
	wind = WindModelScript.new()
	wind.configure(int(parameters.flight_seed), float(parameters.wind_strength))
	recorder = FlightRecorderScript.new()
	recorder.begin(new_launch_id, session_id, parameters, new_start_position)
	position = new_start_position
	start_position = new_start_position
	ground_y = new_start_position.y
	start_rotation = new_start_rotation
	var yaw_error: float = (0.5 - parameters.mass_balance) * 0.34
	rotation = Vector3(new_start_rotation.x, new_start_rotation.y + yaw_error, deg_to_rad(48.0 + parameters.energy * 14.0))
	velocity = Vector3.ZERO
	angular_velocity = Vector3(
		(1.0 - parameters.fin_alignment) * 0.85,
		(1.0 - parameters.fin_symmetry) * 1.20,
		(1.0 - parameters.nose_alignment) * 0.70
	)
	elapsed = 0.0
	phase_elapsed = 0.0
	thrust_duration = lerpf(0.46, 0.92, parameters.energy)
	_noise_phase = float(parameters.flight_seed % 4096) * 0.013
	impacted = false
	_set_state(FlightState.PREPARING)


func step(delta: float) -> void:
	if state == FlightState.ON_STAND or state == FlightState.IMPACTED:
		return

	elapsed += delta
	phase_elapsed += delta

	if state == FlightState.PREPARING:
		_step_preparing(delta)
	elif state == FlightState.THRUST:
		_step_flight(delta, true)
		if phase_elapsed >= thrust_duration:
			_set_state(FlightState.COAST)
	elif state == FlightState.COAST:
		_step_flight(delta, false)
		if _previous_vertical_velocity > 0.0 and velocity.y <= 0.0:
			_set_state(FlightState.APOGEE)
	elif state == FlightState.APOGEE:
		_step_flight(delta, false)
		if phase_elapsed >= apogee_hold:
			_set_state(FlightState.DESCENT)
	elif state == FlightState.DESCENT:
		_step_flight(delta, false)

	recorder.sample(elapsed, position, velocity, angular_velocity)
	_previous_vertical_velocity = velocity.y


func state_name() -> String:
	return _state_name(state)


func finish_summary() -> Dictionary:
	return recorder.finish(elapsed, position)


func result_profile() -> String:
	var summary: Dictionary = finish_summary()
	var height: float = float(summary.get("max_height", 0.0))
	var spin: float = float(summary.get("mean_angular_velocity", 0.0))
	if height > 4.0 and spin < 1.15 and parameters.fin_count >= 3:
		return "stable"
	if height > 2.0:
		return "reasonable_spin"
	return "short_unstable"


func _step_preparing(delta: float) -> void:
	var shake: float = sin(elapsed * 55.0 + _noise_phase) * 0.018 * parameters.energy
	position = start_position + Vector3(shake, absf(shake) * 0.45, -shake * 0.4)
	if phase_elapsed >= prepare_duration:
		position = start_position
		velocity = _forward_axis() * lerpf(0.35, 0.95, parameters.energy)
		_previous_vertical_velocity = velocity.y
		_set_state(FlightState.THRUST)


func _step_flight(delta: float, thrusting: bool) -> void:
	var acceleration: Vector3 = Vector3.DOWN * 6.4
	var wind_vector: Vector3 = wind.sample(elapsed)
	var relative_velocity: Vector3 = velocity - wind_vector
	var speed: float = relative_velocity.length()
	if thrusting:
		var normalized_time: float = clampf(phase_elapsed / maxf(thrust_duration, 0.001), 0.0, 1.0)
		var curve_value: float = _thrust_curve(normalized_time)
		var thrust: float = lerpf(9.5, 22.0, parameters.energy) * curve_value
		var noise: Vector3 = _controlled_noise() * (1.0 - parameters.attachment_quality) * 1.1
		acceleration += (_forward_axis() + noise).normalized() * thrust

	if speed > 0.01:
		var drag_coefficient: float = 0.035 + parameters.body_drag_factor * 0.090
		var drag: Vector3 = -relative_velocity.normalized() * drag_coefficient * minf(speed * speed, 80.0)
		acceleration += drag
		acceleration += wind_vector * 0.20
		_apply_aero_torque(delta, relative_velocity.normalized(), speed)

	velocity += acceleration * delta
	velocity = velocity.limit_length(18.0)
	position += velocity * delta
	rotation += angular_velocity * delta
	angular_velocity *= pow(0.985 - parameters.fin_symmetry * 0.008, delta * 60.0)

	if position.y <= ground_y and elapsed > prepare_duration + 0.25 and velocity.y < 0.0:
		position.y = ground_y
		velocity = Vector3.ZERO
		angular_velocity *= 0.35
		impacted = true
		_set_state(FlightState.IMPACTED)


func _apply_aero_torque(delta: float, velocity_direction: Vector3, speed: float) -> void:
	var forward: Vector3 = _forward_axis()
	var align_axis: Vector3 = forward.cross(velocity_direction)
	var stability: float = clampf((parameters.fin_symmetry * 0.48) + (parameters.fin_alignment * 0.36) + (parameters.attachment_quality * 0.16), 0.0, 1.0)
	var correction: Vector3 = align_axis * speed * stability * 0.36
	var error_strength: float = (1.0 - parameters.fin_symmetry) * 0.85 + (1.0 - parameters.nose_alignment) * 0.55 + (1.0 - parameters.mass_balance) * 0.45
	var error: Vector3 = Vector3(
		sin(elapsed * 2.1 + _noise_phase),
		cos(elapsed * 1.7 + _noise_phase * 0.7),
		sin(elapsed * 2.7 + _noise_phase * 1.3)
	) * error_strength * 0.24
	angular_velocity += (correction + error) * delta
	angular_velocity = angular_velocity.limit_length(4.8)


func _forward_axis() -> Vector3:
	return Basis.from_euler(rotation).x.normalized()


func _controlled_noise() -> Vector3:
	return Vector3(
		sin(elapsed * 9.7 + _noise_phase) * 0.18,
		sin(elapsed * 7.1 + _noise_phase * 0.4) * 0.10,
		cos(elapsed * 8.3 + _noise_phase * 1.2) * 0.18
	)


func _thrust_curve(t: float) -> float:
	return clampf(sin(t * PI) * 0.72 + (1.0 - t) * 0.34 + 0.12, 0.0, 1.0)


func _set_state(new_state: FlightState) -> void:
	if state == new_state:
		return
	state = new_state
	phase_elapsed = 0.0
	recorder.mark_state(_state_name(state), elapsed)


func _state_name(value: FlightState) -> String:
	match value:
		FlightState.ON_STAND:
			return "ON_STAND"
		FlightState.PREPARING:
			return "PREPARING"
		FlightState.THRUST:
			return "THRUST"
		FlightState.COAST:
			return "COAST"
		FlightState.APOGEE:
			return "APOGEE"
		FlightState.DESCENT:
			return "DESCENT"
		FlightState.IMPACTED:
			return "IMPACTED"
		FlightState.RESETTING:
			return "RESETTING"
	return "UNKNOWN"
