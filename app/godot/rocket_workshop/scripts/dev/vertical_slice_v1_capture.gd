extends SceneTree

const MAIN_SCENE := "res://scenes/vertical_slice_v1/vertical_slice_main.tscn"
const FIELD_SCENE := "res://scenes/vertical_slice_v1/field_test_scene.tscn"
const MetricsScript := preload("res://scripts/assembly/assembly_metrics.gd")
const SimulatorScript := preload("res://scripts/launch/bottle_rocket_simulator.gd")
const OUTPUT_DIR := "res://../../..//docs/builds/screenshots"

enum Stage { WORKSHOP, ATTACHED, FIELD_PREP, THRUST, COMPARISON, DONE }

var _stage: Stage = Stage.WORKSHOP
var _stage_frames := 0
var _total_frames := 0
var _main: Node
var _field: Node
var _launch_requested := false
var _flight_complete := false
var _thrust_frames := 0


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_main = (load(MAIN_SCENE) as PackedScene).instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_total_frames += 1
	_stage_frames += 1
	if _total_frames > 1100:
		printerr("VS1 capture timed out")
		quit(1)
		return true

	match _stage:
		Stage.WORKSHOP:
			if _stage_frames >= 45:
				_capture("workshop_v1.png")
				var stable: Resource = load("res://resources/flight/stable_profile.tres")
				var snapshot: Dictionary = stable.call("to_configuration_snapshot")
				_main.experience_state.call("restore_configuration", snapshot)
				_main.workshop.call("restore_from_configuration", snapshot)
				_next(Stage.ATTACHED)
		Stage.ATTACHED:
			if _stage_frames >= 45:
				_capture("fin_attachment_v1.png")
				_create_field()
				_next(Stage.FIELD_PREP)
		Stage.FIELD_PREP:
			if _stage_frames >= 45:
				_capture("launch_preparation_v1.png")
				_launch_requested = bool(_field.call("request_developer_launch"))
				_next(Stage.THRUST)
		Stage.THRUST:
			if _launch_requested and _field.sequence.current_state == &"THRUST":
				_thrust_frames += 1
			if _thrust_frames >= 28:
				_capture("launch_v1.png")
				_next(Stage.COMPARISON)
		Stage.COMPARISON:
			if _flight_complete and _stage_frames >= 36:
				_capture("trajectory_comparison_v1.png")
				_next(Stage.DONE)
		Stage.DONE:
			print("Vertical slice v1 screenshots captured.")
			quit(0)
			return true
	return false


func _create_field() -> void:
	_main.queue_free()
	_main = null
	var stable: Resource = load("res://resources/flight/stable_profile.tres")
	var snapshot: Dictionary = stable.call("to_configuration_snapshot")
	_field = (load(FIELD_SCENE) as PackedScene).instantiate()
	root.add_child(_field)
	_field.launch_completed.connect(_on_launch_completed)
	_field.call("setup", snapshot, MetricsScript.evaluate(snapshot), 4242, [])
	_field.call("set_active", true)
	_field.call("apply_developer_energy", 0.76)


func _on_launch_completed(_summary: Dictionary) -> void:
	var stable_attempt := _simulate_profile("stable")
	var lateral_attempt := _simulate_profile("lateral")
	var attempts: Array[Dictionary] = [stable_attempt, lateral_attempt]
	_field.trajectory_renderer.call("render_attempts", attempts)
	_field.camera_controller.call("frame_trajectory", _field.trajectory_renderer.call("get_all_points"))
	_field.camera_controller.call("set_phase", &"REVIEW")
	_flight_complete = true
	_stage_frames = 0


func _simulate_profile(profile_id: String) -> Dictionary:
	var profile: Resource = load("res://resources/flight/%s_profile.tres" % profile_id)
	var configuration: Dictionary = profile.call("to_configuration_snapshot")
	var metrics: Dictionary = MetricsScript.evaluate(configuration)
	var simulator_config: Dictionary = _field.call("_to_simulator_config", configuration, metrics)
	var simulator: RefCounted = SimulatorScript.new()
	var start := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.61, 0.0))
	simulator.call("setup", simulator_config, 4242, start, 0.61)
	simulator.call("launch")
	var samples: Array[Dictionary] = []
	var apex := start.origin
	var impact := start.origin
	for index: int in range(2600):
		simulator.call("advance_fixed_steps", 1)
		var snapshot: Dictionary = simulator.call("get_snapshot")
		var position: Vector3 = snapshot.position
		if position.y > apex.y:
			apex = position
		impact = position
		if index % 4 == 0:
			samples.append({"position": position, "elapsed": snapshot.elapsed, "state": snapshot.state})
		if simulator.call("is_finished"):
			break
	return {"samples": samples, "apex_position": apex, "impact_position": impact, "attempt_id": profile_id}


func _capture(filename: String) -> void:
	var image: Image = root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIR, filename]
	var error := image.save_png(path)
	if error != OK:
		printerr("VS1 capture failed %s error=%d" % [filename, error])
		quit(1)
		return
	print("CAPTURED %s" % ProjectSettings.globalize_path(path))


func _next(next_stage: Stage) -> void:
	_stage = next_stage
	_stage_frames = 0
