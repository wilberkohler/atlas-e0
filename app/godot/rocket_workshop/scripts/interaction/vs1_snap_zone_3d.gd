extends Area3D
class_name VS1SnapZone3D

signal candidate_changed(part)
signal object_snapped(part, zone, quality)
signal object_released(part, zone)

@export var zone_id: String = "zone"
@export var accepted_type: StringName = &"generic"
@export_range(0.05, 3.0, 0.01) var tolerance: float = 0.70
@export_range(0.05, 4.0, 0.01) var magnetic_radius: float = 1.05
@export_range(1.0, 180.0, 1.0) var angular_tolerance_degrees: float = 55.0
@export_range(0.0, 0.30, 0.005) var preserved_position_error: float = 0.075
@export_range(0.0, 25.0, 0.5) var preserved_angle_error_degrees: float = 9.0
@export var preserve_misalignment: bool = true
@export var use_planar_capture_distance: bool = false
@export var allow_repositioning: bool = true
@export var hint_visible: bool = true

var occupied_part: Node = null
var occupied_object: Node3D = null

var _preview_mesh: MeshInstance3D = null
var _preview_material: StandardMaterial3D = null
var _occupied_local_transform: Transform3D = Transform3D.IDENTITY


func _ready() -> void:
	add_to_group(&"vs1_snap_zones")
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	_build_preview()
	show_idle_hint()
	set_process(true)


func _process(_delta: float) -> void:
	if occupied_object == null or not is_instance_valid(occupied_object):
		return
	if not occupied_object.has_method("get_target_transform"):
		return
	var moving_target: Transform3D = global_transform * _occupied_local_transform
	occupied_object.set("target_position", moving_target.origin)
	occupied_object.set("target_rotation", moving_target.basis.orthonormalized().get_euler())


func can_accept(part: Node) -> bool:
	if part == null:
		return false
	var occupant: Node = occupied_object if occupied_object != null else occupied_part
	if occupant != null and occupant != part:
		return false
	var enabled: bool = bool(_read_property(part, &"snap_enabled", true))
	var kind: StringName = StringName(str(_read_property(
		part,
		&"part_kind",
		_read_property(part, &"part_type", &"generic")
	)))
	return enabled and (accepted_type == &"any" or accepted_type == kind)


func is_in_range(part: Node) -> bool:
	return can_accept(part) and _distance_to_target(_part_target_position(part)) <= tolerance


func is_in_magnetic_range(part: Node) -> bool:
	return can_accept(part) and _distance_to_target(_part_target_position(part)) <= magnetic_radius


func estimate_quality(part: Node) -> float:
	if not can_accept(part):
		return 0.0
	var source: Transform3D = _part_target_transform(part)
	var distance: float = _distance_to_target(source.origin)
	var distance_score: float = 1.0 - clampf(distance / maxf(tolerance, 0.001), 0.0, 1.0)
	var relative_basis: Basis = global_basis.orthonormalized().inverse() * source.basis.orthonormalized()
	var relative_euler: Vector3 = relative_basis.get_euler()
	var angular_delta: float = maxf(absf(relative_euler.x), maxf(absf(relative_euler.y), absf(relative_euler.z)))
	var angular_score: float = 1.0 - clampf(
		angular_delta / deg_to_rad(maxf(angular_tolerance_degrees, 0.1)),
		0.0,
		1.0
	)
	return clampf(distance_score * 0.58 + angular_score * 0.42, 0.0, 1.0)


func get_capture_score(part: Node) -> float:
	if not can_accept(part):
		return -1.0
	var distance: float = _distance_to_target(_part_target_position(part))
	if distance > magnetic_radius:
		return -1.0
	return (1.0 - distance / magnetic_radius) * 0.72 + estimate_quality(part) * 0.28


func get_snap_transform() -> Transform3D:
	# Legacy exact target. New objects use get_snap_transform_for(), which preserves error.
	return global_transform


func get_snap_transform_for(part: Node) -> Transform3D:
	if not preserve_misalignment or part == null:
		return global_transform
	var source: Transform3D = _part_target_transform(part)
	var local_offset: Vector3 = global_transform.affine_inverse() * source.origin
	local_offset.x = clampf(local_offset.x, -preserved_position_error, preserved_position_error)
	local_offset.y = clampf(local_offset.y, -preserved_position_error, preserved_position_error)
	local_offset.z = clampf(local_offset.z, -preserved_position_error, preserved_position_error)

	var relative_basis: Basis = global_basis.orthonormalized().inverse() * source.basis.orthonormalized()
	var relative_euler: Vector3 = relative_basis.get_euler()
	var angle_limit: float = deg_to_rad(preserved_angle_error_degrees)
	relative_euler.x = clampf(relative_euler.x, -angle_limit, angle_limit)
	relative_euler.y = clampf(relative_euler.y, -angle_limit, angle_limit)
	relative_euler.z = clampf(relative_euler.z, -angle_limit, angle_limit)
	return Transform3D(
		global_basis.orthonormalized() * Basis.from_euler(relative_euler),
		global_transform * local_offset
	)


func get_magnetic_target_position(part: Node, current_target: Vector3) -> Vector3:
	if not is_in_magnetic_range(part):
		return current_target
	var distance: float = _distance_to_target(current_target)
	var strength: float = pow(1.0 - clampf(distance / magnetic_radius, 0.0, 1.0), 2.0) * 0.42
	return current_target.lerp(global_position, strength)


func commit_snap(part: Node) -> bool:
	if not is_in_range(part):
		return false
	if not part.has_method("snap_to") and not part.has_method("snap_to_zone"):
		return false
	var quality: float = estimate_quality(part)
	var target: Transform3D = get_snap_transform_for(part)
	occupied_part = part
	occupied_object = part as Node3D
	_occupied_local_transform = global_transform.affine_inverse() * target
	set_occupied_visual(true)
	if part.has_method("snap_to"):
		part.call("snap_to", target, {
			"zone_id": zone_id,
			"quality": quality,
			"position_error": target.origin - global_position,
			"angular_error": (global_basis.inverse() * target.basis).get_euler(),
		})
	elif part.has_method("snap_to_zone"):
		part.call("snap_to_zone", self, quality)
	object_snapped.emit(part, self, quality)
	return true


func release_object(part: Node = null, detach_part: bool = true) -> bool:
	var occupant: Node = occupied_object if occupied_object != null else occupied_part
	if occupant == null or (part != null and occupant != part):
		return false
	occupied_part = null
	occupied_object = null
	_occupied_local_transform = Transform3D.IDENTITY
	if detach_part:
		if occupant.has_method("detach"):
			occupant.call("detach")
		elif occupant.has_method("detach_from_snap"):
			occupant.call("detach_from_snap")
	show_idle_hint()
	object_released.emit(occupant, self)
	return true


func set_preview(active: bool, compatible: bool) -> void:
	if _preview_mesh == null:
		return
	var occupant: Node = occupied_object if occupied_object != null else occupied_part
	if occupant != null:
		_preview_mesh.visible = false
		return
	_preview_mesh.visible = active
	if _preview_material == null:
		return
	_preview_material.albedo_color = Color(0.22, 0.88, 0.62, 0.30) if compatible else Color(0.95, 0.42, 0.22, 0.22)
	_preview_material.emission = Color(0.16, 0.92, 0.56) if compatible else Color(0.95, 0.32, 0.12)
	_preview_material.emission_energy_multiplier = 0.85 if compatible else 0.45


func show_idle_hint() -> void:
	if _preview_mesh == null:
		return
	var occupant: Node = occupied_object if occupied_object != null else occupied_part
	_preview_mesh.visible = hint_visible and occupant == null
	if _preview_material != null:
		_preview_material.albedo_color = Color(0.28, 0.85, 1.0, 0.14)
		_preview_material.emission = Color(0.22, 0.72, 1.0)
		_preview_material.emission_energy_multiplier = 0.28


func set_occupied_visual(active: bool) -> void:
	if _preview_mesh != null:
		_preview_mesh.visible = not active and hint_visible


func clear() -> void:
	occupied_part = null
	occupied_object = null
	_occupied_local_transform = Transform3D.IDENTITY
	show_idle_hint()


func _build_preview() -> void:
	_preview_mesh = get_node_or_null(^"SnapPreview") as MeshInstance3D
	if _preview_mesh == null:
		_preview_mesh = MeshInstance3D.new()
		_preview_mesh.name = "SnapPreview"
		var marker := CylinderMesh.new()
		marker.top_radius = 0.22 if accepted_type == &"fin" else 0.34
		marker.bottom_radius = marker.top_radius
		marker.height = 0.018
		marker.radial_segments = 24
		_preview_mesh.mesh = marker
		add_child(_preview_mesh)
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_material.emission_enabled = true
	_preview_material.no_depth_test = false
	_preview_mesh.material_override = _preview_material


func _part_target_position(part: Node) -> Vector3:
	if _has_property(part, &"target_position"):
		return part.get("target_position") as Vector3
	return (part as Node3D).global_position if part is Node3D else Vector3.INF


func _part_target_transform(part: Node) -> Transform3D:
	if part.has_method("get_target_transform"):
		return part.call("get_target_transform") as Transform3D
	return (part as Node3D).global_transform if part is Node3D else Transform3D.IDENTITY


func _has_property(object: Object, property_name: StringName) -> bool:
	for descriptor: Dictionary in object.get_property_list():
		if StringName(descriptor.get("name", "")) == property_name:
			return true
	return false


func _read_property(object: Object, property_name: StringName, fallback: Variant) -> Variant:
	if object != null and _has_property(object, property_name):
		return object.get(property_name)
	return fallback


func _distance_to_target(target: Vector3) -> float:
	if not use_planar_capture_distance:
		return target.distance_to(global_position)
	return Vector2(target.x, target.z).distance_to(Vector2(global_position.x, global_position.z))

