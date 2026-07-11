extends SceneTree

const MAIN_SCENE := "res://scenes/vertical_slice_v1/vertical_slice_main.tscn"
const FIELD_SCENE := "res://scenes/vertical_slice_v1/field_test_scene.tscn"
const ProfileScript := preload("res://scripts/launch/flight_profile.gd")
const MetricsScript := preload("res://scripts/assembly/assembly_metrics.gd")

var _main: Node
var _field: Node
var _frame := 0
var _flight_summary: Dictionary = {}
var _failed := false


func _initialize() -> void:
	var packed: PackedScene = load(MAIN_SCENE) as PackedScene
	if packed == null:
		_fail("vertical_slice_main.tscn não carregou")
		return
	_main = packed.instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 6:
		_validate_workshop()
	if _frame == 10 and not _failed:
		_prepare_field()
	if _frame == 14 and not _failed:
		_run_flight_fast()
	if _frame == 16 and not _failed:
		_validate_flight()
		if not _failed:
			print("Vertical slice v1 integrated scene smoke test passed.")
			quit(0)
		return true
	if _frame > 80 and not _failed:
		_fail("scene smoke excedeu o limite de frames")
	return false


func _validate_workshop() -> void:
	if _main.workshop == null or _main.workshop.camera == null:
		_fail("oficina/câmera não foi construída")
		return
	for required_name: String in ["PetBottleAssembly", "Fin1", "Fin2", "Fin3", "PaperNoseCone", "TapeRoll", "WaterPitcher", "LaunchStandV2"]:
		if _main.workshop.find_child(required_name, true, false) == null:
			_fail("objeto reconhecível ausente: %s" % required_name)
			return
	if _main.workshop.find_child("PetBottleV2", true, false) == null:
		_fail("garrafa v2 não está na oficina")
		return
	if _main.developer_overlay.visible:
		_fail("painel F2 deve iniciar oculto")
		return
	if _main.workshop.is_ready_for_test():
		_fail("montagem vazia não deve liberar a base")


func _prepare_field() -> void:
	_main.queue_free()
	_main = null
	var profile := ProfileScript.new()
	var configuration: Dictionary = profile.to_configuration_snapshot()
	var packed: PackedScene = load(FIELD_SCENE) as PackedScene
	_field = packed.instantiate()
	root.add_child(_field)
	_field.launch_completed.connect(func(summary: Dictionary) -> void: _flight_summary = summary)
	_field.call("setup", configuration, MetricsScript.evaluate(configuration), 4242, [])
	_field.call("set_active", true)
	_field.call("apply_developer_energy", 0.76)
	if not bool(_field.call("request_developer_launch")):
		_fail("sequência recusou lançamento de desenvolvimento")


func _run_flight_fast() -> void:
	if _field == null or _field.rocket_body == null or _field.rocket_body.simulator == null:
		_fail("RigidBody3D/simulador não foi criado")
		return
	for _index: int in range(2600):
		_field.rocket_body.simulator.call("advance_fixed_steps", 1)
		if _field.rocket_body.simulator.call("is_finished"):
			break
	if not _field.rocket_body.simulator.call("is_finished"):
		_fail("simulação integrada não terminou")


func _validate_flight() -> void:
	if _flight_summary.is_empty():
		_fail("launch_completed não produziu resumo")
		return
	var timestamps: Dictionary = _flight_summary.get("state_timestamps", {})
	for required_state: StringName in [&"THRUST", &"COAST", &"APEX", &"DESCENT", &"IMPACT", &"REVIEW"]:
		if not timestamps.has(required_state):
			_fail("estado de voo ausente: %s" % String(required_state))
			return
	if (_flight_summary.get("samples", []) as Array).size() < 12:
		_fail("trajetória integrada não foi registrada")
		return
	if _field.trajectory_renderer.rendered_attempts.size() != 1:
		_fail("renderer não mostrou a tentativa atual")
		return
	if _field.find_child("VolumetricWaterJet", true, false) == null:
		_fail("jato volumétrico de água ausente")


func _fail(message: String) -> void:
	_failed = true
	printerr("VS1_SCENE_SMOKE_FAIL %s" % message)
	quit(1)
