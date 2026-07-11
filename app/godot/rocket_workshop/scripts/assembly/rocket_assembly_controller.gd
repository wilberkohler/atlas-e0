extends Node3D
class_name VS1RocketAssemblyController

signal configuration_changed(snapshot: Dictionary, metrics: Dictionary)
signal readiness_changed(ready: bool)
signal rocket_placed(configuration_snapshot: Dictionary)
signal interaction_event(part_id: String, kind: String, payload: Dictionary)
signal tactile_event(event_name: String, world_position: Vector3)

const OBJECT_SCENES := {
	"bottle": "res://scenes/objects/pet_bottle_interactive.tscn",
	"fin": "res://scenes/objects/fin_interactive.tscn",
	"nose": "res://scenes/objects/nose_cone_interactive.tscn",
	"tape": "res://scenes/objects/tape_roll_interactive.tscn",
	"water": "res://scenes/objects/water_container_interactive.tscn",
	"stand": "res://scenes/objects/launch_stand_interactive.tscn",
}
const WORKBENCH_ASSET := "res://assets_3d/export/v2/workbench.glb"
const GrabberScript := preload("res://scripts/interaction/object_grabber_3d.gd")
const MetricsScript := preload("res://scripts/assembly/assembly_metrics.gd")

var camera: Camera3D
var configuration: RefCounted
var grabber: Node
var bottle: Node3D
var fins: Array[Node3D] = []
var nose: Node3D
var tape: Node3D
var water_container: Node3D
var launch_stand: Node3D

var _ready_for_test := false
var _placed_on_stand := false
var _built := false
var _home_bottle_transform := Transform3D.IDENTITY
var _rest_transforms: Dictionary = {}
var _world_environment: WorldEnvironment
var _environment_resource: Environment


func _ready() -> void:
	_build_environment()


func setup(new_configuration: RefCounted) -> void:
	configuration = new_configuration
	if configuration != null and not configuration.changed.is_connected(_on_configuration_changed):
		configuration.changed.connect(_on_configuration_changed)
	if not _built:
		_spawn_workshop()
	_apply_configuration_visual(configuration.call("snapshot") if configuration != null else {})
	_update_readiness()


func set_active(active: bool) -> void:
	visible = active
	if _world_environment != null:
		_world_environment.environment = _environment_resource if active else null
	if camera != null:
		camera.current = active
	if grabber != null:
		grabber.call("set_enabled", active)


func prepare_for_retry() -> void:
	_placed_on_stand = false
	var stand_zone: Node = launch_stand.get_node_or_null(^"RocketSnap") if launch_stand != null else null
	if stand_zone != null and stand_zone.has_method("release_object"):
		stand_zone.call("release_object", bottle, false)
	if bottle != null:
		bottle.call("detach")
		bottle.set_physics_process(true)
		bottle.reparent(self, true)
		bottle.target_position = _home_bottle_transform.origin
		bottle.target_rotation = _home_bottle_transform.basis.get_euler()
	_update_readiness()


func restore_from_configuration(snapshot: Dictionary) -> void:
	if configuration != null:
		configuration.call("apply_snapshot", snapshot, false)
	_reset_loose_parts()
	_apply_configuration_visual(snapshot)
	_update_readiness()


func get_camera() -> Camera3D:
	return camera


func get_metrics() -> Dictionary:
	return MetricsScript.evaluate(configuration) if configuration != null else {}


func get_configuration_snapshot() -> Dictionary:
	return configuration.call("snapshot") if configuration != null else {}


func is_ready_for_test() -> bool:
	return _ready_for_test


func _build_environment() -> void:
	_world_environment = WorldEnvironment.new()
	_world_environment.name = "WorkshopEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.17, 0.20, 0.19)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.88, 0.82, 0.70)
	environment.ambient_light_energy = 0.52
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	_environment_resource = environment
	_world_environment.environment = environment
	add_child(_world_environment)

	var key := DirectionalLight3D.new()
	key.name = "WarmWindowLight"
	key.light_color = Color(1.0, 0.91, 0.76)
	key.light_energy = 1.28
	key.shadow_enabled = true
	key.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "CoolBenchFill"
	fill.light_color = Color(0.68, 0.84, 1.0)
	fill.light_energy = 1.35
	fill.omni_range = 7.5
	fill.position = Vector3(-2.8, 3.4, 2.4)
	add_child(fill)

	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(18.0, 18.0)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.16, 0.18, 0.17)
	floor_material.roughness = 0.92
	var floor := MeshInstance3D.new()
	floor.name = "WorkshopFloor"
	floor.mesh = floor_mesh
	floor.material_override = floor_material
	floor.position.y = -1.24
	add_child(floor)

	camera = Camera3D.new()
	camera.name = "WorkshopCamera"
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 42.0
	camera.position = Vector3(5.35, 4.25, 5.75)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(-0.05, 0.76, 0.03), Vector3.UP)


func _spawn_workshop() -> void:
	var bench_scene: PackedScene = load(WORKBENCH_ASSET) as PackedScene
	if bench_scene == null:
		push_error("VS1: workbench v2 não pôde ser carregado; sem fallback visual.")
		return
	var bench := bench_scene.instantiate() as Node3D
	bench.name = "WorkbenchV2"
	bench.position = Vector3(-0.25, 0.0, 0.0)
	add_child(bench)

	bottle = _spawn_object("bottle", "PetBottleAssembly", Vector3(-0.05, 1.34, 0.05), Vector3.ZERO)
	_home_bottle_transform = bottle.global_transform
	for index: int in range(3):
		var positions := [Vector3(-2.25, 0.49, -0.78), Vector3(-1.45, 0.49, -1.08), Vector3(-2.10, 0.49, 0.82)]
		var rotations := [Vector3(90.0, -18.0, 0.0), Vector3(90.0, 12.0, 0.0), Vector3(90.0, 30.0, 0.0)]
		var fin := _spawn_object("fin", "Fin%d" % [index + 1], positions[index], rotations[index])
		fin.part_id = StringName("fin_%d" % [index + 1])
		fins.append(fin)
	nose = _spawn_object("nose", "PaperNoseCone", Vector3(1.18, 0.12, -1.05), Vector3(0.0, -22.0, 0.0))
	tape = _spawn_object("tape", "TapeRoll", Vector3(-1.28, 0.18, 1.12), Vector3(90.0, 0.0, 12.0))
	water_container = _spawn_object("water", "WaterPitcher", Vector3(1.45, 0.53, -0.82), Vector3(0.0, 20.0, 0.0))
	launch_stand = _spawn_object("stand", "LaunchStandV2", Vector3(2.02, 0.42, 0.86), Vector3.ZERO)

	for part: Node3D in [bottle, nose, tape, water_container, launch_stand]:
		if part != null:
			_rest_transforms[String(part.part_id)] = part.global_transform
	for fin: Node3D in fins:
		_rest_transforms[String(fin.part_id)] = fin.global_transform

	_connect_parts_and_zones()
	grabber = GrabberScript.new()
	grabber.name = "ObjectGrabber3D"
	grabber.drag_plane_y = 0.10
	add_child(grabber)
	grabber.call("set_camera", camera)
	grabber.interaction.connect(_on_grabber_interaction)
	_built = true


func _spawn_object(kind: String, object_name: String, world_position: Vector3, rotation_degrees_value: Vector3) -> Node3D:
	var scene_path: String = OBJECT_SCENES[kind]
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("VS1: wrapper obrigatório ausente: %s" % scene_path)
		return null
	var part := packed.instantiate() as Node3D
	part.name = object_name
	part.position = world_position
	part.rotation_degrees = rotation_degrees_value
	add_child(part)
	part.target_position = part.global_position
	part.target_rotation = part.global_rotation
	return part


func _connect_parts_and_zones() -> void:
	for part: Node3D in [bottle, nose, tape, water_container]:
		_connect_part(part)
	for fin: Node3D in fins:
		_connect_part(fin)

	for zone: Node in get_tree().get_nodes_in_group(&"vs1_snap_zones"):
		if not is_ancestor_of(zone):
			continue
		if not zone.object_snapped.is_connected(_on_object_snapped):
			zone.object_snapped.connect(_on_object_snapped)
		if not zone.object_released.is_connected(_on_object_released):
			zone.object_released.connect(_on_object_released)

	var tape_controller: Node = tape.get_node_or_null(^"TapeGestureController") if tape != null else null
	if tape_controller != null:
		tape_controller.fixation_changed.connect(_on_fixation_changed)
	var water_controller: Node = water_container.get_node_or_null(^"WaterFillController") if water_container != null else null
	if water_controller != null:
		water_controller.water_level_changed.connect(_on_water_level_changed)


func _connect_part(part: Node3D) -> void:
	if part == null:
		return
	if not part.grab_started.is_connected(_on_part_grab_started):
		part.grab_started.connect(_on_part_grab_started)


func _on_part_grab_started(part: Node3D) -> void:
	if part != bottle and part.get_parent() == bottle:
		var preserved := part.global_transform
		part.reparent(self, true)
		part.global_transform = preserved
		part.target_position = preserved.origin
		part.target_rotation = preserved.basis.get_euler()
		part.set_physics_process(true)
		var loose_shadow: GeometryInstance3D = part.get_node_or_null(^"BlobShadow") as GeometryInstance3D
		if loose_shadow != null:
			loose_shadow.visible = true
	if part.part_kind == &"fin":
		configuration.call("mark_fin_repositioned", String(part.part_id))
	tactile_event.emit("cardboard" if part.part_kind == &"fin" else "plastic", part.global_position)


func _on_object_snapped(part: Node, zone: Node, quality: float) -> void:
	if part == null or configuration == null:
		return
	if part.part_kind == &"fin":
		var metadata: Dictionary = part.snap_metadata
		var angular_error: Vector3 = metadata.get("angular_error", Vector3.ZERO)
		var position_error: Vector3 = metadata.get("position_error", Vector3.ZERO)
		var angular_position := _zone_turn(String(zone.zone_id))
		configuration.call("set_fin", String(part.part_id), angular_position, clampf(angular_error.x / deg_to_rad(12.0), -1.0, 1.0), clampf(0.5 + position_error.y / 0.20, 0.0, 1.0), clampf(angular_error.z / deg_to_rad(12.0), -1.0, 1.0), quality * 0.42, false, true)
		_attach_to_bottle(part)
		tactile_event.emit("snap", part.global_position)
	elif part.part_kind == &"nose":
		var cone_error: Vector3 = part.snap_metadata.get("angular_error", Vector3.ZERO)
		var cone_offset: Vector3 = part.snap_metadata.get("position_error", Vector3.ZERO)
		var deviation := clampf(maxf(absf(cone_error.x), absf(cone_error.z)) / deg_to_rad(10.0), 0.0, 1.0)
		var centering := clampf(1.0 - Vector2(cone_offset.x, cone_offset.z).length() / 0.12, 0.0, 1.0)
		configuration.call("set_cone", true, deviation, centering, quality * 0.64, false)
		_attach_to_bottle(part)
		tactile_event.emit("snap", part.global_position)
	elif part == bottle and String(zone.zone_id) == "launch_stand":
		if _ready_for_test:
			_placed_on_stand = true
			grabber.call("set_enabled", false)
			rocket_placed.emit(configuration.call("snapshot"))
	_update_readiness()


func _attach_to_bottle(part: Node3D) -> void:
	var preserved: Transform3D = part.call("get_target_transform")
	part.global_transform = preserved
	part.reparent(bottle, true)
	part.global_transform = preserved
	part.target_position = part.global_position
	part.target_rotation = part.global_rotation
	part.set_physics_process(false)
	var attached_shadow: GeometryInstance3D = part.get_node_or_null(^"BlobShadow") as GeometryInstance3D
	if attached_shadow != null:
		attached_shadow.visible = false


func _on_object_released(part: Node, zone: Node) -> void:
	if configuration == null or part == null:
		return
	if part.part_kind == &"fin":
		configuration.call("remove_fin", String(part.part_id))
	elif part.part_kind == &"nose":
		configuration.call("remove_cone")
	elif part == bottle and String(zone.zone_id) == "launch_stand":
		_placed_on_stand = false
	_update_readiness()


func _on_fixation_changed(junction: Node3D, quality: float) -> void:
	var fin: Node = junction.occupied_object if junction != null else null
	if fin == null or fin.part_kind != &"fin":
		return
	var state: Dictionary = configuration.call("get_fin", String(fin.part_id))
	state["attachment_quality"] = quality
	state["fixed"] = quality >= 0.28
	configuration.call("update_fin", String(fin.part_id), state)
	tactile_event.emit("tape", junction.global_position)


func _on_water_level_changed(_receiver: Node, level: float, _visual_band: StringName) -> void:
	if configuration != null:
		configuration.call("set_water_level", level)


func _on_grabber_interaction(part: Node3D, kind: StringName) -> void:
	if part == null:
		return
	interaction_event.emit(String(part.part_id), String(kind), {
		"part_kind": String(part.part_kind),
		"position": _vector(part.global_position),
		"rotation": _vector(part.global_rotation),
		"reposition_count": int(part.reposition_count),
	})


func _on_configuration_changed(snapshot: Dictionary) -> void:
	_update_readiness()
	configuration_changed.emit(snapshot, MetricsScript.evaluate(snapshot))


func _update_readiness() -> void:
	var next_ready := configuration != null and bool(configuration.call("is_minimum_test_ready"))
	if bottle != null:
		bottle.snap_enabled = next_ready
	if launch_stand != null:
		var glow: GeometryInstance3D = launch_stand.get_node_or_null(^"Visual/ReadyGlow") as GeometryInstance3D
		if glow != null:
			glow.visible = next_ready
		var stand_zone: Node = launch_stand.get_node_or_null(^"RocketSnap")
		if stand_zone != null:
			stand_zone.hint_visible = next_ready
			stand_zone.call("show_idle_hint")
	if next_ready != _ready_for_test:
		_ready_for_test = next_ready
		readiness_changed.emit(_ready_for_test)


func _reset_loose_parts() -> void:
	for zone: Node in get_tree().get_nodes_in_group(&"vs1_snap_zones"):
		if is_ancestor_of(zone):
			zone.call("clear")
	for part: Node3D in fins + [nose]:
		if part.get_parent() != self:
			part.reparent(self, true)
		part.call("detach")
		part.set_physics_process(true)
		var loose_shadow: GeometryInstance3D = part.get_node_or_null(^"BlobShadow") as GeometryInstance3D
		if loose_shadow != null:
			loose_shadow.visible = true
		var rest: Transform3D = _rest_transforms.get(String(part.part_id), part.global_transform)
		part.global_transform = rest
		part.target_position = rest.origin
		part.target_rotation = rest.basis.get_euler()


func _apply_configuration_visual(snapshot: Dictionary) -> void:
	if snapshot.is_empty() or bottle == null:
		return
	var liquid_owner: Node = bottle
	liquid_owner.set_meta(&"water_level", float(snapshot.get("water_level", 0.0)))
	var water_controller: Node = water_container.get_node_or_null(^"WaterFillController") if water_container != null else null
	if water_controller != null:
		water_controller.call("set_receiver_level", bottle.get_node(^"PourReceiver"), float(snapshot.get("water_level", 0.0)))
	call_deferred("_restore_attached_parts", snapshot)


func _restore_attached_parts(snapshot: Dictionary) -> void:
	var raw_fins: Array = snapshot.get("fins", [])
	var used_zones: Dictionary = {}
	for fin_state: Dictionary in raw_fins:
		if not bool(fin_state.get("attached", false)):
			continue
		var part := _find_fin(String(fin_state.get("fin_id", "")))
		var zone := _closest_free_fin_zone(float(fin_state.get("angular_position", 0.0)), used_zones)
		if part == null or zone == null:
			continue
		used_zones[String(zone.zone_id)] = true
		var base: Transform3D = zone.global_transform
		var local_error := Vector3(0.0, (float(fin_state.get("height", 0.5)) - 0.5) * 0.20, 0.0)
		var error_basis := Basis.from_euler(Vector3(float(fin_state.get("tilt", 0.0)) * deg_to_rad(9.0), 0.0, float(fin_state.get("orientation", 0.0)) * deg_to_rad(9.0)))
		var target := Transform3D(base.basis * error_basis, base.origin + base.basis * local_error)
		zone.occupied_part = part
		zone.occupied_object = part
		part.call("snap_to", target, {"zone_id": zone.zone_id, "quality": float(fin_state.get("attachment_quality", 0.0))})
		zone.set_meta(&"fixation_quality", float(fin_state.get("attachment_quality", 0.0)))
		if bool(fin_state.get("fixed", false)):
			_ensure_restored_tape_band(zone, float(fin_state.get("attachment_quality", 0.0)))
		_attach_to_bottle(part)
	var cone_state: Dictionary = snapshot.get("cone", {})
	if bool(cone_state.get("present", false)):
		var nose_zone: Node = bottle.get_node_or_null(^"NoseSnap")
		if nose_zone != null:
			var angle := float(cone_state.get("angular_deviation", 0.0)) * deg_to_rad(7.0)
			var target := Transform3D(nose_zone.global_basis * Basis.from_euler(Vector3(angle, 0.0, -angle * 0.5)), nose_zone.global_position)
			nose_zone.occupied_part = nose
			nose_zone.occupied_object = nose
			nose.call("snap_to", target, {"zone_id": "nose", "quality": float(cone_state.get("attachment_quality", 0.0))})
			_attach_to_bottle(nose)


func _find_fin(fin_id: String) -> Node3D:
	for fin: Node3D in fins:
		if String(fin.part_id) == fin_id:
			return fin
	return null


func _closest_free_fin_zone(turn: float, used: Dictionary) -> Node:
	var best: Node = null
	var best_distance := INF
	for zone_name: String in ["FinSnapA", "FinSnapB", "FinSnapC"]:
		var zone: Node = bottle.get_node_or_null(NodePath(zone_name))
		if zone == null or used.has(String(zone.zone_id)):
			continue
		var candidate_turn := _zone_turn(String(zone.zone_id))
		var distance := absf(wrapf((turn - candidate_turn) * TAU, -PI, PI))
		if distance < best_distance:
			best_distance = distance
			best = zone
	return best


func _zone_turn(zone_id: String) -> float:
	match zone_id:
		"fin_a": return 0.0
		"fin_b": return 1.0 / 3.0
		"fin_c": return 2.0 / 3.0
	return 0.0


func _ensure_restored_tape_band(zone: Node3D, quality: float) -> void:
	if zone.get_node_or_null(^"TapeBand_Restored") != null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.90, 0.84, 0.56, 0.44 + clampf(quality, 0.0, 1.0) * 0.38)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.36
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, material)
	for index: int in range(29):
		var angle := TAU * float(index) / 28.0
		var radial := Vector3(cos(angle) * 0.43, 0.0, sin(angle) * 0.43)
		mesh.surface_set_normal(radial.normalized())
		mesh.surface_add_vertex(radial + Vector3(0.0, -0.05, 0.0))
		mesh.surface_add_vertex(radial + Vector3(0.0, 0.05, 0.0))
	mesh.surface_end()
	var band := MeshInstance3D.new()
	band.name = "TapeBand_Restored"
	band.mesh = mesh
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	zone.add_child(band)


func _vector(value: Vector3) -> Dictionary:
	return {"x": value.x, "y": value.y, "z": value.z}
