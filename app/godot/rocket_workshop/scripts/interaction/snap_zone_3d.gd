extends Area3D
class_name SnapZone3D

@export var zone_id: String = "zone"
@export var accepted_type: StringName = &"generic"
@export var tolerance: float = 0.70
@export var angular_tolerance_degrees: float = 55.0
@export var hint_visible: bool = true

var occupied_part: Node = null
var _preview_mesh: MeshInstance3D = null
var _preview_material: StandardMaterial3D = null


func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 0
	collision_mask = 0
	_build_preview()
	show_idle_hint()


func can_accept(part: Node) -> bool:
	if part == null:
		return false
	if occupied_part != null and occupied_part != part:
		return false
	return part.snap_enabled and part.part_type == accepted_type


func is_in_range(part: Node) -> bool:
	return can_accept(part) and part.global_position.distance_to(global_position) <= tolerance


func estimate_quality(part: Node) -> float:
	if part == null:
		return 0.0
	var distance: float = part.global_position.distance_to(global_position)
	var distance_score: float = 1.0 - clampf(distance / tolerance, 0.0, 1.0)
	var angular_tolerance: float = deg_to_rad(angular_tolerance_degrees)
	var angular_delta: float = absf(wrapf(part.global_rotation.y - global_rotation.y, -PI, PI))
	var angular_score: float = 1.0 - clampf(angular_delta / angular_tolerance, 0.0, 1.0)
	return clampf((distance_score * 0.58) + (angular_score * 0.42), 0.0, 1.0)


func get_snap_transform() -> Transform3D:
	return global_transform


func set_preview(active: bool, compatible: bool) -> void:
	if _preview_mesh == null:
		return
	if occupied_part != null:
		_preview_mesh.visible = false
		return
	_preview_mesh.visible = active
	if _preview_material == null:
		return
	if compatible:
		_preview_material.albedo_color = Color(0.15, 0.85, 0.52, 0.55)
		_preview_material.emission = Color(0.10, 0.85, 0.48)
		_preview_material.emission_energy_multiplier = 1.35
	else:
		_preview_material.albedo_color = Color(0.95, 0.46, 0.22, 0.32)
		_preview_material.emission = Color(0.95, 0.38, 0.16)
		_preview_material.emission_energy_multiplier = 0.8


func show_idle_hint() -> void:
	if _preview_mesh == null:
		return
	_preview_mesh.visible = hint_visible and occupied_part == null
	if _preview_material == null:
		return
	if accepted_type == &"nose":
		_preview_material.albedo_color = Color(0.95, 0.92, 0.68, 0.28)
		_preview_material.emission = Color(0.85, 0.78, 0.34)
	elif accepted_type == &"fin":
		_preview_material.albedo_color = Color(0.35, 0.74, 1.0, 0.24)
		_preview_material.emission = Color(0.25, 0.58, 0.95)
	else:
		_preview_material.albedo_color = Color(0.30, 1.0, 0.72, 0.24)
		_preview_material.emission = Color(0.20, 0.88, 0.58)
	_preview_material.emission_energy_multiplier = 0.35


func set_occupied_visual(active: bool) -> void:
	if _preview_mesh == null:
		return
	_preview_mesh.visible = false if active else hint_visible


func clear() -> void:
	occupied_part = null
	show_idle_hint()


func _build_preview() -> void:
	var mesh: Mesh = _make_preview_mesh()
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.albedo_color = Color(0.15, 0.85, 0.52, 0.35)
	_preview_material.emission_enabled = true
	_preview_material.emission_energy_multiplier = 0.7

	_preview_mesh = MeshInstance3D.new()
	_preview_mesh.name = "SnapPreview"
	_preview_mesh.mesh = mesh
	_preview_mesh.material_override = _preview_material
	add_child(_preview_mesh)


func _make_preview_mesh() -> Mesh:
	if accepted_type == &"fin":
		var fin_marker: BoxMesh = BoxMesh.new()
		fin_marker.size = Vector3(0.18, 0.06, 0.82)
		return fin_marker
	if accepted_type == &"energy":
		var energy_marker: BoxMesh = BoxMesh.new()
		energy_marker.size = Vector3(1.05, 0.06, 0.72)
		return energy_marker
	var nose_marker: CylinderMesh = CylinderMesh.new()
	nose_marker.top_radius = 0.46
	nose_marker.bottom_radius = 0.46
	nose_marker.height = 0.035
	nose_marker.radial_segments = 32
	return nose_marker
