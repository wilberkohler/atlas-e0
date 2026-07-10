extends Node
class_name LaunchController

signal launch_started(profile: String)
signal launch_finished(profile: String)

const AssemblyEvaluatorScript := preload("res://scripts/assembly/assembly_evaluator.gd")
const TrajectoryProfileScript := preload("res://scripts/launch/trajectory_profile.gd")

var assembly: Node = null
var telemetry: Node = null
var launch_stand: Node = null
var launching: bool = false
var _home_position: Vector3 = Vector3.ZERO
var _home_rotation: Vector3 = Vector3.ZERO


func configure(new_assembly: Node, new_telemetry: Node, new_launch_stand: Node) -> void:
	assembly = new_assembly
	telemetry = new_telemetry
	launch_stand = new_launch_stand
	if assembly != null:
		_home_position = assembly.position
		_home_rotation = assembly.rotation_degrees


func request_launch() -> void:
	if launching or assembly == null:
		return
	if not assembly.is_ready_for_launch():
		if telemetry != null:
			telemetry.record("launch_blocked", "not_ready", assembly.get_summary())
		return

	var evaluation: Dictionary = AssemblyEvaluatorScript.evaluate(assembly)
	var trajectory: String = String(evaluation.get("trajectory", "short_unstable"))
	var profile: Resource = TrajectoryProfileScript.from_id(trajectory)
	if telemetry != null:
		telemetry.record_launch(trajectory, evaluation)

	launching = true
	launch_started.emit(trajectory)
	_play_launch(profile)


func set_ready_visual(ready: bool) -> void:
	if launch_stand != null and launch_stand.has_method("set_ready_visual"):
		launch_stand.call("set_ready_visual", ready)


func _play_launch(profile: Resource) -> void:
	_home_position = assembly.position
	_home_rotation = assembly.rotation_degrees
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(assembly, "position", _home_position + profile.apex, profile.duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(assembly, "rotation_degrees", _home_rotation + profile.rotation_degrees, profile.duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.set_parallel(false)
	tween.tween_interval(0.28)
	tween.set_parallel(true)
	tween.tween_property(assembly, "position", _home_position, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(assembly, "rotation_degrees", _home_rotation, 0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_launch_tween_finished.bind(profile.id))


func _on_launch_tween_finished(profile_id: String) -> void:
	launching = false
	launch_finished.emit(profile_id)
