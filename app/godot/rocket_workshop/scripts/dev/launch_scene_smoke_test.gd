extends SceneTree

var scene: Node = null
var frames := 0


func _initialize() -> void:
	scene = load("res://scenes/main_3d.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	frames += 1
	if frames < 3:
		return false

	var assembly: Node = scene.assembly
	var parts: Array[Node] = scene.all_parts
	_snap_to(assembly, parts[1], "nose")
	_snap_to(assembly, parts[2], "fin_left")
	_snap_to(assembly, parts[3], "fin_right")
	_snap_to(assembly, parts[5], "energy_socket")
	if assembly.is_ready_for_launch():
		_fail("assembly should not be ready with only two fins.")
		return true

	_snap_to(assembly, parts[4], "fin_top")
	if not assembly.is_ready_for_launch():
		_fail("assembly should be ready after the third fin.")
		return true

	scene.launch_controller.request_launch()
	for _i: int in range(720):
		scene.launch_controller._physics_process(1.0 / 60.0)
		if not scene.telemetry.flight_summaries.is_empty():
			break

	if scene.telemetry.flight_summaries.is_empty():
		_fail("no flight summary recorded.")
		return true

	var summary: Dictionary = scene.telemetry.flight_summaries.back()
	if float(summary.get("max_height", 0.0)) <= 0.5:
		_fail("flight did not gain height.")
		return true

	print("Scene launch smoke test passed.")
	quit(0)
	return true


func _snap_to(assembly: Node, part: Node, zone_id: String) -> void:
	for zone: Node in assembly.snap_zones:
		if zone.zone_id == zone_id:
			part.global_position = zone.global_position
			assembly.snap_part(part, zone)
			return
	printerr("Zone not found: %s" % zone_id)
	quit(1)


func _fail(message: String) -> void:
	printerr("Scene launch smoke test failed: %s" % message)
	quit(1)
