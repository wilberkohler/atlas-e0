extends Node
class_name VS1WaterFillController

signal pour_started(receiver)
signal water_level_changed(receiver, normalized_level, visual_band)
signal pour_stopped(receiver)
signal source_level_changed(normalized_level)

@export var container_path: NodePath = ^".."
@export var spout_path: NodePath = ^"../PourSpout"
@export var authorial_visual_root_path: NodePath = ^"../Visual/AuthorialPitcher"
@export var receiver_group: StringName = &"vs1_water_receivers"
@export_range(0.1, 1.5, 0.01) var receiving_radius: float = 0.48
@export_range(0.01, 1.0, 0.01) var normalized_flow_rate: float = 0.22
@export_range(0.0, 85.0, 1.0) var tilt_start_degrees: float = 24.0
@export_range(1.0, 90.0, 1.0) var full_flow_degrees: float = 58.0
@export var require_held_container: bool = true
@export var build_authorial_pitcher: bool = true

var source_level: float = 1.0
var active_receiver: Node3D = null

var _container: Node3D = null
var _spout: Node3D = null
var _visual_root: Node3D = null
var _source_liquid: MeshInstance3D = null


func _ready() -> void:
	_container = get_node_or_null(container_path) as Node3D
	_spout = get_node_or_null(spout_path) as Node3D
	_visual_root = get_node_or_null(authorial_visual_root_path) as Node3D
	if build_authorial_pitcher and _visual_root != null and _visual_root.get_child_count() == 0:
		_build_pitcher_visual()
	_update_source_visual()
	set_process(true)


func _process(delta: float) -> void:
	if _container == null or _spout == null or source_level <= 0.0:
		_stop_pouring()
		return
	if require_held_container and (not _container.has_method("is_grabbed") or not bool(_container.call("is_grabbed"))):
		_stop_pouring()
		return

	var tilt_radians: float = acos(clampf(_container.global_basis.y.normalized().dot(Vector3.UP), -1.0, 1.0))
	var tilt_degrees: float = rad_to_deg(tilt_radians)
	if tilt_degrees < tilt_start_degrees:
		_stop_pouring()
		return

	var receiver: Node3D = _nearest_receiver()
	if receiver == null:
		_stop_pouring()
		return
	if active_receiver != receiver:
		_stop_pouring()
		active_receiver = receiver
		pour_started.emit(receiver)

	var flow_strength: float = clampf(inverse_lerp(tilt_start_degrees, full_flow_degrees, tilt_degrees), 0.12, 1.0)
	var transfer: float = minf(source_level, normalized_flow_rate * flow_strength * delta)
	var current_level: float = get_receiver_level(receiver)
	transfer = minf(transfer, 1.0 - current_level)
	if transfer <= 0.0:
		_stop_pouring()
		return
	source_level = clampf(source_level - transfer, 0.0, 1.0)
	set_receiver_level(receiver, current_level + transfer)
	_update_source_visual()
	source_level_changed.emit(source_level)


func set_source_level(normalized_level: float) -> void:
	source_level = clampf(normalized_level, 0.0, 1.0)
	_update_source_visual()
	source_level_changed.emit(source_level)


func get_receiver_level(receiver: Node) -> float:
	var owner: Node = _receiver_owner(receiver)
	return float(owner.get_meta(&"water_level", 0.0)) if owner != null else 0.0


func set_receiver_level(receiver: Node, normalized_level: float) -> void:
	var owner: Node = _receiver_owner(receiver)
	if owner == null:
		return
	var level: float = clampf(normalized_level, 0.0, 1.0)
	owner.set_meta(&"water_level", level)
	_update_receiver_visual(owner, level)
	water_level_changed.emit(owner, level, _visual_band(level))


func _nearest_receiver() -> Node3D:
	var nearest: Node3D = null
	var best_distance: float = receiving_radius
	for candidate: Node in get_tree().get_nodes_in_group(receiver_group):
		var receiver: Node3D = candidate as Node3D
		if receiver == null:
			continue
		var distance: float = _spout.global_position.distance_to(receiver.global_position)
		if distance < best_distance:
			best_distance = distance
			nearest = receiver
	return nearest


func _stop_pouring() -> void:
	if active_receiver != null:
		pour_stopped.emit(active_receiver)
	active_receiver = null


func _receiver_owner(receiver: Node) -> Node:
	if receiver == null:
		return null
	if receiver.has_node(^"LiquidVisual"):
		return receiver
	var parent: Node = receiver.get_parent()
	if parent != null and parent.has_node(^"LiquidVisual"):
		return parent
	return receiver


func _update_receiver_visual(owner: Node, level: float) -> void:
	var liquid: MeshInstance3D = owner.get_node_or_null(^"LiquidVisual") as MeshInstance3D
	if liquid == null:
		return
	var bottom_y: float = float(liquid.get_meta(&"bottom_y", -0.98))
	var maximum_height: float = float(liquid.get_meta(&"maximum_height", 2.05))
	liquid.visible = level > 0.006
	liquid.scale.y = maxf(level, 0.006)
	liquid.position.y = bottom_y + maximum_height * level * 0.5


func _update_source_visual() -> void:
	if _source_liquid == null:
		return
	var maximum_height: float = 0.70
	var bottom_y: float = -0.31
	_source_liquid.visible = source_level > 0.006
	_source_liquid.scale.y = maxf(source_level, 0.006)
	_source_liquid.position.y = bottom_y + maximum_height * source_level * 0.5


func _visual_band(level: float) -> StringName:
	if level < 0.34:
		return &"little"
	if level < 0.68:
		return &"intermediate"
	return &"much"


func _build_pitcher_visual() -> void:
	var ceramic := StandardMaterial3D.new()
	ceramic.albedo_color = Color(0.66, 0.88, 0.91)
	ceramic.roughness = 0.32
	ceramic.metallic = 0.0
	ceramic.cull_mode = BaseMaterial3D.CULL_DISABLED

	var body := MeshInstance3D.new()
	body.name = "FacetedPitcherBody"
	body.mesh = _build_lathed_body_mesh()
	body.material_override = ceramic
	_visual_root.add_child(body)

	var handle := MeshInstance3D.new()
	handle.name = "CurvedHandle"
	handle.mesh = _build_handle_mesh()
	handle.material_override = ceramic
	_visual_root.add_child(handle)

	var spout := MeshInstance3D.new()
	spout.name = "PouringSpout"
	spout.mesh = _build_spout_mesh()
	spout.material_override = ceramic
	_visual_root.add_child(spout)

	var liquid_material := StandardMaterial3D.new()
	liquid_material.albedo_color = Color(0.20, 0.64, 0.92, 0.62)
	liquid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	liquid_material.roughness = 0.12
	liquid_material.metallic = 0.04

	var liquid_mesh := CylinderMesh.new()
	liquid_mesh.top_radius = 0.37
	liquid_mesh.bottom_radius = 0.31
	liquid_mesh.height = 0.70
	liquid_mesh.radial_segments = 24
	_source_liquid = MeshInstance3D.new()
	_source_liquid.name = "SourceLiquid"
	_source_liquid.mesh = liquid_mesh
	_source_liquid.material_override = liquid_material
	_visual_root.add_child(_source_liquid)


func _build_lathed_body_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var profile: Array[Vector2] = [
		Vector2(0.30, -0.40),
		Vector2(0.38, -0.34),
		Vector2(0.43, 0.26),
		Vector2(0.49, 0.48),
		Vector2(0.50, 0.55),
	]
	var sides: int = 20
	for ring: int in range(profile.size() - 1):
		for side: int in range(sides):
			var angle_a: float = TAU * float(side) / float(sides)
			var angle_b: float = TAU * float(side + 1) / float(sides)
			var lower: Vector2 = profile[ring]
			var upper: Vector2 = profile[ring + 1]
			var a := Vector3(cos(angle_a) * lower.x, lower.y, sin(angle_a) * lower.x)
			var b := Vector3(cos(angle_b) * lower.x, lower.y, sin(angle_b) * lower.x)
			var c := Vector3(cos(angle_b) * upper.x, upper.y, sin(angle_b) * upper.x)
			var d := Vector3(cos(angle_a) * upper.x, upper.y, sin(angle_a) * upper.x)
			_add_quad(surface, a, b, c, d)
	for side: int in range(sides):
		var angle_a: float = TAU * float(side) / float(sides)
		var angle_b: float = TAU * float(side + 1) / float(sides)
		var edge_a := Vector3(cos(angle_a) * 0.30, -0.40, sin(angle_a) * 0.30)
		var edge_b := Vector3(cos(angle_b) * 0.30, -0.40, sin(angle_b) * 0.30)
		surface.add_vertex(Vector3(0.0, -0.40, 0.0))
		surface.add_vertex(edge_b)
		surface.add_vertex(edge_a)
	# A thick open rim makes the silhouette read as a vessel rather than a primitive.
	for side: int in range(sides):
		var angle_a: float = TAU * float(side) / float(sides)
		var angle_b: float = TAU * float(side + 1) / float(sides)
		var outer_a := Vector3(cos(angle_a) * 0.50, 0.55, sin(angle_a) * 0.50)
		var outer_b := Vector3(cos(angle_b) * 0.50, 0.55, sin(angle_b) * 0.50)
		var inner_b := Vector3(cos(angle_b) * 0.42, 0.55, sin(angle_b) * 0.42)
		var inner_a := Vector3(cos(angle_a) * 0.42, 0.55, sin(angle_a) * 0.42)
		_add_quad(surface, outer_a, outer_b, inner_b, inner_a)
	surface.generate_normals()
	return surface.commit()


func _build_handle_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path_segments: int = 15
	var tube_segments: int = 8
	for path_index: int in range(path_segments):
		var t_a: float = PI * float(path_index) / float(path_segments)
		var t_b: float = PI * float(path_index + 1) / float(path_segments)
		var center_a := Vector3(0.39 + sin(t_a) * 0.38, 0.44 - t_a / PI * 0.72, 0.0)
		var center_b := Vector3(0.39 + sin(t_b) * 0.38, 0.44 - t_b / PI * 0.72, 0.0)
		var tangent: Vector3 = (center_b - center_a).normalized()
		var plane_normal := Vector3(-tangent.y, tangent.x, 0.0).normalized()
		for tube_index: int in range(tube_segments):
			var angle_a: float = TAU * float(tube_index) / float(tube_segments)
			var angle_b: float = TAU * float(tube_index + 1) / float(tube_segments)
			var offset_a: Vector3 = (plane_normal * cos(angle_a) + Vector3.FORWARD * sin(angle_a)) * 0.045
			var offset_b: Vector3 = (plane_normal * cos(angle_b) + Vector3.FORWARD * sin(angle_b)) * 0.045
			_add_quad(surface, center_a + offset_a, center_a + offset_b, center_b + offset_b, center_b + offset_a)
	surface.generate_normals()
	return surface.commit()


func _build_spout_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-0.46, 0.43, -0.17)
	var b := Vector3(-0.46, 0.43, 0.17)
	var c := Vector3(-0.72, 0.53, 0.09)
	var d := Vector3(-0.72, 0.53, -0.09)
	var a2 := a + Vector3.UP * 0.08
	var b2 := b + Vector3.UP * 0.08
	var c2 := c + Vector3.UP * 0.08
	var d2 := d + Vector3.UP * 0.08
	_add_quad(surface, a, b, c, d)
	_add_quad(surface, a2, d2, c2, b2)
	_add_quad(surface, a, a2, b2, b)
	_add_quad(surface, d, c, c2, d2)
	_add_quad(surface, b, b2, c2, c)
	_add_quad(surface, a, d, d2, a2)
	surface.generate_normals()
	return surface.commit()


func _add_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
	surface.add_vertex(a)
	surface.add_vertex(c)
	surface.add_vertex(d)
