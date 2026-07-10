extends Node3D
class_name LaunchStand

var _indicator_material: StandardMaterial3D = null
var _lever_material: StandardMaterial3D = null


func _ready() -> void:
	_build()
	_build_hitbox()
	set_ready_visual(false)


func set_ready_visual(ready: bool) -> void:
	if _indicator_material != null:
		if ready:
			_indicator_material.albedo_color = Color(0.20, 0.92, 0.52)
			_indicator_material.emission = Color(0.12, 0.90, 0.38)
			_indicator_material.emission_enabled = true
			_indicator_material.emission_energy_multiplier = 1.2
		else:
			_indicator_material.albedo_color = Color(0.28, 0.34, 0.32)
			_indicator_material.emission_enabled = false
	if _lever_material != null:
		_lever_material.albedo_color = Color(0.12, 0.52, 0.60) if ready else Color(0.33, 0.36, 0.36)


func _build() -> void:
	var base_material: StandardMaterial3D = _material(Color(0.17, 0.18, 0.18), 0.68)
	var rail_material: StandardMaterial3D = _material(Color(0.55, 0.58, 0.56), 0.44)
	_indicator_material = _material(Color(0.28, 0.34, 0.32), 0.38)
	_lever_material = _material(Color(0.33, 0.36, 0.36), 0.58)

	var base_mesh: BoxMesh = BoxMesh.new()
	base_mesh.size = Vector3(1.35, 0.18, 1.08)
	_add_mesh("BasePlate", base_mesh, Transform3D(Basis(), Vector3.ZERO), base_material)

	var cradle_mesh: BoxMesh = BoxMesh.new()
	cradle_mesh.size = Vector3(1.72, 0.12, 0.12)
	_add_mesh("CradleA", cradle_mesh, Transform3D(Basis(Vector3.UP, deg_to_rad(12.0)), Vector3(-0.05, 0.20, -0.22)), rail_material)
	_add_mesh("CradleB", cradle_mesh, Transform3D(Basis(Vector3.UP, deg_to_rad(12.0)), Vector3(-0.05, 0.20, 0.22)), rail_material)

	var indicator_mesh: CylinderMesh = CylinderMesh.new()
	indicator_mesh.top_radius = 0.12
	indicator_mesh.bottom_radius = 0.12
	indicator_mesh.height = 0.05
	indicator_mesh.radial_segments = 24
	_add_mesh("ReadyLight", indicator_mesh, Transform3D(Basis(), Vector3(0.52, 0.15, -0.36)), _indicator_material)

	var lever_mesh: BoxMesh = BoxMesh.new()
	lever_mesh.size = Vector3(0.12, 0.58, 0.12)
	var lever_basis: Basis = Basis(Vector3.FORWARD, deg_to_rad(-24.0))
	_add_mesh("TestLever", lever_mesh, Transform3D(lever_basis, Vector3(0.58, 0.44, 0.35)), _lever_material)


func _add_mesh(node_name: String, mesh: Mesh, transform: Transform3D, material: Material) -> void:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.transform = transform
	instance.material_override = material
	add_child(instance)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _build_hitbox() -> void:
	var hitbox: Area3D = Area3D.new()
	hitbox.name = "LaunchHitbox"
	hitbox.input_ray_pickable = true
	hitbox.collision_layer = 2
	hitbox.collision_mask = 0
	hitbox.set_meta("launch_stand", true)
	add_child(hitbox)

	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(1.65, 0.92, 1.18)

	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.position = Vector3(0.0, 0.34, 0.0)
	collision.shape = shape
	hitbox.add_child(collision)
