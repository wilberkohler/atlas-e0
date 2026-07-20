extends SceneTree

const ASSET_PATHS := [
	"res://assets_3d/export/v3/pet_bottle_main.glb",
	"res://assets_3d/export/v3/nose_cone_a.glb",
	"res://assets_3d/export/v3/cardboard_fin_straight.glb",
	"res://assets_3d/export/v3/elastic_set.glb",
	"res://assets_3d/export/v3/launch_stand.glb",
	"res://assets_3d/export/v3/workbench.glb",
]


func _initialize() -> void:
	for path: String in ASSET_PATHS:
		if not ResourceLoader.exists(path):
			_fail("asset path not found by ResourceLoader: %s" % path)
			return

		var packed: PackedScene = load(path) as PackedScene
		if packed == null:
			_fail("asset did not load as PackedScene: %s" % path)
			return

		var instance: Node = packed.instantiate()
		if instance == null:
			_fail("asset did not instantiate: %s" % path)
			return

		var mesh_count: int = _count_meshes(instance)
		instance.free()
		if mesh_count <= 0:
			_fail("asset has no MeshInstance3D nodes: %s" % path)
			return

	print("Asset import smoke test passed.")
	quit(0)


func _count_meshes(node: Node) -> int:
	var count: int = 1 if node is MeshInstance3D else 0
	for child: Node in node.get_children():
		count += _count_meshes(child)
	return count


func _fail(message: String) -> void:
	printerr("Asset import smoke test failed: %s" % message)
	quit(1)
