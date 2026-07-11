extends RigidBody3D
class_name VS1BottleRocketBody

## RigidBody3D bridge for the deterministic vertical-slice simulator. The body
## owns collision reporting and exposes visual/audio callbacks through signals;
## the headless model remains the single source of flight motion.

signal flight_state_changed(previous_state: StringName, new_state: StringName, snapshot: Dictionary)
signal trajectory_sample(snapshot: Dictionary)
signal jet_visual_requested(amount: float, origin: Vector3, direction: Vector3)
signal apex_reached(position: Vector3, elapsed: float)
signal impact_reached(position: Vector3, elapsed: float, reason: StringName)
signal review_ready(snapshot: Dictionary)
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

const SimulatorScript := preload("res://scripts/launch/bottle_rocket_simulator.gd")

var flight_state: int = FlightState.PREPARED
var normalized_config: Dictionary = {}
var flight_seed: int = 1
var simulator: RefCounted = null

var _prepared_transform: Transform3D = Transform3D.IDENTITY
var _ground_height: float = 0.0
var _is_configured: bool = false


func _ready() -> void:
	custom_integrator = true
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = maxi(max_contacts_reported, 4)
	continuous_cd = true
	can_sleep = false
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func prepare(
	config_snapshot: Dictionary,
	seed_value: int,
	start_transform: Transform3D = Transform3D.IDENTITY,
	ground_height: float = NAN
) -> void:
	normalized_config = SimulatorScript.normalize_config(config_snapshot)
	flight_seed = seed_value
	_prepared_transform = start_transform
	if start_transform == Transform3D.IDENTITY and is_inside_tree():
		_prepared_transform = global_transform
	_ground_height = _prepared_transform.origin.y if is_nan(ground_height) else ground_height
	global_transform = _prepared_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false
	freeze = false

	simulator = SimulatorScript.new()
	_connect_simulator()
	simulator.setup(normalized_config, flight_seed, _prepared_transform, _ground_height)
	flight_state = FlightState.PREPARED
	mass = float(simulator.abstract_mass)
	_is_configured = true


func start_anticipation() -> bool:
	if not _is_configured or simulator == null:
		_emit_local_fail_safe(&"body_not_prepared")
		return false
	return bool(simulator.launch())


func register_external_impact(position: Vector3, reason: StringName = &"external_collision") -> void:
	if simulator != null:
		simulator.register_impact(position, reason)


func force_safe_finish(reason: StringName = &"body_timeout") -> void:
	if simulator == null:
		_emit_local_fail_safe(reason)
		return
	simulator.force_safe_finish(reason)


func reset_to_prepared() -> void:
	prepare(normalized_config, flight_seed, _prepared_transform, _ground_height)


func get_snapshot() -> Dictionary:
	if simulator == null:
		return {
			"state": &"PREPARED",
			"state_id": FlightState.PREPARED,
			"position": global_position,
			"transform": global_transform,
			"velocity": linear_velocity,
			"angular_velocity": angular_velocity,
			"seed": flight_seed,
		}
	return simulator.get_snapshot()


func get_state_name() -> StringName:
	if simulator == null:
		return &"PREPARED"
	return simulator.get_state_name()


func is_finished() -> bool:
	return simulator != null and simulator.is_finished()


func _integrate_forces(direct_state: PhysicsDirectBodyState3D) -> void:
	if simulator == null:
		direct_state.linear_velocity = Vector3.ZERO
		direct_state.angular_velocity = Vector3.ZERO
		return

	simulator.advance(direct_state.step)
	var snapshot: Dictionary = simulator.get_snapshot()
	var next_transform: Transform3D = snapshot.get("transform", direct_state.transform)
	var next_velocity: Vector3 = snapshot.get("velocity", Vector3.ZERO)
	var next_angular_velocity: Vector3 = snapshot.get("angular_velocity", Vector3.ZERO)
	if not _is_safe_transform(next_transform) or not _is_safe_vector(next_velocity) or not _is_safe_vector(next_angular_velocity):
		simulator.force_safe_finish(&"invalid_body_snapshot")
		snapshot = simulator.get_snapshot()
		next_transform = snapshot.get("transform", _prepared_transform)
		next_velocity = snapshot.get("velocity", Vector3.ZERO)
		next_angular_velocity = snapshot.get("angular_velocity", Vector3.ZERO)

	direct_state.transform = next_transform
	direct_state.linear_velocity = next_velocity
	direct_state.angular_velocity = next_angular_velocity
	mass = maxf(0.05, float(snapshot.get("abstract_mass", 1.0)))


func _connect_simulator() -> void:
	if simulator == null:
		return
	simulator.state_changed.connect(_on_simulator_state_changed)
	simulator.sample_ready.connect(_on_simulator_sample_ready)
	simulator.jet_changed.connect(_on_simulator_jet_changed)
	simulator.apex_reached.connect(_on_simulator_apex_reached)
	simulator.impact_reached.connect(_on_simulator_impact_reached)
	simulator.simulation_finished.connect(_on_simulator_finished)
	simulator.fail_safe_triggered.connect(_on_simulator_fail_safe)


func _on_simulator_state_changed(previous_state: int, new_state: int, snapshot: Dictionary) -> void:
	flight_state = new_state
	flight_state_changed.emit(
		SimulatorScript.state_name(previous_state),
		SimulatorScript.state_name(new_state),
		snapshot
	)


func _on_simulator_sample_ready(snapshot: Dictionary) -> void:
	trajectory_sample.emit(snapshot)


func _on_simulator_jet_changed(amount: float, origin: Vector3, direction: Vector3) -> void:
	jet_visual_requested.emit(amount, origin, direction)


func _on_simulator_apex_reached(position: Vector3, elapsed: float) -> void:
	apex_reached.emit(position, elapsed)


func _on_simulator_impact_reached(position: Vector3, elapsed: float, reason: StringName) -> void:
	impact_reached.emit(position, elapsed, reason)


func _on_simulator_finished(snapshot: Dictionary) -> void:
	review_ready.emit(snapshot)


func _on_simulator_fail_safe(reason: StringName, snapshot: Dictionary) -> void:
	fail_safe_triggered.emit(reason, snapshot)


func _on_body_entered(_other_body: Node) -> void:
	if simulator == null:
		return
	var state_name: StringName = simulator.get_state_name()
	if state_name == &"COAST" or state_name == &"APEX" or state_name == &"DESCENT":
		simulator.register_impact(global_position, &"rigid_body_collision")
	elif state_name == &"THRUST" and float(simulator.state_elapsed) > 0.12:
		simulator.register_impact(global_position, &"rigid_body_collision")


func _emit_local_fail_safe(reason: StringName) -> void:
	var snapshot: Dictionary = get_snapshot()
	snapshot["fail_safe_reason"] = reason
	fail_safe_triggered.emit(reason, snapshot)


func _is_safe_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)


func _is_safe_transform(value: Transform3D) -> bool:
	return (
		_is_safe_vector(value.origin)
		and _is_safe_vector(value.basis.x)
		and _is_safe_vector(value.basis.y)
		and _is_safe_vector(value.basis.z)
	)
