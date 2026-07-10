extends Node3D
class_name Workbench


func _ready() -> void:
	_build()


func _build() -> void:
	var wood: StandardMaterial3D = _material(Color(0.45, 0.30, 0.18), 0.78)
	var dark_wood: StandardMaterial3D = _material(Color(0.30, 0.20, 0.13), 0.85)
	var mark: StandardMaterial3D = _material(Color(0.20, 0.15, 0.12), 0.90)

	var top_mesh: BoxMesh = BoxMesh.new()
	top_mesh.size = Vector3(7.2, 0.28, 4.5)
	_add_mesh("Top", top_mesh, Transform3D(Basis(), Vector3(0.0, -0.12, 0.0)), wood)

	for x_value: float in [-3.15, 3.15]:
		for z_value: float in [-1.85, 1.85]:
			var leg_mesh: BoxMesh = BoxMesh.new()
			leg_mesh.size = Vector3(0.28, 1.35, 0.28)
			_add_mesh("Leg", leg_mesh, Transform3D(Basis(), Vector3(x_value, -0.86, z_value)), dark_wood)

	for index: int in range(10):
		var scratch_mesh: BoxMesh = BoxMesh.new()
		scratch_mesh.size = Vector3(0.48 + float(index % 3) * 0.18, 0.012, 0.018)
		var x_pos: float = -2.8 + float(index) * 0.62
		var z_pos: float = -1.45 + float((index * 7) % 9) * 0.34
		var basis: Basis = Basis(Vector3.UP, deg_to_rad(float(index * 13 % 44) - 22.0))
		_add_mesh("Scratch", scratch_mesh, Transform3D(basis, Vector3(x_pos, 0.035, z_pos)), mark)


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
