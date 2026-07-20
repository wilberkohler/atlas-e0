extends Node3D
class_name DraggablePart3D

signal selected(part)
signal released(part)
signal rotated(part)

@export var part_id: String = "part"
@export var part_type: StringName = &"generic"
@export var display_name: String = "Peça"
@export_multiline var description: String = "Uma peça da bancada."
@export var shape_style: StringName = &"box"
@export var can_drag: bool = true
@export var can_rotate: bool = true
@export var snap_enabled: bool = true
@export var rest_height: float = 0.35
@export var selected_lift: float = 0.20

var initial_transform: Transform3D
var original_parent: Node = null
var state: StringName = &"idle"
var touch_count: int = 0
var drag_count: int = 0
var rotation_count: int = 0
var drag_started_at: float = 0.0
var total_drag_duration: float = 0.0
var is_snapped: bool = false
var snap_zone: Node = null
var snap_quality: float = 0.0
var energy_level: float = 0.45

var _materials: Array[StandardMaterial3D] = []
var _hitbox: Area3D = null
var _visual_root: Node3D = null


func _ready() -> void:
	initial_transform = global_transform
	original_parent = get_parent()
	_ensure_visual()
	_apply_highlight(0.0)


func set_hovered(active: bool) -> void:
	if state == &"dragging" or state == &"selected":
		return
	if active:
		state = &"hovered"
		_apply_highlight(0.45)
	else:
		state = &"snapped" if is_snapped else &"idle"
		_apply_highlight(0.0 if not is_snapped else 0.18)


func begin_drag() -> void:
	if not can_drag:
		return
	touch_count += 1
	drag_count += 1
	drag_started_at = Time.get_unix_time_from_system()
	state = &"dragging"
	_apply_highlight(0.75)
	selected.emit(self)


func update_drag_position(target: Vector3) -> void:
	if state != &"dragging":
		return
	global_position = Vector3(target.x, rest_height + selected_lift, target.z)


func end_drag(table_target: Vector3) -> float:
	var duration: float = 0.0
	if drag_started_at > 0.0:
		duration = Time.get_unix_time_from_system() - drag_started_at
	total_drag_duration += duration
	drag_started_at = 0.0
	state = &"idle"
	global_position = Vector3(table_target.x, rest_height, table_target.z)
	_apply_highlight(0.0)
	released.emit(self)
	return duration


func rotate_by(radians: float) -> void:
	if not can_rotate:
		return
	rotate_y(radians)
	rotation_count += 1
	if part_type == &"energy":
		energy_level = clampf(energy_level + absf(radians) * 0.18, 0.10, 1.0)
	_apply_highlight(0.65)
	rotated.emit(self)


func snap_to_zone(zone: Node, quality: float) -> void:
	is_snapped = true
	snap_zone = zone
	snap_quality = quality
	state = &"snapped"
	global_transform = zone.get_snap_transform()
	var wobble: float = (1.0 - quality) * 0.28
	if wobble > 0.02:
		rotate_object_local(Vector3.FORWARD, wobble)
	_apply_highlight(0.22)


func detach_from_snap() -> void:
	is_snapped = false
	snap_zone = null
	snap_quality = 0.0
	state = &"idle"
	_apply_highlight(0.0)


func reset_to_initial() -> void:
	if original_parent != null and get_parent() != original_parent:
		reparent(original_parent, true)
	global_transform = initial_transform
	is_snapped = false
	snap_zone = null
	snap_quality = 0.0
	state = &"idle"
	touch_count = 0
	drag_count = 0
	rotation_count = 0
	total_drag_duration = 0.0
	energy_level = 0.45
	_apply_highlight(0.0)


func get_hitbox() -> Area3D:
	return _hitbox


func get_hover_title() -> String:
	return display_name


func get_hover_description() -> String:
	return description


func _ensure_visual() -> void:
	if _visual_root != null:
		return
	_visual_root = Node3D.new()
	_visual_root.name = "Visual"
	add_child(_visual_root)

	if _build_imported_visual():
		_build_hitbox()
		return

	if shape_style == &"bottle":
		_build_bottle()
	elif shape_style == &"cone":
		_build_cone()
	elif shape_style == &"fin":
		_build_fin()
	elif shape_style == &"elastic":
		_build_elastic()
	else:
		_build_box()

	_build_hitbox()


func _build_imported_visual() -> bool:
	var asset_path: String = _asset_visual_path()
	if asset_path.is_empty() or not ResourceLoader.exists(asset_path):
		return false

	var packed: PackedScene = load(asset_path) as PackedScene
	if packed == null:
		return false

	var imported: Node3D = packed.instantiate() as Node3D
	if imported == null:
		return false

	imported.name = "ImportedAssetVisual"
	imported.transform = _asset_visual_transform()
	_visual_root.add_child(imported)
	_register_imported_materials(imported)
	return true


func _asset_visual_path() -> String:
	if shape_style == &"bottle":
		return "res://assets_3d/export/v3/pet_bottle_main.glb"
	if shape_style == &"cone":
		return "res://assets_3d/export/v3/nose_cone_a.glb"
	if shape_style == &"fin":
		return "res://assets_3d/export/v3/cardboard_fin_straight.glb"
	if shape_style == &"elastic":
		return "res://assets_3d/export/v3/elastic_set.glb"
	return ""


func _asset_visual_transform() -> Transform3D:
	var transform: Transform3D = Transform3D.IDENTITY
	if shape_style == &"elastic":
		transform.origin = Vector3(-0.18, 0.0, 0.0)
	return transform


func _register_imported_materials(node: Node) -> void:
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
			var source_material: Material = mesh_instance.get_surface_override_material(surface_index)
			if source_material == null:
				source_material = mesh_instance.mesh.surface_get_material(surface_index)
			var standard_material: StandardMaterial3D = source_material as StandardMaterial3D
			if standard_material != null:
				var duplicated: StandardMaterial3D = standard_material.duplicate() as StandardMaterial3D
				mesh_instance.set_surface_override_material(surface_index, duplicated)
				_materials.append(duplicated)

	for child: Node in node.get_children():
		_register_imported_materials(child)


func _build_bottle() -> void:
	var pet_material: StandardMaterial3D = _material(Color(0.62, 0.90, 1.0, 0.32), 0.25, 0.32)
	var cap_material: StandardMaterial3D = _material(Color(0.14, 0.46, 0.78), 0.45, 1.0)
	var body_mesh: CylinderMesh = CylinderMesh.new()
	body_mesh.top_radius = 0.34
	body_mesh.bottom_radius = 0.38
	body_mesh.height = 2.85
	body_mesh.radial_segments = 24
	var body_transform: Transform3D = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(90.0)), Vector3.ZERO)
	_add_mesh("PETBody", body_mesh, body_transform, pet_material)

	var neck_mesh: CylinderMesh = CylinderMesh.new()
	neck_mesh.top_radius = 0.20
	neck_mesh.bottom_radius = 0.24
	neck_mesh.height = 0.55
	neck_mesh.radial_segments = 18
	var neck_transform: Transform3D = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(90.0)), Vector3(1.63, 0.0, 0.0))
	_add_mesh("PETNeck", neck_mesh, neck_transform, pet_material)

	var cap_mesh: CylinderMesh = CylinderMesh.new()
	cap_mesh.top_radius = 0.22
	cap_mesh.bottom_radius = 0.22
	cap_mesh.height = 0.16
	cap_mesh.radial_segments = 18
	var cap_transform: Transform3D = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(90.0)), Vector3(1.98, 0.0, 0.0))
	_add_mesh("PETCap", cap_mesh, cap_transform, cap_material)


func _build_cone() -> void:
	var cone_material: StandardMaterial3D = _material(Color(0.96, 0.90, 0.76), 0.72, 1.0)
	var cone_mesh: CylinderMesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.42
	cone_mesh.height = 0.85
	cone_mesh.radial_segments = 24
	var cone_transform: Transform3D = Transform3D(Basis(Vector3.FORWARD, deg_to_rad(-90.0)), Vector3.ZERO)
	_add_mesh("PaperCone", cone_mesh, cone_transform, cone_material)


func _build_fin() -> void:
	var cardboard_material: StandardMaterial3D = _material(Color(0.67, 0.45, 0.25), 0.86, 1.0)
	var fin_mesh: BoxMesh = BoxMesh.new()
	fin_mesh.size = Vector3(0.10, 0.56, 0.72)
	var fin_transform: Transform3D = Transform3D(Basis(), Vector3(0.10, 0.00, 0.18))
	_add_mesh("CardboardFin", fin_mesh, fin_transform, cardboard_material)


func _build_elastic() -> void:
	var rubber_material: StandardMaterial3D = _material(Color(0.24, 0.12, 0.10), 0.92, 1.0)
	var band_a: BoxMesh = BoxMesh.new()
	band_a.size = Vector3(0.92, 0.10, 0.12)
	_add_mesh("ElasticBandA", band_a, Transform3D(Basis(), Vector3(0.0, 0.0, -0.20)), rubber_material)
	var band_b: BoxMesh = BoxMesh.new()
	band_b.size = Vector3(0.92, 0.10, 0.12)
	_add_mesh("ElasticBandB", band_b, Transform3D(Basis(), Vector3(0.0, 0.0, 0.20)), rubber_material)
	var bridge: BoxMesh = BoxMesh.new()
	bridge.size = Vector3(0.12, 0.10, 0.50)
	_add_mesh("ElasticBridgeLeft", bridge, Transform3D(Basis(), Vector3(-0.46, 0.0, 0.0)), rubber_material)
	_add_mesh("ElasticBridgeRight", bridge, Transform3D(Basis(), Vector3(0.46, 0.0, 0.0)), rubber_material)


func _build_box() -> void:
	var material: StandardMaterial3D = _material(Color(0.80, 0.80, 0.76), 0.75, 1.0)
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.7, 0.3, 0.7)
	_add_mesh("PlaceholderBox", mesh, Transform3D.IDENTITY, material)


func _build_hitbox() -> void:
	_hitbox = Area3D.new()
	_hitbox.name = "Hitbox"
	_hitbox.input_ray_pickable = true
	_hitbox.collision_layer = 1
	_hitbox.collision_mask = 0
	_hitbox.set_meta("part", self)
	add_child(_hitbox)

	var shape: BoxShape3D = BoxShape3D.new()
	if shape_style == &"bottle":
		shape.size = Vector3(3.5, 0.95, 0.95)
	elif shape_style == &"cone":
		shape.size = Vector3(0.92, 0.74, 0.74)
	elif shape_style == &"fin":
		shape.size = Vector3(0.42, 0.72, 0.90)
	elif shape_style == &"elastic":
		shape.size = Vector3(1.12, 0.34, 0.76)
	else:
		shape.size = Vector3(0.8, 0.5, 0.8)

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = shape
	_hitbox.add_child(collision)


func _add_mesh(mesh_name: String, mesh: Mesh, transform: Transform3D, material: StandardMaterial3D) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.transform = transform
	instance.material_override = material
	_materials.append(material)
	_visual_root.add_child(instance)


func _material(color: Color, roughness: float, alpha: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if alpha < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = alpha
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	return material


func _apply_highlight(amount: float) -> void:
	for material: StandardMaterial3D in _materials:
		material.emission_enabled = amount > 0.0
		material.emission = Color(0.35, 0.84, 1.0) * amount
		material.emission_energy_multiplier = 0.6 + amount
