extends Node3D
class_name VS1TrajectoryRenderer

## World-space trajectory review. It draws at most the two latest attempts and
## creates only lightweight review helpers (line, apex marker and impact marker).

signal trajectories_rendered(attempt_count: int)
signal review_visibility_changed(is_visible: bool)

const MAX_TRAJECTORIES: int = 2
const PREVIOUS_COLOR := Color(0.34, 0.62, 0.82, 0.40)
const CURRENT_COLOR := Color(0.96, 0.61, 0.31, 0.78)
const APEX_COLOR := Color(1.0, 0.91, 0.54, 0.90)
const IMPACT_COLOR := Color(0.94, 0.43, 0.34, 0.88)

var normalized_config: Dictionary = {}
var render_seed: int = 1
var rendered_attempts: Array[Dictionary] = []

var _visual_root: Node3D = null


func _ready() -> void:
	_ensure_visual_root()


func configure(config_snapshot: Dictionary = {}, seed_value: int = 1) -> void:
	normalized_config = {
		"opacity": clampf(float(config_snapshot.get("opacity", 0.72)), 0.0, 1.0),
		"marker_scale": clampf(float(config_snapshot.get("marker_scale", 0.48)), 0.0, 1.0),
		"brightness": clampf(float(config_snapshot.get("brightness", 0.65)), 0.0, 1.0),
	}
	render_seed = seed_value


func render_attempts(attempts: Array[Dictionary]) -> void:
	_ensure_visual_root()
	_clear_visual_children()
	rendered_attempts.clear()
	var start_index: int = maxi(0, attempts.size() - MAX_TRAJECTORIES)
	for source_index: int in range(start_index, attempts.size()):
		rendered_attempts.append(attempts[source_index].duplicate(true))

	for index: int in range(rendered_attempts.size()):
		var attempt: Dictionary = rendered_attempts[index]
		var is_current: bool = index == rendered_attempts.size() - 1
		var color: Color = CURRENT_COLOR if is_current else PREVIOUS_COLOR
		color.a *= _opacity_multiplier()
		var points: PackedVector3Array = _extract_points(attempt)
		if points.size() >= 2:
			_create_line(points, color, index)
		if not points.is_empty():
			var apex: Vector3 = _extract_position(attempt.get("apex_position", _highest_point(points)))
			var impact: Vector3 = _extract_position(attempt.get("impact_position", points[points.size() - 1]))
			_create_marker(apex, APEX_COLOR, "Apex_%d" % index, _marker_size())
			_create_marker(impact, IMPACT_COLOR, "Impact_%d" % index, _marker_size() * 0.86)

	_visual_root.visible = true
	trajectories_rendered.emit(rendered_attempts.size())
	review_visibility_changed.emit(true)


func render_from_recorder(recorder: RefCounted) -> void:
	if recorder == null or not recorder.has_method("get_recent_attempts"):
		render_attempts([])
		return
	var raw_attempts: Variant = recorder.call("get_recent_attempts")
	var typed_attempts: Array[Dictionary] = []
	if raw_attempts is Array:
		for value: Variant in raw_attempts:
			if value is Dictionary:
				typed_attempts.append(value)
	render_attempts(typed_attempts)


func show_review() -> void:
	_ensure_visual_root()
	_visual_root.visible = true
	review_visibility_changed.emit(true)


func hide_review() -> void:
	_ensure_visual_root()
	_visual_root.visible = false
	review_visibility_changed.emit(false)


func clear() -> void:
	_ensure_visual_root()
	_clear_visual_children()
	rendered_attempts.clear()
	trajectories_rendered.emit(0)


func get_all_points() -> PackedVector3Array:
	var points := PackedVector3Array()
	for attempt: Dictionary in rendered_attempts:
		for point: Vector3 in _extract_points(attempt):
			points.append(point)
	return points


func _ensure_visual_root() -> void:
	if is_instance_valid(_visual_root):
		return
	_visual_root = Node3D.new()
	_visual_root.name = "VS1TrajectoryVisuals"
	add_child(_visual_root)


func _clear_visual_children() -> void:
	if not is_instance_valid(_visual_root):
		return
	for child: Node in _visual_root.get_children():
		_visual_root.remove_child(child)
		child.queue_free()


func _create_line(points: PackedVector3Array, color: Color, index: int) -> void:
	var mesh := ImmediateMesh.new()
	var material := _make_material(color)
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for world_point: Vector3 in points:
		mesh.surface_add_vertex(_to_visual_local(world_point))
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.name = "Trajectory_%d" % index
	instance.mesh = mesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual_root.add_child(instance)


func _create_marker(world_position: Vector3, color: Color, marker_name: String, marker_size: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = marker_size
	sphere.height = marker_size * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	var marker := MeshInstance3D.new()
	marker.name = marker_name
	marker.mesh = sphere
	marker.material_override = _make_material(color)
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.position = _to_visual_local(world_position)
	_visual_root.add_child(marker)


func _make_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	var brightness: float = lerpf(0.84, 1.18, float(normalized_config.get("brightness", 0.65)))
	material.albedo_color = Color(
		clampf(color.r * brightness, 0.0, 1.0),
		clampf(color.g * brightness, 0.0, 1.0),
		clampf(color.b * brightness, 0.0, 1.0),
		color.a
	)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


func _extract_points(attempt: Dictionary) -> PackedVector3Array:
	var points := PackedVector3Array()
	for sample: Variant in attempt.get("samples", []):
		if sample is Dictionary:
			points.append(_extract_position(sample.get("position", Vector3.ZERO)))
		elif sample is Vector3:
			points.append(sample)
	return points


func _extract_position(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Dictionary:
		return Vector3(float(value.get("x", 0.0)), float(value.get("y", 0.0)), float(value.get("z", 0.0)))
	return Vector3.ZERO


func _highest_point(points: PackedVector3Array) -> Vector3:
	var highest: Vector3 = points[0]
	for point: Vector3 in points:
		if point.y > highest.y:
			highest = point
	return highest


func _to_visual_local(world_position: Vector3) -> Vector3:
	return _visual_root.global_transform.affine_inverse() * world_position


func _opacity_multiplier() -> float:
	return lerpf(0.45, 1.0, float(normalized_config.get("opacity", 0.72)))


func _marker_size() -> float:
	return lerpf(0.07, 0.16, float(normalized_config.get("marker_scale", 0.48)))
