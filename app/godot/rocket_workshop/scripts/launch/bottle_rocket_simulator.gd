extends RefCounted
class_name VS1BottleRocketSimulator

## Deterministic, scene-independent flight model for the vertical slice.
## All inputs are abstract gameplay values normalized to [0, 1], except the
## centered asymmetry vector whose components are normalized to [-1, 1].

signal state_changed(previous_state: int, new_state: int, snapshot: Dictionary)
signal sample_ready(snapshot: Dictionary)
signal jet_changed(amount: float, origin: Vector3, direction: Vector3)
signal apex_reached(position: Vector3, elapsed: float)
signal impact_reached(position: Vector3, elapsed: float, reason: StringName)
signal simulation_finished(snapshot: Dictionary)
signal fail_safe_triggered(reason: StringName, snapshot: Dictionary)

enum FlightState {
	PREPARED,
	ANTICIPATION,
	THRUST,
	COAST,
	APEX,
	DESCENT,
	IMPACT,
	REVIEW,
}

const FIXED_STEP: float = 1.0 / 120.0
const MAX_SUBSTEPS_PER_ADVANCE: int = 32
const MAX_FLIGHT_TIME: float = 14.0
const MAX_ABSTRACT_SPEED: float = 30.0
const MAX_ABSTRACT_SPIN: float = 12.0
const MAX_ABSTRACT_DISTANCE: float = 180.0
const DEFAULT_CONFIG := {
	"energy_level": 0.62,
	"water_level": 0.52,
	"fin_presence": 1.0,
	"fin_symmetry": 0.78,
	"fin_alignment": 0.78,
	"fin_height_consistency": 0.78,
	"attachment_quality": 0.72,
	"nose_alignment": 0.82,
	"mass_balance": 0.72,
	"body_drag": 0.42,
	"wind_level": 0.16,
	"anticipation_level": 0.42,
	"asymmetry_vector": Vector3.ZERO,
}

var flight_state: FlightState = FlightState.PREPARED
var config: Dictionary = DEFAULT_CONFIG.duplicate(true)
var flight_seed: int = 1
var flight_transform: Transform3D = Transform3D.IDENTITY
var linear_velocity: Vector3 = Vector3.ZERO
var angular_velocity: Vector3 = Vector3.ZERO
var abstract_mass: float = 1.0
var stability_score: float = 0.0
var total_elapsed: float = 0.0
var state_elapsed: float = 0.0
var fail_safe_reason: StringName = &""

var last_thrust_force: Vector3 = Vector3.ZERO
var last_drag_force: Vector3 = Vector3.ZERO
var last_wind_force: Vector3 = Vector3.ZERO
var last_gravity_force: Vector3 = Vector3.ZERO
var last_stability_torque: Vector3 = Vector3.ZERO
var last_asymmetry_torque: Vector3 = Vector3.ZERO

var _start_transform: Transform3D = Transform3D.IDENTITY
var _ground_height: float = 0.0
var _accumulator: float = 0.0
var _previous_vertical_velocity: float = 0.0
var _has_left_ground: bool = false
var _fail_safe_emitted: bool = false
var _impact_reason: StringName = &"ground"
var _wind_direction: Vector3 = Vector3.RIGHT
var _wind_phase_a: float = 0.0
var _wind_phase_b: float = 0.0
var _seeded_asymmetry_direction: Vector3 = Vector3.RIGHT


static func normalize_config(source: Dictionary) -> Dictionary:
	var normalized: Dictionary = DEFAULT_CONFIG.duplicate(true)
	for key: String in DEFAULT_CONFIG.keys():
		if key == "asymmetry_vector":
			continue
		if source.has(key):
			var candidate: float = float(source[key])
			normalized[key] = clampf(candidate, 0.0, 1.0) if is_finite(candidate) else DEFAULT_CONFIG[key]

	var asymmetry_value: Variant = source.get("asymmetry_vector", Vector3.ZERO)
	var asymmetry := Vector3.ZERO
	if asymmetry_value is Vector3:
		asymmetry = asymmetry_value
	elif asymmetry_value is Dictionary:
		if asymmetry_value.has("z"):
			asymmetry = Vector3(
				float(asymmetry_value.get("x", 0.0)),
				float(asymmetry_value.get("y", 0.0)),
				float(asymmetry_value.get("z", 0.0))
			)
		else:
			# Assembly metrics expose their centered radial vector as {x, y}.
			asymmetry = Vector3(
				float(asymmetry_value.get("x", 0.0)),
				0.0,
				float(asymmetry_value.get("y", 0.0))
			)
	if not (is_finite(asymmetry.x) and is_finite(asymmetry.y) and is_finite(asymmetry.z)):
		asymmetry = Vector3.ZERO
	normalized["asymmetry_vector"] = Vector3(
		clampf(asymmetry.x, -1.0, 1.0),
		clampf(asymmetry.y, -1.0, 1.0),
		clampf(asymmetry.z, -1.0, 1.0)
	).limit_length(1.0)
	return normalized


static func calculate_stability(normalized_config: Dictionary) -> float:
	var safe: Dictionary = normalize_config(normalized_config)
	return clampf(
		float(safe["fin_presence"]) * 0.24
		+ float(safe["fin_symmetry"]) * 0.20
		+ float(safe["fin_alignment"]) * 0.17
		+ float(safe["fin_height_consistency"]) * 0.12
		+ float(safe["attachment_quality"]) * 0.12
		+ float(safe["nose_alignment"]) * 0.09
		+ float(safe["mass_balance"]) * 0.06,
		0.0,
		1.0
	)


static func state_name(value: int) -> StringName:
	match value:
		FlightState.PREPARED:
			return &"PREPARED"
		FlightState.ANTICIPATION:
			return &"ANTICIPATION"
		FlightState.THRUST:
			return &"THRUST"
		FlightState.COAST:
			return &"COAST"
		FlightState.APEX:
			return &"APEX"
		FlightState.DESCENT:
			return &"DESCENT"
		FlightState.IMPACT:
			return &"IMPACT"
		FlightState.REVIEW:
			return &"REVIEW"
	return &"UNKNOWN"


func setup(
	normalized_config: Dictionary,
	seed_value: int,
	start_transform: Transform3D = Transform3D.IDENTITY,
	ground_height: float = 0.0
) -> void:
	config = normalize_config(normalized_config)
	flight_seed = seed_value
	_start_transform = start_transform
	_start_transform.basis = _start_transform.basis.orthonormalized()
	flight_transform = _start_transform
	_ground_height = ground_height
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	stability_score = calculate_stability(config)
	abstract_mass = _initial_mass()
	total_elapsed = 0.0
	state_elapsed = 0.0
	_accumulator = 0.0
	_previous_vertical_velocity = 0.0
	_has_left_ground = false
	_fail_safe_emitted = false
	fail_safe_reason = &""
	_impact_reason = &"ground"
	_clear_dynamics()
	_configure_seeded_variation()
	flight_state = FlightState.PREPARED
	sample_ready.emit(get_snapshot())


func launch() -> bool:
	if flight_state != FlightState.PREPARED:
		return false
	_transition_to(FlightState.ANTICIPATION)
	return true


func advance(delta: float) -> void:
	if flight_state == FlightState.REVIEW or flight_state == FlightState.PREPARED:
		return
	if not is_finite(delta) or delta < 0.0:
		_trigger_fail_safe(&"invalid_delta")
		return
	if is_zero_approx(delta):
		return

	_accumulator += minf(delta, FIXED_STEP * float(MAX_SUBSTEPS_PER_ADVANCE))
	var step_count: int = 0
	while _accumulator + 0.0000001 >= FIXED_STEP and step_count < MAX_SUBSTEPS_PER_ADVANCE:
		_step_fixed(FIXED_STEP)
		_accumulator -= FIXED_STEP
		step_count += 1
		if flight_state == FlightState.REVIEW:
			_accumulator = 0.0
			break


func advance_fixed_steps(step_count: int = 1) -> void:
	for index: int in range(maxi(0, step_count)):
		_step_fixed(FIXED_STEP)
		if flight_state == FlightState.REVIEW:
			break


func register_impact(position: Vector3, reason: StringName = &"collision") -> void:
	if flight_state == FlightState.IMPACT or flight_state == FlightState.REVIEW:
		return
	if flight_state == FlightState.PREPARED:
		return
	if _is_vector_finite(position):
		flight_transform.origin = position
	_impact_reason = reason
	_enter_impact()


func force_safe_finish(reason: StringName = &"external_timeout") -> void:
	_trigger_fail_safe(reason)


func is_finished() -> bool:
	return flight_state == FlightState.REVIEW


func get_state_name() -> StringName:
	return state_name(flight_state)


func get_wind() -> Vector3:
	return _sample_wind(total_elapsed)


func get_snapshot() -> Dictionary:
	return {
		"state": get_state_name(),
		"state_id": int(flight_state),
		"elapsed": total_elapsed,
		"state_elapsed": state_elapsed,
		"transform": flight_transform,
		"position": flight_transform.origin,
		"basis": flight_transform.basis,
		"velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"abstract_mass": abstract_mass,
		"stability_score": stability_score,
		"wind": get_wind(),
		"thrust_force": last_thrust_force,
		"drag_force": last_drag_force,
		"wind_force": last_wind_force,
		"gravity_force": last_gravity_force,
		"stability_torque": last_stability_torque,
		"asymmetry_torque": last_asymmetry_torque,
		"jet_amount": _jet_amount(),
		"seed": flight_seed,
		"fail_safe_reason": fail_safe_reason,
	}


func _step_fixed(delta: float) -> void:
	if flight_state == FlightState.PREPARED or flight_state == FlightState.REVIEW:
		return

	total_elapsed += delta
	state_elapsed += delta
	var state_before_step: FlightState = flight_state
	var previous_velocity_y: float = linear_velocity.y

	match flight_state:
		FlightState.ANTICIPATION:
			_clear_dynamics()
			if state_elapsed >= _anticipation_duration():
				_transition_to(FlightState.THRUST)
		FlightState.THRUST:
			_integrate_flight(delta, true)
			if state_elapsed >= _thrust_duration():
				_transition_to(FlightState.COAST)
		FlightState.COAST:
			_integrate_flight(delta, false)
			if _has_left_ground and previous_velocity_y > 0.0 and linear_velocity.y <= 0.0:
				_transition_to(FlightState.APEX)
			elif state_elapsed > 4.0 and linear_velocity.y <= 0.0:
				_transition_to(FlightState.DESCENT)
		FlightState.APEX:
			_integrate_flight(delta, false)
			if state_elapsed >= 0.16:
				_transition_to(FlightState.DESCENT)
		FlightState.DESCENT:
			_integrate_flight(delta, false)
		FlightState.IMPACT:
			_clear_dynamics()
			linear_velocity = Vector3.ZERO
			angular_velocity *= maxf(0.0, 1.0 - delta * 9.0)
			if state_elapsed >= 0.32:
				_transition_to(FlightState.REVIEW)

	_previous_vertical_velocity = linear_velocity.y
	if state_before_step != FlightState.IMPACT and flight_state != FlightState.REVIEW:
		_validate_simulation()
	if flight_state != FlightState.REVIEW:
		sample_ready.emit(get_snapshot())


func _integrate_flight(delta: float, thrusting: bool) -> void:
	var forward: Vector3 = flight_transform.basis.y.normalized()
	var wind: Vector3 = _sample_wind(total_elapsed)
	var relative_velocity: Vector3 = linear_velocity - wind
	var relative_speed: float = relative_velocity.length()
	var thrust_amount: float = _thrust_amount() if thrusting else 0.0
	var thrust_strength: float = lerpf(12.0, 25.0, float(config["energy_level"])) * thrust_amount
	var asymmetry: Vector3 = _effective_asymmetry()
	var thrust_bias: Vector3 = flight_transform.basis * Vector3(asymmetry.x, 0.0, asymmetry.z)
	var thrust_direction: Vector3 = (forward + thrust_bias * 0.11).normalized()

	last_thrust_force = thrust_direction * thrust_strength
	last_gravity_force = Vector3.DOWN * (6.8 * abstract_mass)
	last_drag_force = Vector3.ZERO
	last_wind_force = Vector3.ZERO
	if relative_speed > 0.001:
		var drag_factor: float = lerpf(0.020, 0.072, float(config["body_drag"]))
		drag_factor += (1.0 - stability_score) * 0.018
		last_drag_force = -relative_velocity.normalized() * minf(relative_speed * relative_speed * drag_factor, 16.0)
		last_wind_force = wind * lerpf(0.10, 0.44, float(config["wind_level"]))
		last_wind_force += (flight_transform.basis * asymmetry) * minf(relative_speed * relative_speed * 0.012, 1.8)

	var net_force: Vector3 = last_thrust_force + last_gravity_force + last_drag_force + last_wind_force
	linear_velocity += (net_force / maxf(abstract_mass, 0.45)) * delta
	linear_velocity = linear_velocity.limit_length(MAX_ABSTRACT_SPEED)
	flight_transform.origin += linear_velocity * delta

	_update_abstract_mass(thrusting)
	_integrate_torque(delta, relative_velocity, forward, asymmetry)
	if angular_velocity.length_squared() > 0.0000001:
		var rotation_delta := Quaternion(angular_velocity.normalized(), angular_velocity.length() * delta)
		flight_transform.basis = (Basis(rotation_delta) * flight_transform.basis).orthonormalized()

	if flight_transform.origin.y > _ground_height + 0.06:
		_has_left_ground = true
	if _should_impact_ground():
		flight_transform.origin.y = _ground_height
		_impact_reason = &"ground"
		_enter_impact()

	jet_changed.emit(thrust_amount, flight_transform.origin, -forward)


func _integrate_torque(delta: float, relative_velocity: Vector3, forward: Vector3, asymmetry: Vector3) -> void:
	var speed: float = relative_velocity.length()
	var velocity_direction: Vector3 = relative_velocity.normalized() if speed > 0.001 else forward
	var alignment_axis: Vector3 = forward.cross(velocity_direction)
	last_stability_torque = alignment_axis * speed * lerpf(0.08, 0.62, stability_score)
	var asymmetry_world: Vector3 = flight_transform.basis * asymmetry
	var imperfection: float = 1.0 - stability_score
	last_asymmetry_torque = asymmetry_world * (0.24 + speed * 0.12) * lerpf(0.55, 1.35, imperfection)
	last_asymmetry_torque += _controlled_wobble() * imperfection * (0.08 + speed * 0.025)

	var angular_acceleration: Vector3 = last_stability_torque + last_asymmetry_torque
	var abstract_inertia: float = lerpf(0.72, 1.22, abstract_mass)
	angular_velocity += (angular_acceleration / abstract_inertia) * delta
	var damping: float = lerpf(0.16, 0.82, stability_score)
	angular_velocity *= exp(-damping * delta)
	angular_velocity = angular_velocity.limit_length(MAX_ABSTRACT_SPIN)


func _transition_to(next_state: FlightState) -> void:
	if flight_state == next_state:
		return
	var previous_state: FlightState = flight_state
	flight_state = next_state
	state_elapsed = 0.0
	if next_state == FlightState.APEX:
		apex_reached.emit(flight_transform.origin, total_elapsed)
	elif next_state == FlightState.IMPACT:
		impact_reached.emit(flight_transform.origin, total_elapsed, _impact_reason)
	elif next_state == FlightState.REVIEW:
		jet_changed.emit(0.0, flight_transform.origin, -flight_transform.basis.y.normalized())
	state_changed.emit(int(previous_state), int(next_state), get_snapshot())
	if next_state == FlightState.REVIEW:
		simulation_finished.emit(get_snapshot())


func _enter_impact() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity *= 0.28
	_transition_to(FlightState.IMPACT)


func _validate_simulation() -> void:
	if total_elapsed > MAX_FLIGHT_TIME:
		_trigger_fail_safe(&"flight_timeout")
		return
	if not _is_vector_finite(flight_transform.origin) or not _is_vector_finite(linear_velocity):
		_trigger_fail_safe(&"non_finite_motion")
		return
	if not _is_vector_finite(angular_velocity) or not _is_basis_finite(flight_transform.basis):
		_trigger_fail_safe(&"non_finite_rotation")
		return
	if flight_transform.origin.distance_to(_start_transform.origin) > MAX_ABSTRACT_DISTANCE:
		_trigger_fail_safe(&"out_of_bounds")


func _trigger_fail_safe(reason: StringName) -> void:
	if flight_state == FlightState.REVIEW:
		return
	fail_safe_reason = reason
	if not _is_vector_finite(flight_transform.origin):
		flight_transform = _start_transform
	if not _is_vector_finite(linear_velocity):
		linear_velocity = Vector3.ZERO
	if not _is_vector_finite(angular_velocity):
		angular_velocity = Vector3.ZERO
	if not _is_basis_finite(flight_transform.basis):
		flight_transform.basis = _start_transform.basis
	_impact_reason = &"fail_safe"
	if not _fail_safe_emitted:
		_fail_safe_emitted = true
		fail_safe_triggered.emit(reason, get_snapshot())
	_enter_impact()


func _configure_seeded_variation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = flight_seed
	var angle: float = rng.randf_range(-PI, PI)
	_wind_direction = Vector3(cos(angle), 0.0, sin(angle)).normalized()
	_wind_phase_a = rng.randf_range(-PI, PI)
	_wind_phase_b = rng.randf_range(-PI, PI)
	var asymmetry_angle: float = rng.randf_range(-PI, PI)
	_seeded_asymmetry_direction = Vector3(cos(asymmetry_angle), 0.25, sin(asymmetry_angle)).normalized()


func _sample_wind(time_value: float) -> Vector3:
	var level: float = float(config["wind_level"])
	var base_strength: float = lerpf(0.08, 0.72, level) * level
	var variation: float = 1.0
	variation += sin(time_value * 0.71 + _wind_phase_a) * 0.16
	variation += sin(time_value * 1.37 + _wind_phase_b) * 0.07
	var cross_direction := Vector3(-_wind_direction.z, 0.0, _wind_direction.x)
	return _wind_direction * base_strength * variation + cross_direction * base_strength * sin(time_value * 0.43 + _wind_phase_b) * 0.08


func _effective_asymmetry() -> Vector3:
	var explicit: Vector3 = config["asymmetry_vector"]
	var inferred_strength: float = (
		(1.0 - float(config["fin_symmetry"])) * 0.42
		+ (1.0 - float(config["fin_alignment"])) * 0.31
		+ (1.0 - float(config["fin_height_consistency"])) * 0.16
		+ (1.0 - float(config["nose_alignment"])) * 0.11
	)
	var inferred: Vector3 = _seeded_asymmetry_direction * inferred_strength * 0.62
	return (explicit + inferred).limit_length(1.0)


func _controlled_wobble() -> Vector3:
	return Vector3(
		sin(total_elapsed * 3.1 + _wind_phase_a),
		cos(total_elapsed * 2.3 + _wind_phase_b),
		sin(total_elapsed * 3.7 + _wind_phase_a * 0.7)
	)


func _initial_mass() -> float:
	return lerpf(0.72, 1.0, float(config["water_level"]))


func _update_abstract_mass(thrusting: bool) -> void:
	if not thrusting:
		return
	var progress: float = clampf(state_elapsed / maxf(_thrust_duration(), FIXED_STEP), 0.0, 1.0)
	var released_fraction: float = float(config["water_level"]) * 0.34 * progress
	abstract_mass = maxf(0.52, _initial_mass() - released_fraction)


func _anticipation_duration() -> float:
	return lerpf(0.40, 0.95, float(config["anticipation_level"]))


func _thrust_duration() -> float:
	var duration_bias: float = float(config["water_level"]) * 0.62 + float(config["energy_level"]) * 0.38
	return lerpf(0.46, 0.94, duration_bias)


func _thrust_amount() -> float:
	if flight_state != FlightState.THRUST:
		return 0.0
	var progress: float = clampf(state_elapsed / maxf(_thrust_duration(), FIXED_STEP), 0.0, 1.0)
	var attack: float = clampf(progress / 0.10, 0.0, 1.0)
	var release: float = pow(1.0 - progress, 0.72)
	return clampf(attack * release, 0.0, 1.0)


func _jet_amount() -> float:
	return _thrust_amount() * float(config["water_level"])


func _should_impact_ground() -> bool:
	if not _has_left_ground:
		return flight_state == FlightState.DESCENT and state_elapsed > 0.7
	return flight_transform.origin.y <= _ground_height and linear_velocity.y <= 0.0


func _clear_dynamics() -> void:
	last_thrust_force = Vector3.ZERO
	last_drag_force = Vector3.ZERO
	last_wind_force = Vector3.ZERO
	last_gravity_force = Vector3.ZERO
	last_stability_torque = Vector3.ZERO
	last_asymmetry_torque = Vector3.ZERO


func _is_vector_finite(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)


func _is_basis_finite(value: Basis) -> bool:
	return _is_vector_finite(value.x) and _is_vector_finite(value.y) and _is_vector_finite(value.z)
