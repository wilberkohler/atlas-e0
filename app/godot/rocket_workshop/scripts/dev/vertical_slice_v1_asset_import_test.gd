extends SceneTree

const ASSETS := {
	"pet_bottle": "res://assets_3d/export/v2/pet_bottle.glb",
	"paper_nose_cone": "res://assets_3d/export/v2/paper_nose_cone.glb",
	"cardboard_fin": "res://assets_3d/export/v2/cardboard_fin.glb",
	"launch_stand": "res://assets_3d/export/v2/launch_stand.glb",
	"workbench": "res://assets_3d/export/v2/workbench.glb",
	"tape_roll": "res://assets_3d/export/v2/tape_roll.glb",
}

const REQUIRED_MARKERS := {
	"pet_bottle": ["GRAB_PIVOT", "SNAP_NOSE", "SNAP_FIN_1", "SNAP_FIN_2", "SNAP_FIN_3"],
	"paper_nose_cone": ["CONE_BASE_PIVOT"],
	"cardboard_fin": ["FIN_GRAB_PIVOT", "SNAP_CONTACT"],
	"launch_stand": ["ROCKET_PLACEMENT_POINT"],
}


func _initialize() -> void:
	for asset_id: String in ASSETS:
		var path: String = ASSETS[asset_id]
		if not ResourceLoader.exists(path):
			_fail("ResourceLoader não encontrou %s em %s" % [asset_id, path])
			return

		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			_fail("%s não carregou como PackedScene" % asset_id)
			return

		var instance: Node = packed.instantiate()
		if instance == null:
			_fail("%s não pôde ser instanciado" % asset_id)
			return

		var mesh_count: int = _count_meshes(instance)
		if mesh_count <= 0:
			instance.free()
			_fail("%s não contém MeshInstance3D" % asset_id)
			return

		for marker: String in REQUIRED_MARKERS.get(asset_id, []):
			if instance.find_child(marker, true, false) == null:
				instance.free()
				_fail("%s não contém o marcador %s" % [asset_id, marker])
				return

		print("ASSET_OK %s meshes=%d" % [asset_id, mesh_count])
		instance.free()

	print("Vertical slice v1 asset import gate passed.")
	quit(0)


func _count_meshes(node: Node) -> int:
	var total: int = 1 if node is MeshInstance3D else 0
	for child: Node in node.get_children():
		total += _count_meshes(child)
	return total


func _fail(message: String) -> void:
	printerr("Vertical slice v1 asset import gate failed: %s" % message)
	quit(1)
