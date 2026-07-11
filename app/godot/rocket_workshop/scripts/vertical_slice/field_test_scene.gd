extends Node3D
class_name VS1FieldTestScene

signal state_changed(previous_state: StringName, new_state: StringName, context: Dictionary)
signal energy_changed(level: float)
signal launch_completed(summary: Dictionary)
signal review_ready(summary: Dictionary)
signal return_requested(summary: Dictionary)
signal tactile_event(event_name: String, world_position: Vector3)

const STAND_ASSET := "res://assets_3d/export/v2/launch_stand.glb"
const BOTTLE_ASSET := "res://assets_3d/export/v2/pet_bottle.glb"
const FIN_ASSET := "res://assets_3d/export/v2/cardboard_fin.glb"
const NOSE_ASSET := "res://assets_3d/export/v2/paper_nose_cone.glb"
const BodyScript := preload("res://scripts/launch/bottle_rocket_body.gd")
const SequenceScript := preload("res://scripts/launch/launch_sequence_controller.gd")
const CameraScript := preload("res://scripts/launch/launch_camera_controller.gd")
const RendererScript := preload("res://scripts/launch/trajectory_renderer.gd")

var camera: Camera3D
var sequence: Node
var camera_controller: Node
var trajectory_renderer: Node3D
var rocket_body: Node3D

var _attempt_root: Node3D
var _configuration_snapshot: Dictionary = {}
var _metrics: Dictionary = {}
var _previous_attempts: Array[Dictionary] = []
var _energy_level := 0.08
var _lever_dragging := false
var _lever_visual: Node3D
var _indicator_material: StandardMaterial3D
var _jet: GPUParticles3D
var _jet_plume: MeshInstance3D
var _world_environment: WorldEnvironment
var _environment_resource: Environment


func _ready() -> void:
	_build_field()
	set_process_unhandled_input(true)


func setup(configuration_snapshot: Dictionary, metrics: Dictionary, seed: int, previous_attempts: Array = []) -> void:
	_configuration_snapshot = configuration_snapshot.duplicate(true)
	_metrics = metrics.duplicate(true)
	_previous_attempts.clear()
	for value: Variant in previous_attempts:
		if value is Dictionary:
			_previous_attempts.append(value.duplicate(true))
	_clear_attempt()
	_attempt_root = Node3D.new()
	_attempt_root.name = "AttemptRoot"
	add_child(_attempt_root)
	_build_launch_stand()
	_build_controls()
	_build_sequence(seed)
	_update_indicator()


func set_active(active: bool) -> void:
	visible = active
	if _world_environment != null:
		_world_environment.environment = _environment_resource if active else null
	if camera != null:
		camera.current = active
	set_process_unhandled_input(active)


func apply_developer_energy(level: float) -> void:
	if sequence == null:
		return
	var delta := clampf(level, 0.0, 1.0) - _energy_level
	if delta > 0.0:
		_energy_level = float(sequence.call("add_energy_gesture", delta))
		energy_changed.emit(_energy_level)
		_update_indicator()


func request_developer_launch() -> bool:
	if sequence == null:
		return false
	return bool(sequence.call("request_launch"))


func _build_field() -> void:
	_world_environment = WorldEnvironment.new()
	_world_environment.name = "FieldEnvironment"
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.20, 0.48, 0.78)
	sky_material.sky_horizon_color = Color(0.76, 0.88, 0.93)
	sky_material.ground_bottom_color = Color(0.11, 0.18, 0.10)
	sky_material.ground_horizon_color = Color(0.45, 0.60, 0.36)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.62
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_environment_resource = environment
	_world_environment.environment = environment
	add_child(_world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "FieldSun"
	sun.light_color = Color(1.0, 0.94, 0.80)
	sun.light_energy = 1.38
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	add_child(sun)

	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(42.0, 42.0)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.16, 0.31, 0.12)
	ground_material.roughness = 0.96
	var ground_visual := MeshInstance3D.new()
	ground_visual.name = "GrassField"
	ground_visual.mesh = ground_mesh
	ground_visual.material_override = ground_material
	add_child(ground_visual)

	var ground_body := StaticBody3D.new()
	ground_body.name = "FieldCollision"
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(42.0, 0.20, 42.0)
	ground_shape.shape = box
	ground_shape.position.y = -0.11
	ground_body.add_child(ground_shape)
	add_child(ground_body)

	camera = Camera3D.new()
	camera.name = "FieldCamera"
	camera.fov = 46.0
	camera.position = Vector3(6.6, 4.15, 7.25)
	camera.current = false
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.42, 0.0), Vector3.UP)


func _clear_attempt() -> void:
	if _attempt_root != null and is_instance_valid(_attempt_root):
		_attempt_root.queue_free()
	_attempt_root = null
	sequence = null
	camera_controller = null
	trajectory_renderer = null
	rocket_body = null
	_jet = null
	_jet_plume = null
	_lever_visual = null
	_lever_dragging = false
	_energy_level = 0.08


func _build_launch_stand() -> void:
	var packed: PackedScene = load(STAND_ASSET) as PackedScene
	if packed == null:
		push_error("VS1: launch_stand v2 ausente; sem fallback visual.")
		return
	var stand := packed.instantiate() as Node3D
	stand.name = "LaunchStandV2"
	_attempt_root.add_child(stand)
	_lever_visual = stand.find_child("Launch_Stand_Abstract_Lever", true, false) as Node3D

	_indicator_material = StandardMaterial3D.new()
	_indicator_material.albedo_color = Color(0.12, 0.24, 0.18, 0.76)
	_indicator_material.emission_enabled = true
	_indicator_material.emission = Color(0.06, 0.18, 0.10)
	_indicator_material.emission_energy_multiplier = 0.25
	var lens := SphereMesh.new()
	lens.radius = 0.075
	lens.height = 0.075
	lens.radial_segments = 18
	lens.rings = 8
	var indicator := MeshInstance3D.new()
	indicator.name = "AbstractEnergyGlow"
	indicator.position = Vector3(-0.42, 0.18, -0.06)
	indicator.mesh = lens
	indicator.material_override = _indicator_material
	_attempt_root.add_child(indicator)


func _build_controls() -> void:
	_add_control_area("EnergyLeverControl", &"lever", Vector3(0.45, 0.28, -0.02), Vector3(0.34, 0.62, 0.34))
	_add_control_area("LaunchButtonControl", &"launch", Vector3(-0.42, 0.20, -0.18), Vector3(0.30, 0.24, 0.30))


func _add_control_area(control_name: String, control_id: StringName, position_value: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = control_name
	area.collision_layer = 4
	area.collision_mask = 0
	area.input_ray_pickable = true
	area.position = position_value
	area.set_meta(&"field_control", control_id)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	_attempt_root.add_child(area)


func _build_sequence(seed: int) -> void:
	sequence = SequenceScript.new()
	sequence.name = "LaunchSequenceController"
	_attempt_root.add_child(sequence)
	trajectory_renderer = RendererScript.new()
	trajectory_renderer.name = "TrajectoryRenderer"
	_attempt_root.add_child(trajectory_renderer)
	trajectory_renderer.call("configure", {"opacity": 0.76, "marker_scale": 0.48}, seed)
	camera_controller = CameraScript.new()
	camera_controller.name = "LaunchCameraController"
	_attempt_root.add_child(camera_controller)

	var simulator_config := _to_simulator_config(_configuration_snapshot, _metrics)
	simulator_config["energy_level"] = _energy_level
	simulator_config["review_hold"] = 0.42
	sequence.call("set_trajectory_renderer", trajectory_renderer)
	sequence.call("set_camera_controller", camera_controller)
	sequence.call("configure", simulator_config, seed, Callable(self, "_create_rocket_body"))
	sequence.state_changed.connect(_on_sequence_state_changed)
	sequence.energy_feedback_changed.connect(_on_energy_feedback_changed)
	sequence.jet_visual_requested.connect(_on_jet_visual_requested)
	sequence.launch_completed.connect(_on_launch_completed)
	sequence.review_ready.connect(_on_review_ready)
	sequence.return_to_workshop_requested.connect(_on_return_requested)
	sequence.fail_safe_triggered.connect(_on_fail_safe)
	sequence.call("begin_preparation")
	rocket_body = sequence.rocket_body
	camera_controller.call("configure", camera, rocket_body, {"follow_distance": 0.60, "follow_height": 0.55, "smoothing": 0.68, "shake": 0.48}, seed)


func _create_rocket_body(_normalized_config: Dictionary, _seed: int) -> Node3D:
	var body := BodyScript.new()
	body.name = "BottleRocketRigidBody"
	body.position = Vector3(0.0, 0.61, 0.0)
	body.collision_layer = 8
	body.collision_mask = 16
	var collision := CollisionShape3D.new()
	collision.name = "RocketCollision"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.40
	capsule.height = 2.58
	collision.shape = capsule
	collision.position.y = 1.31
	body.add_child(collision)

	var visual_root := Node3D.new()
	visual_root.name = "AssembledRocketVisual"
	body.add_child(visual_root)
	var bottle_visual := _instantiate_asset(BOTTLE_ASSET, "PetBottleV2")
	if bottle_visual != null:
		bottle_visual.position.y = 1.33
		visual_root.add_child(bottle_visual)

	for fin_state: Dictionary in _configuration_snapshot.get("fins", []):
		if not bool(fin_state.get("attached", false)):
			continue
		var fin_visual := _instantiate_asset(FIN_ASSET, "Fin_%s" % String(fin_state.get("fin_id", "")))
		if fin_visual == null:
			continue
		var angle := float(fin_state.get("angular_position", 0.0)) * TAU
		var height_offset := (float(fin_state.get("height", 0.5)) - 0.5) * 0.34
		fin_visual.position = Vector3(cos(angle) * 0.41, 0.64 + height_offset, sin(angle) * 0.41)
		fin_visual.rotation = Vector3(float(fin_state.get("tilt", 0.0)) * deg_to_rad(12.0), -angle, float(fin_state.get("orientation", 0.0)) * deg_to_rad(12.0))
		visual_root.add_child(fin_visual)
		if bool(fin_state.get("fixed", false)):
			_add_tape_band(visual_root, 0.66 + height_offset, float(fin_state.get("attachment_quality", 0.0)))

	var cone_state: Dictionary = _configuration_snapshot.get("cone", {})
	if bool(cone_state.get("present", false)):
		var cone_visual := _instantiate_asset(NOSE_ASSET, "PaperNoseConeV2")
		if cone_visual != null:
			cone_visual.position.y = 2.76
			var deviation := float(cone_state.get("angular_deviation", 0.0)) * deg_to_rad(10.0)
			cone_visual.rotation = Vector3(deviation, 0.0, -deviation * 0.55)
			visual_root.add_child(cone_visual)

	_add_water_visual(visual_root, float(_configuration_snapshot.get("water_level", 0.0)))
	_add_jet(body)
	return body


func _instantiate_asset(path: String, node_name: String) -> Node3D:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		push_error("VS1: asset obrigatório não carregou: %s" % path)
		return null
	var instance := packed.instantiate() as Node3D
	instance.name = node_name
	return instance


func _add_tape_band(parent: Node3D, local_y: float, quality: float) -> void:
	var mesh := ImmediateMesh.new()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.90, 0.84, 0.60, 0.42 + quality * 0.38)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.32
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	for index: int in range(33):
		var angle := TAU * float(index) / 32.0
		var radial := Vector3(cos(angle) * 0.425, 0.0, sin(angle) * 0.425)
		mesh.surface_set_normal(radial.normalized())
		mesh.surface_add_vertex(radial + Vector3(0.0, local_y - 0.045, 0.0))
		mesh.surface_add_vertex(radial + Vector3(0.0, local_y + 0.045, 0.0))
	mesh.surface_end()
	var band := MeshInstance3D.new()
	band.name = "AppliedTapeBand"
	band.mesh = mesh
	parent.add_child(band)


func _add_water_visual(parent: Node3D, level: float) -> void:
	if level <= 0.005:
		return
	var liquid := CylinderMesh.new()
	liquid.top_radius = 0.30
	liquid.bottom_radius = 0.30
	liquid.height = 2.02 * level
	liquid.radial_segments = 24
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.55, 0.92, 0.58)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.10
	var visual := MeshInstance3D.new()
	visual.name = "WaterInsideBottle"
	visual.mesh = liquid
	visual.material_override = material
	visual.position.y = 0.35 + level * 1.01
	parent.add_child(visual)


func _add_jet(body: Node3D) -> void:
	var process_material := ParticleProcessMaterial.new()
	process_material.direction = Vector3(0.0, -1.0, 0.0)
	process_material.spread = 22.0
	process_material.initial_velocity_min = 2.8
	process_material.initial_velocity_max = 4.8
	process_material.gravity = Vector3(0.0, -2.8, 0.0)
	process_material.scale_min = 0.45
	process_material.scale_max = 1.25
	var drop := SphereMesh.new()
	drop.radius = 0.035
	drop.height = 0.085
	drop.radial_segments = 8
	drop.rings = 4
	var drop_material := StandardMaterial3D.new()
	drop_material.albedo_color = Color(0.45, 0.78, 1.0, 0.72)
	drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.material = drop_material
	_jet = GPUParticles3D.new()
	_jet.name = "VolumetricWaterJet"
	_jet.position.y = 0.08
	_jet.amount = 72
	_jet.lifetime = 0.46
	_jet.randomness = 0.46
	_jet.local_coords = true
	_jet.process_material = process_material
	_jet.draw_pass_1 = drop
	_jet.emitting = false
	body.add_child(_jet)

	# A translucent volume complements the individual droplets during the brief
	# thrust burst. It avoids the visual reading of a single blue line.
	var plume_mesh := CylinderMesh.new()
	plume_mesh.top_radius = 0.075
	plume_mesh.bottom_radius = 0.23
	plume_mesh.height = 0.72
	plume_mesh.radial_segments = 18
	var plume_material := StandardMaterial3D.new()
	plume_material.albedo_color = Color(0.28, 0.72, 1.0, 0.34)
	plume_material.emission_enabled = true
	plume_material.emission = Color(0.16, 0.58, 1.0)
	plume_material.emission_energy_multiplier = 0.55
	plume_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plume_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_jet_plume = MeshInstance3D.new()
	_jet_plume.name = "WaterSprayVolume"
	_jet_plume.mesh = plume_mesh
	_jet_plume.material_override = plume_material
	_jet_plume.position.y = -0.28
	_jet_plume.visible = false
	_jet_plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(_jet_plume)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or sequence == null or sequence.current_state != &"PREPARED":
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			var control := _pick_control(button.position)
			if control == &"lever":
				_lever_dragging = true
				_apply_energy_gesture(0.055)
				get_viewport().set_input_as_handled()
			elif control == &"launch":
				if _energy_level >= 0.30 and bool(sequence.call("request_launch")):
					tactile_event.emit("anticipation", Vector3.ZERO)
				else:
					_pulse_indicator()
				get_viewport().set_input_as_handled()
		else:
			_lever_dragging = false
			_reset_lever()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and _lever_dragging:
		_apply_energy_gesture(clampf(absf(motion.relative.y) * 0.0025 + absf(motion.relative.x) * 0.0012, 0.0, 0.09))
		if _lever_visual != null:
			_lever_visual.rotation.z = clampf(_lever_visual.rotation.z - motion.relative.y * 0.004, -0.48, 0.28)
		get_viewport().set_input_as_handled()


func _pick_control(pointer: Vector2) -> StringName:
	var from := camera.project_ray_origin(pointer)
	var to := from + camera.project_ray_normal(pointer) * 80.0
	var query := PhysicsRayQueryParameters3D.create(from, to, 4)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return &""
	var collider: Object = result.get("collider") as Object
	return StringName(str(collider.get_meta(&"field_control", ""))) if collider != null else &""


func _apply_energy_gesture(amount: float) -> void:
	_energy_level = float(sequence.call("add_energy_gesture", amount))
	energy_changed.emit(_energy_level)
	_update_indicator()


func _on_energy_feedback_changed(level: float) -> void:
	_energy_level = level
	_update_indicator()


func _update_indicator() -> void:
	if _indicator_material == null:
		return
	var ready := _energy_level >= 0.30
	_indicator_material.emission = Color(0.12, 0.92, 0.48) if ready else Color(0.06, 0.18 + _energy_level * 0.62, 0.12)
	_indicator_material.emission_energy_multiplier = 0.25 + _energy_level * 1.55
	_indicator_material.albedo_color = Color(0.16, 0.80, 0.40, 0.85) if ready else Color(0.10, 0.24, 0.16, 0.72)


func _pulse_indicator() -> void:
	if _indicator_material == null:
		return
	var tween := create_tween()
	tween.tween_property(_indicator_material, "emission_energy_multiplier", 1.5, 0.10)
	tween.tween_property(_indicator_material, "emission_energy_multiplier", 0.25 + _energy_level * 1.55, 0.24)


func _reset_lever() -> void:
	if _lever_visual == null:
		return
	create_tween().tween_property(_lever_visual, "rotation:z", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_sequence_state_changed(previous: StringName, next_state: StringName, context: Dictionary) -> void:
	state_changed.emit(previous, next_state, context)
	if next_state == &"THRUST":
		tactile_event.emit("launch", rocket_body.global_position if rocket_body != null else Vector3.ZERO)
	elif next_state == &"IMPACT":
		tactile_event.emit("impact", rocket_body.global_position if rocket_body != null else Vector3.ZERO)


func _on_jet_visual_requested(amount: float, _origin: Vector3, _direction: Vector3) -> void:
	if _jet != null:
		_jet.emitting = amount > 0.015
		_jet.amount_ratio = clampf(amount * 1.35, 0.0, 1.0)
	if _jet_plume != null:
		_jet_plume.visible = amount > 0.025
		_jet_plume.scale.y = 0.35 + clampf(amount, 0.0, 1.0) * 0.85


func _on_launch_completed(summary: Dictionary) -> void:
	var attempts := _previous_attempts.duplicate(true)
	attempts.append(summary.duplicate(true))
	while attempts.size() > 2:
		attempts.pop_front()
	trajectory_renderer.call("render_attempts", attempts)
	launch_completed.emit(summary)


func _on_review_ready(summary: Dictionary) -> void:
	review_ready.emit(summary)


func _on_return_requested(_config: Dictionary, summary: Dictionary) -> void:
	return_requested.emit(summary)


func _on_fail_safe(reason: StringName, _context: Dictionary) -> void:
	push_warning("VS1 flight fail-safe: %s" % String(reason))


func _to_simulator_config(configuration: Dictionary, metrics: Dictionary) -> Dictionary:
	var asymmetry: Dictionary = metrics.get("asymmetry_vector", {})
	return {
		"energy_level": float(configuration.get("energy_level", 0.0)),
		"water_level": float(configuration.get("water_level", 0.0)),
		"fin_presence": clampf(float(metrics.get("fin_count", 0)) / 3.0, 0.0, 1.0),
		"fin_symmetry": float(metrics.get("fin_spacing_score", 0.0)),
		"fin_alignment": (float(metrics.get("fin_tilt_score", 0.0)) + float(metrics.get("fin_orientation_score", 0.0))) * 0.5,
		"fin_height_consistency": float(metrics.get("fin_height_score", 0.0)),
		"attachment_quality": float(metrics.get("attachment_score", 0.0)),
		"nose_alignment": float(metrics.get("cone_alignment_score", 0.45)),
		"mass_balance": clampf(1.0 - float(metrics.get("asymmetry_magnitude", 0.0)) * 0.72, 0.0, 1.0),
		"body_drag": clampf(0.28 + (1.0 - float(metrics.get("stability_score", 0.0))) * 0.38, 0.0, 1.0),
		"wind_level": 0.14,
		"anticipation_level": 0.52,
		"asymmetry_vector": {"x": float(asymmetry.get("x", 0.0)), "y": 0.0, "z": float(asymmetry.get("y", 0.0))},
	}
