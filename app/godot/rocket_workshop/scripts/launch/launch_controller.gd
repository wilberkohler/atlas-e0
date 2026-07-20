extends Node
class_name LaunchController

signal launch_started(profile: String)
signal launch_finished(profile: String)
signal flight_metrics_updated(summary: Dictionary)

const AssemblyToFlightMapperScript := preload("res://scripts/flight/assembly_to_flight_mapper.gd")
const FlightModelScript := preload("res://scripts/flight/flight_model.gd")

var assembly: Node = null
var telemetry: Node = null
var launch_stand: Node = null
var camera_rig: Node = null
var launching: bool = false

var _home_position: Vector3 = Vector3.ZERO
var _home_rotation_degrees: Vector3 = Vector3.ZERO
var _flight_model: RefCounted = null
var _launch_id: int = 0
var _resetting: bool = false


func configure(new_assembly: Node, new_telemetry: Node, new_launch_stand: Node, new_camera_rig: Node = null) -> void:
	assembly = new_assembly
	telemetry = new_telemetry
	launch_stand = new_launch_stand
	camera_rig = new_camera_rig
	if assembly != null:
		_home_position = assembly.position
		_home_rotation_degrees = assembly.rotation_degrees
	set_physics_process(true)


func request_launch() -> void:
	if launching or assembly == null:
		return
	if not assembly.is_ready_for_launch():
		if telemetry != null:
			telemetry.record("launch_blocked", "not_ready", assembly.get_summary())
		return

	_launch_id += 1
	var seed: int = 1000 + _launch_id * 7919
	var parameters: Resource = AssemblyToFlightMapperScript.map(assembly, seed)
	var session_id: String = "session_%d" % int(telemetry.session_started_at if telemetry != null else Time.get_unix_time_from_system())
	_flight_model = FlightModelScript.new()
	_flight_model.setup(_launch_id, session_id, parameters, _home_position, assembly.rotation)

	if telemetry != null:
		telemetry.record_launch("continuous", {
			"parameters": parameters.to_dict(),
			"assembly": assembly.get_summary()
		})

	launching = true
	_resetting = false
	set_ready_visual(false)
	if camera_rig != null:
		camera_rig.follow_launch(assembly)
	launch_started.emit("continuous")


func set_ready_visual(ready: bool) -> void:
	if launch_stand != null and launch_stand.has_method("set_ready_visual"):
		launch_stand.call("set_ready_visual", ready)


func _physics_process(delta: float) -> void:
	if _flight_model == null or assembly == null or _resetting:
		return

	_flight_model.step(delta)
	assembly.position = _flight_model.position
	assembly.rotation = _flight_model.rotation

	if _flight_model.impacted:
		_finish_flight()


func _finish_flight() -> void:
	if _flight_model == null or _resetting:
		return

	_resetting = true
	var summary: Dictionary = _flight_model.finish_summary()
	summary["height_graph"] = _flight_model.recorder.height_graph()
	summary["speed_graph"] = _flight_model.recorder.speed_graph()
	var profile: String = _classify_flight(summary, _flight_model.parameters)
	summary["profile"] = profile

	if telemetry != null:
		telemetry.record_flight_result(profile, summary)
	flight_metrics_updated.emit(summary)
	launch_finished.emit(profile)

	if camera_rig != null:
		camera_rig.show_result(assembly)

	var tween: Tween = create_tween()
	tween.tween_interval(1.15)
	tween.tween_property(assembly, "position", _home_position, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(assembly, "rotation_degrees", _home_rotation_degrees, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_reset_finished)


func _on_reset_finished() -> void:
	_flight_model = null
	_resetting = false
	launching = false
	if camera_rig != null:
		camera_rig.show_bench()
	if assembly != null:
		set_ready_visual(assembly.is_ready_for_launch())


func _classify_flight(summary: Dictionary, parameters: Resource) -> String:
	var height: float = float(summary.get("max_height", 0.0))
	var mean_spin: float = float(summary.get("mean_angular_velocity", 0.0))
	if height >= 4.0 and mean_spin <= 1.25 and int(parameters.fin_count) >= 3:
		return "stable"
	if height >= 1.8:
		return "reasonable_spin"
	return "short_unstable"
