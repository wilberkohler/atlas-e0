extends Node3D

const WORKBENCH_SCENE := "res://scenes/environment/workbench.tscn"
const BOTTLE_SCENE := "res://scenes/parts/pet_bottle.tscn"
const CONE_SCENE := "res://scenes/parts/nose_cone.tscn"
const FIN_SCENE := "res://scenes/parts/fin.tscn"
const ELASTIC_SCENE := "res://scenes/parts/elastic_unit.tscn"
const LAUNCH_STAND_SCENE := "res://scenes/props/launch_stand.tscn"
const RocketAssemblyScript := preload("res://scripts/assembly/rocket_assembly.gd")
const InteractionControllerScript := preload("res://scripts/interaction/interaction_controller.gd")
const SnapZoneScript := preload("res://scripts/interaction/snap_zone_3d.gd")
const TelemetryServiceScript := preload("res://scripts/telemetry/telemetry_service.gd")
const MinimalHUDScript := preload("res://scripts/ui/minimal_hud.gd")
const DebugOverlayScript := preload("res://scripts/ui/debug_overlay.gd")
const LaunchControllerScript := preload("res://scripts/launch/launch_controller.gd")
const LaunchCameraRigScript := preload("res://scripts/flight/launch_camera_rig.gd")

var camera: Camera3D = null
var telemetry: Node = null
var hud: Node = null
var debug_overlay: Node = null
var assembly: Node = null
var interaction: Node = null
var launch_controller: Node = null
var launch_camera_rig: Node = null
var launch_stand: Node = null
var loose_parts_root: Node3D = null
var all_parts: Array[Node] = []
var _last_debug_update: float = 0.0
var _idle_hint_visible: bool = false


func _ready() -> void:
	_setup_world()
	_create_workbench()
	_create_roots()
	_create_assembly()
	_create_loose_parts()
	_create_launch_stand()
	_create_snap_zones()
	_create_services_and_ui()
	_wire_runtime()
	telemetry.record("scene", "main_3d", {"detail": "World-first rocket workshop loaded"})
	hud.set_context("Arraste peças pela bancada. Q/E ou roda giram a peça durante o arraste.")


func _process(delta: float) -> void:
	_update_idle_hint()
	_last_debug_update += delta
	if debug_overlay != null and debug_overlay.visible and _last_debug_update > 0.35:
		_last_debug_update = 0.0
		debug_overlay.set_snapshot(telemetry.snapshot(assembly.get_summary()))


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_F2:
		debug_overlay.visible = not debug_overlay.visible
		if debug_overlay.visible:
			debug_overlay.set_snapshot(telemetry.snapshot(assembly.get_summary()))
		get_viewport().set_input_as_handled()


func _setup_world() -> void:
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	environment_node.name = "WorldEnvironment"
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.09, 0.13, 0.15)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.78, 0.74)
	environment.ambient_light_energy = 0.92
	environment_node.environment = environment
	add_child(environment_node)

	var key_light: DirectionalLight3D = DirectionalLight3D.new()
	key_light.name = "DirectionalLight3D"
	key_light.light_energy = 2.2
	key_light.rotation_degrees = Vector3(-58.0, -38.0, 0.0)
	add_child(key_light)

	var fill_light: OmniLight3D = OmniLight3D.new()
	fill_light.name = "SoftFill"
	fill_light.light_energy = 0.75
	fill_light.omni_range = 8.0
	fill_light.position = Vector3(-2.8, 3.0, 2.2)
	add_child(fill_light)

	var camera_rig: Node3D = Node3D.new()
	camera_rig.name = "CameraRig"
	add_child(camera_rig)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.4
	camera.position = Vector3(4.8, 5.2, 5.4)
	camera.current = true
	camera_rig.add_child(camera)
	camera.look_at(Vector3(0.0, 0.18, 0.0), Vector3.UP)


func _create_workbench() -> void:
	var packed: PackedScene = load(WORKBENCH_SCENE) as PackedScene
	var workbench: Node3D = packed.instantiate() as Node3D
	workbench.name = "Workbench"
	add_child(workbench)


func _create_roots() -> void:
	loose_parts_root = Node3D.new()
	loose_parts_root.name = "LooseParts"
	add_child(loose_parts_root)

	assembly = RocketAssemblyScript.new()
	assembly.name = "AssemblyArea"
	assembly.position = Vector3(0.15, 0.52, 0.10)
	add_child(assembly)


func _create_assembly() -> void:
	var bottle: Node = _instantiate_part(BOTTLE_SCENE, "pet_bottle", Vector3.ZERO, Vector3.ZERO)
	assembly.add_child(bottle)
	all_parts.append(bottle)


func _create_loose_parts() -> void:
	var cone: Node = _instantiate_part(CONE_SCENE, "nose_cone", Vector3(-2.65, 0.36, -1.18), Vector3(0.0, 28.0, 0.0))
	loose_parts_root.add_child(cone)
	all_parts.append(cone)

	for index: int in range(3):
		var x_pos: float = -2.85 + float(index) * 0.48
		var z_pos: float = -0.22 + float(index) * 0.46
		var fin: Node = _instantiate_part(FIN_SCENE, "fin_%d" % [index + 1], Vector3(x_pos, 0.32, z_pos), Vector3(0.0, -18.0 + float(index) * 17.0, 0.0))
		fin.display_name = "Aleta %d" % [index + 1]
		loose_parts_root.add_child(fin)
		all_parts.append(fin)

	var elastic: Node = _instantiate_part(ELASTIC_SCENE, "elastic_unit", Vector3(2.55, 0.30, -1.25), Vector3(0.0, -24.0, 0.0))
	loose_parts_root.add_child(elastic)
	all_parts.append(elastic)


func _create_launch_stand() -> void:
	var packed: PackedScene = load(LAUNCH_STAND_SCENE) as PackedScene
	launch_stand = packed.instantiate() as Node
	launch_stand.name = "LaunchStand"
	launch_stand.position = Vector3(2.05, 0.12, 1.05)
	add_child(launch_stand)


func _create_snap_zones() -> void:
	_add_snap_zone("nose", &"nose", Vector3(1.92, 0.0, 0.0), Vector3(0.0, 0.0, 0.0), 1.65)
	_add_snap_zone("fin_left", &"fin", Vector3(-1.04, -0.05, -0.43), Vector3(0.0, 90.0, 0.0), 1.45)
	_add_snap_zone("fin_right", &"fin", Vector3(-1.04, -0.05, 0.43), Vector3(0.0, -90.0, 0.0), 1.45)
	_add_snap_zone("fin_top", &"fin", Vector3(-1.14, 0.40, 0.0), Vector3(0.0, 0.0, 18.0), 1.45)
	_add_snap_zone("energy_socket", &"energy", Vector3(1.75, -0.24, 0.95), Vector3(0.0, 15.0, 0.0), 1.85)


func _create_services_and_ui() -> void:
	telemetry = TelemetryServiceScript.new()
	telemetry.name = "TelemetryService"
	add_child(telemetry)

	hud = MinimalHUDScript.new()
	hud.name = "MinimalHUD"
	add_child(hud)

	debug_overlay = DebugOverlayScript.new()
	debug_overlay.name = "DebugOverlay"
	add_child(debug_overlay)

	launch_controller = LaunchControllerScript.new()
	launch_controller.name = "LaunchController"
	add_child(launch_controller)

	launch_camera_rig = LaunchCameraRigScript.new()
	launch_camera_rig.name = "LaunchCameraRig"
	add_child(launch_camera_rig)

	interaction = InteractionControllerScript.new()
	interaction.name = "InteractionController"
	add_child(interaction)


func _wire_runtime() -> void:
	assembly.configure(telemetry, loose_parts_root)
	launch_camera_rig.configure(camera)
	launch_controller.configure(assembly, telemetry, launch_stand, launch_camera_rig)
	interaction.configure(camera, assembly, telemetry, launch_controller)

	assembly.readiness_changed.connect(_on_readiness_changed)
	assembly.assembly_changed.connect(_on_assembly_changed)
	assembly.part_snapped.connect(_on_part_snapped)
	interaction.hover_description_requested.connect(_on_hover_description_requested)
	interaction.hover_description_cleared.connect(_on_hover_description_cleared)
	interaction.snap_missed.connect(_on_snap_missed)
	hud.launch_requested.connect(_on_launch_requested)
	hud.reset_requested.connect(_on_reset_requested)
	launch_controller.launch_started.connect(_on_launch_started)
	launch_controller.launch_finished.connect(_on_launch_finished)
	launch_controller.flight_metrics_updated.connect(_on_flight_metrics_updated)

	_on_readiness_changed(assembly.is_ready_for_launch())
	_update_progress_line()


func _instantiate_part(scene_path: String, id_override: String, position_value: Vector3, rotation_degrees_value: Vector3) -> Node:
	var packed: PackedScene = load(scene_path) as PackedScene
	var part: Node = packed.instantiate() as Node
	part.part_id = id_override
	part.position = position_value
	part.rotation_degrees = rotation_degrees_value
	return part


func _add_snap_zone(zone_id: String, accepted_type: StringName, position_value: Vector3, rotation_degrees_value: Vector3, tolerance: float) -> void:
	var zone: Node = SnapZoneScript.new()
	zone.name = zone_id
	zone.zone_id = zone_id
	zone.accepted_type = accepted_type
	zone.position = position_value
	zone.rotation_degrees = rotation_degrees_value
	zone.tolerance = tolerance
	assembly.add_child(zone)
	assembly.register_snap_zone(zone)


func _on_readiness_changed(ready: bool) -> void:
	hud.set_ready(ready)
	launch_controller.set_ready_visual(ready)
	_update_progress_line()
	if ready:
		if assembly.get_snapped_fin_count() >= 3:
			hud.set_context("Montagem completa. A base acendeu para um teste estável.")
		else:
			hud.set_context("Pronto para testar, mas a terceira aleta melhora a estabilidade.")
	else:
		hud.set_context("Siga os fantasmas coloridos: cone no bico, aletas no corpo, elástico na base.")


func _on_assembly_changed(_summary: Dictionary) -> void:
	_update_progress_line()
	if debug_overlay != null and debug_overlay.visible:
		debug_overlay.set_snapshot(telemetry.snapshot(assembly.get_summary()))


func _on_part_snapped(message: String) -> void:
	hud.set_context(message)


func _on_launch_requested() -> void:
	launch_controller.request_launch()


func _on_reset_requested() -> void:
	assembly.reset_parts(all_parts)
	telemetry.reset()
	launch_controller.set_ready_visual(false)
	hud.set_ready(false)
	hud.set_context("Bancada reiniciada. Arraste uma peça para começar de novo.")
	_idle_hint_visible = false


func _on_launch_started(profile: String) -> void:
	hud.set_context("Preparando lançamento. Observe altura, desvio e giro.")


func _on_launch_finished(profile: String) -> void:
	if profile == "stable":
		hud.set_context("O conjunto subiu alinhado por mais tempo.")
	elif profile == "reasonable_spin":
		hud.set_context("As aletas não estabilizaram todo o giro.")
	else:
		hud.set_context("A energia ou o alinhamento produziram um voo curto.")
	if debug_overlay != null and debug_overlay.visible:
		debug_overlay.set_snapshot(telemetry.snapshot(assembly.get_summary()))


func _on_flight_metrics_updated(_summary: Dictionary) -> void:
	if debug_overlay != null and debug_overlay.visible:
		debug_overlay.set_snapshot(telemetry.snapshot(assembly.get_summary()))


func _on_hover_description_requested(part: Node) -> void:
	if part == null or hud == null:
		return
	hud.show_piece_description(part.get_hover_title(), part.get_hover_description())


func _on_hover_description_cleared() -> void:
	if hud != null:
		hud.clear_piece_description()


func _on_snap_missed(part: Node) -> void:
	if part == null or hud == null:
		return
	hud.set_context("%s ainda não encaixou. Solte mais perto de um fantasma colorido." % part.display_name)


func _update_idle_hint() -> void:
	if telemetry == null or hud == null:
		return
	if telemetry.seconds_since_last_event() > 6.0 and not _idle_hint_visible:
		hud.set_context("Dica: arraste uma peça, aproxime das áreas luminosas e solte para encaixar.")
		_idle_hint_visible = true
	elif telemetry.seconds_since_last_event() <= 2.0:
		_idle_hint_visible = false


func _update_progress_line() -> void:
	if hud == null or assembly == null:
		return
	var cone_text: String = "Cone OK" if assembly.get_zone_quality("nose") > 0.0 else "Cone --"
	var fin_count: int = assembly.get_snapped_fin_count()
	var fins_text: String = "Aletas %d/3" % fin_count
	var energy_text: String = "Elástico OK" if assembly.get_energy_score() > 0.0 else "Elástico --"
	if assembly.is_ready_for_launch() and fin_count >= 3:
		hud.set_progress("%s | %s | %s | Montagem completa" % [cone_text, fins_text, energy_text])
	elif assembly.is_ready_for_launch():
		hud.set_progress("%s | %s | %s | Teste parcial liberado" % [cone_text, fins_text, energy_text])
	else:
		hud.set_progress("%s | %s | %s" % [cone_text, fins_text, energy_text])
