extends Node
class_name VS1TapeGestureController

signal gesture_started(junction)
signal gesture_progressed(junction, normalized_progress)
signal fixation_changed(junction, quality)
signal gesture_finished(junction, quality)

@export var tape_part_path: NodePath = ^".."
@export var junction_group: StringName = &"vs1_tape_junctions"
@export_range(0.10, 2.0, 0.01) var application_radius: float = 0.72
@export_range(0.10, 5.0, 0.05) var minimum_path_length: float = 1.05
@export_range(30.0, 720.0, 5.0) var minimum_arc_degrees: float = 235.0
@export_range(0.0, 1.0, 0.01) var partial_threshold: float = 0.28
@export_range(0.0, 1.0, 0.01) var adequate_threshold: float = 0.78
@export_range(0.05, 1.0, 0.01) var band_radius: float = 0.43
@export_range(0.02, 0.35, 0.01) var band_width: float = 0.10

var active_junction: Node3D = null
var gesture_progress: float = 0.0

var _tape_part: Node3D = null
var _last_point: Vector3 = Vector3.ZERO
var _last_angle: float = 0.0
var _path_length: float = 0.0
var _arc_length: float = 0.0
var _completed_junction: Node3D = null
var _band: MeshInstance3D = null
var _band_material: StandardMaterial3D = null


func _ready() -> void:
	_tape_part = get_node_or_null(tape_part_path) as Node3D
	_band_material = StandardMaterial3D.new()
	_band_material.albedo_color = Color(0.90, 0.84, 0.56, 0.80)
	_band_material.roughness = 0.38
	_band_material.metallic = 0.0
	_band_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	set_process(true)


func _process(_delta: float) -> void:
	if _tape_part == null or not _tape_part.has_method("is_grabbed"):
		return
	if not bool(_tape_part.call("is_grabbed")):
		if active_junction != null:
			end_gesture()
		_completed_junction = null
		return

	var nearest: Node3D = _find_nearest_junction()
	if nearest == null:
		if active_junction != null:
			end_gesture()
		_completed_junction = null
		return
	if nearest == _completed_junction:
		return
	if active_junction != nearest:
		if active_junction != null:
			end_gesture()
		begin_gesture(nearest)
	sample_gesture(_tape_part.global_position)


func begin_gesture(junction: Node3D) -> void:
	if junction == null:
		return
	active_junction = junction
	gesture_progress = 0.0
	_path_length = 0.0
	_arc_length = 0.0
	_last_point = _tape_part.global_position if _tape_part != null else junction.global_position
	_last_angle = _angle_around_junction(junction, _last_point)
	_band = _get_or_create_band(junction)
	_update_band(0.02)
	gesture_started.emit(junction)


func sample_gesture(world_position: Vector3) -> void:
	if active_junction == null:
		return
	var current_angle: float = _angle_around_junction(active_junction, world_position)
	_path_length += world_position.distance_to(_last_point)
	_arc_length += absf(wrapf(current_angle - _last_angle, -PI, PI))
	_last_point = world_position
	_last_angle = current_angle
	var distance_progress: float = _path_length / maxf(minimum_path_length, 0.001)
	var arc_progress: float = _arc_length / deg_to_rad(maxf(minimum_arc_degrees, 1.0))
	gesture_progress = clampf(minf(distance_progress, arc_progress), 0.0, 1.0)
	_update_band(maxf(gesture_progress, 0.02))
	gesture_progressed.emit(active_junction, gesture_progress)
	if gesture_progress >= adequate_threshold:
		var completed: Node3D = active_junction
		_set_fixation_quality(completed, clampf(0.72 + gesture_progress * 0.28, 0.0, 1.0))
		_completed_junction = completed
		active_junction = null


func end_gesture() -> float:
	if active_junction == null:
		return 0.0
	var junction: Node3D = active_junction
	var quality: float = 0.0
	if gesture_progress >= adequate_threshold:
		quality = clampf(0.72 + gesture_progress * 0.28, 0.0, 1.0)
	elif gesture_progress >= partial_threshold:
		quality = clampf(gesture_progress * 0.70, 0.0, 0.70)
	if quality > 0.0:
		_set_fixation_quality(junction, quality)
	elif _band != null:
		_band.queue_free()
	gesture_finished.emit(junction, quality)
	active_junction = null
	_band = null
	gesture_progress = 0.0
	return quality


func cancel_gesture() -> void:
	if _band != null:
		_band.queue_free()
	active_junction = null
	_band = null
	gesture_progress = 0.0


func get_fixation_quality(junction: Node) -> float:
	return float(junction.get_meta(&"fixation_quality", 0.0)) if junction != null else 0.0


func _find_nearest_junction() -> Node3D:
	var nearest: Node3D = null
	var best_distance: float = application_radius
	for candidate: Node in get_tree().get_nodes_in_group(junction_group):
		var junction: Node3D = candidate as Node3D
		if junction == null:
			continue
		if _has_property(junction, &"occupied_part"):
			var occupant: Variant = junction.get("occupied_object") if _has_property(junction, &"occupied_object") else null
			if occupant == null:
				occupant = junction.get("occupied_part")
			if occupant == null:
				continue
		var distance: float = _tape_part.global_position.distance_to(junction.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = junction
	return nearest


func _angle_around_junction(junction: Node3D, world_position: Vector3) -> float:
	var local: Vector3 = junction.to_local(world_position)
	return atan2(local.z, local.x)


func _set_fixation_quality(junction: Node3D, quality: float) -> void:
	var previous: float = float(junction.get_meta(&"fixation_quality", 0.0))
	var resolved: float = maxf(previous, quality)
	junction.set_meta(&"fixation_quality", resolved)
	junction.set_meta(&"fixed", resolved >= adequate_threshold)
	var occupant: Object = junction.get("occupied_object") as Object if _has_property(junction, &"occupied_object") else null
	if occupant == null and _has_property(junction, &"occupied_part"):
		occupant = junction.get("occupied_part") as Object
	if occupant != null:
		occupant.set_meta(&"fixation_quality", resolved)
		occupant.set_meta(&"fixed", resolved >= adequate_threshold)
		if _has_property(occupant, &"snap_metadata"):
			var metadata: Dictionary = occupant.get("snap_metadata") as Dictionary
			metadata["fixation_quality"] = resolved
			metadata["fixed"] = resolved >= adequate_threshold
			occupant.set("snap_metadata", metadata)
	_update_band(clampf(resolved, 0.03, 1.0))
	fixation_changed.emit(junction, resolved)
	gesture_finished.emit(junction, resolved)


func _get_or_create_band(junction: Node3D) -> MeshInstance3D:
	var band_name: StringName = StringName("TapeBand_%s" % str(junction.get_instance_id()))
	var existing: MeshInstance3D = junction.get_node_or_null(NodePath(str(band_name))) as MeshInstance3D
	if existing != null:
		return existing
	var created := MeshInstance3D.new()
	created.name = band_name
	created.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	junction.add_child(created)
	return created


func _update_band(progress: float) -> void:
	if _band == null:
		return
	var arc: float = TAU * clampf(progress, 0.02, 1.0)
	var segment_count: int = maxi(3, int(ceil(28.0 * progress)))
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _band_material)
	for index: int in range(segment_count + 1):
		var angle: float = -PI * 0.5 + arc * float(index) / float(segment_count)
		var normal := Vector3(cos(angle), 0.0, sin(angle))
		mesh.surface_set_normal(normal)
		mesh.surface_add_vertex(Vector3(normal.x * band_radius, -band_width * 0.5, normal.z * band_radius))
		mesh.surface_set_normal(normal)
		mesh.surface_add_vertex(Vector3(normal.x * band_radius, band_width * 0.5, normal.z * band_radius))
	mesh.surface_end()
	_band.mesh = mesh


func _has_property(object: Object, property_name: StringName) -> bool:
	if object == null:
		return false
	for descriptor: Dictionary in object.get_property_list():
		if StringName(descriptor.get("name", "")) == property_name:
			return true
	return false
