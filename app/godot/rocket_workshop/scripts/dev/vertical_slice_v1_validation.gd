extends SceneTree

const ConfigurationScript := preload("res://scripts/assembly/rocket_configuration.gd")
const MetricsScript := preload("res://scripts/assembly/assembly_metrics.gd")
const SimulatorScript := preload("res://scripts/launch/bottle_rocket_simulator.gd")
const AttemptRecordScript := preload("res://scripts/telemetry/attempt_record.gd")
const AttemptHistoryScript := preload("res://scripts/telemetry/attempt_history.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	var stable_configuration: RefCounted = _configuration("stable")
	var spin_configuration: RefCounted = _configuration("spin")
	var lateral_configuration: RefCounted = _configuration("lateral")
	var short_configuration: RefCounted = _configuration("short")

	var stable := _run_case(stable_configuration, 4242)
	var spin := _run_case(spin_configuration, 4242)
	var lateral := _run_case(lateral_configuration, 4242)
	var short := _run_case(short_configuration, 4242)
	var repeat := _run_case(stable_configuration, 4242)

	_expect(float(stable.total_rotation) < float(spin.total_rotation), "configuração estável deve girar menos")
	_expect(float(spin.max_spin) > float(stable.max_spin), "aleta inclinada deve produzir mais torque/giro")
	_expect(float(lateral.lateral_displacement) > float(stable.lateral_displacement), "assimetria deve aumentar o desvio lateral")
	_expect(float(short.max_height) < float(stable.max_height), "energia menor deve produzir voo mais curto")
	_expect(stable.states.has("APEX") and stable.states.has("DESCENT"), "voo deve alcançar ápice e descida")
	_expect(stable.samples.size() > 12, "trajetória deve ser registrada")
	_expect(bool(stable.finite), "forças e movimento não podem gerar NaN/infinito")
	_expect(is_equal_approx(float(stable.max_height), float(repeat.max_height)), "seed fixa deve repetir a altura")
	_expect(is_equal_approx(float(stable.lateral_displacement), float(repeat.lateral_displacement)), "seed fixa deve repetir o desvio")

	_validate_history(stable_configuration, stable, spin)
	_validate_configuration_restore(stable_configuration)
	_validate_unexpected_collision(stable_configuration)

	if not _failures.is_empty():
		for failure: String in _failures:
			printerr("VS1_VALIDATION_FAIL %s" % failure)
		quit(1)
		return

	print("VS1_CASE stable height=%.3f lateral=%.3f rotation=%.3f" % [stable.max_height, stable.lateral_displacement, stable.total_rotation])
	print("VS1_CASE spin height=%.3f lateral=%.3f rotation=%.3f" % [spin.max_height, spin.lateral_displacement, spin.total_rotation])
	print("VS1_CASE lateral height=%.3f lateral=%.3f rotation=%.3f" % [lateral.max_height, lateral.lateral_displacement, lateral.total_rotation])
	print("VS1_CASE short height=%.3f lateral=%.3f rotation=%.3f" % [short.max_height, short.lateral_displacement, short.total_rotation])
	print("Vertical slice v1 causality and telemetry validation passed.")
	quit(0)


func _configuration(profile: String) -> RefCounted:
	var configuration: RefCounted = ConfigurationScript.new()
	var fin_count := 3
	var tilts := [0.01, -0.01, 0.0]
	var orientations := [0.0, 0.01, -0.01]
	var heights := [0.50, 0.51, 0.49]
	var positions := [0.0, 0.333, 0.667]
	var qualities := [0.90, 0.88, 0.89]
	var water := 0.54
	var energy := 0.76
	var cone_deviation := 0.01
	var cone_centering := 0.96
	if profile == "spin":
		tilts = [0.72, 0.0, -0.02]
		orientations = [0.62, 0.0, 0.0]
		qualities = [0.46, 0.84, 0.82]
	elif profile == "lateral":
		fin_count = 2
		tilts = [0.28, -0.04]
		orientations = [0.34, -0.02]
		heights = [0.34, 0.68]
		positions = [0.02, 0.43]
		qualities = [0.52, 0.80]
		cone_deviation = 0.38
		cone_centering = 0.58
	elif profile == "short":
		water = 0.20
		energy = 0.16

	for index: int in range(fin_count):
		configuration.call("set_fin", "fin_%d" % [index + 1], positions[index], tilts[index], heights[index], orientations[index], qualities[index], true, true)
	configuration.call("set_cone", true, cone_deviation, cone_centering, 0.82, true)
	configuration.call("set_water_level", water)
	configuration.call("set_energy_level", energy)
	return configuration


func _run_case(configuration: RefCounted, seed: int) -> Dictionary:
	var configuration_snapshot: Dictionary = configuration.call("snapshot")
	var metrics: Dictionary = MetricsScript.evaluate(configuration_snapshot)
	var simulator_config := _simulator_config(configuration_snapshot, metrics)
	var simulator: RefCounted = SimulatorScript.new()
	simulator.call("setup", simulator_config, seed, Transform3D(Basis.IDENTITY, Vector3.ZERO), 0.0)
	simulator.call("launch")

	var states: Array[String] = []
	var samples: Array[Dictionary] = []
	var max_height := 0.0
	var lateral_displacement := 0.0
	var total_rotation := 0.0
	var max_spin := 0.0
	var finite := true
	for _step: int in range(2400):
		simulator.call("advance_fixed_steps", 1)
		var snapshot: Dictionary = simulator.call("get_snapshot")
		var state_name := String(snapshot.state)
		if not states.has(state_name):
			states.append(state_name)
		var position: Vector3 = snapshot.position
		var velocity: Vector3 = snapshot.velocity
		var spin: Vector3 = snapshot.angular_velocity
		finite = finite and _finite_vector(position) and _finite_vector(velocity) and _finite_vector(spin)
		max_height = maxf(max_height, position.y)
		lateral_displacement = maxf(lateral_displacement, Vector2(position.x, position.z).length())
		max_spin = maxf(max_spin, spin.length())
		total_rotation += spin.length() * float(SimulatorScript.FIXED_STEP)
		if _step % 4 == 0:
			samples.append({"t": float(snapshot.elapsed), "position": position, "state": state_name})
		if bool(simulator.call("is_finished")):
			break
	return {
		"states": states,
		"samples": samples,
		"max_height": max_height,
		"lateral_displacement": lateral_displacement,
		"total_rotation": total_rotation,
		"max_spin": max_spin,
		"finite": finite,
		"finished": simulator.call("is_finished"),
	}


func _simulator_config(configuration: Dictionary, metrics: Dictionary) -> Dictionary:
	return {
		"energy_level": float(configuration.get("energy_level", 0.0)),
		"water_level": float(configuration.get("water_level", 0.0)),
		"fin_presence": clampf(float(metrics.get("fin_count", 0)) / 3.0, 0.0, 1.0),
		"fin_symmetry": float(metrics.get("fin_spacing_score", 0.0)),
		"fin_alignment": (float(metrics.get("fin_tilt_score", 0.0)) + float(metrics.get("fin_orientation_score", 0.0))) * 0.5,
		"fin_height_consistency": float(metrics.get("fin_height_score", 0.0)),
		"attachment_quality": float(metrics.get("attachment_score", 0.0)),
		"nose_alignment": float(metrics.get("cone_alignment_score", 0.0)),
		"mass_balance": 1.0 - float(metrics.get("asymmetry_magnitude", 0.0)) * 0.7,
		"body_drag": clampf(0.30 + (1.0 - float(metrics.get("stability_score", 0.0))) * 0.34, 0.0, 1.0),
		"wind_level": 0.14,
		"anticipation_level": 0.48,
		"asymmetry_vector": metrics.get("asymmetry_vector", {}),
	}


func _validate_history(configuration: RefCounted, stable: Dictionary, spin: Dictionary) -> void:
	var history: RefCounted = AttemptHistoryScript.new()
	for index: int in range(3):
		var record: RefCounted = AttemptRecordScript.new()
		record.call("begin", "test_session", "attempt_%d" % [index + 1], configuration, MetricsScript.evaluate(configuration), 4242)
		record.call("mark_launch", 1.0 + index)
		var source: Dictionary = stable if index != 1 else spin
		record.call("finish_flight", {
			"max_height": float(source.max_height),
			"time_to_apex": 1.2,
			"horizontal_displacement": float(source.lateral_displacement),
			"total_rotation": float(source.total_rotation),
			"flight_duration": 3.4,
			"impact_position": Vector3(0.2 * index, 0.0, 0.1),
			"samples": source.samples,
		})
		history.call("add_attempt", record)
	_expect(int(history.call("size")) == 2, "histórico visual deve preservar exatamente as duas últimas tentativas")
	var attempts: Array = history.call("get_visual_attempts")
	_expect(attempts.size() == 2 and String(attempts[0].attempt_id) == "attempt_2", "histórico deve descartar apenas a tentativa visual mais antiga")


func _validate_configuration_restore(configuration: RefCounted) -> void:
	var snapshot: Dictionary = configuration.call("snapshot")
	var restored: RefCounted = ConfigurationScript.new()
	restored.call("apply_snapshot", snapshot, false)
	_expect(restored.call("snapshot").get("fins", []) == snapshot.get("fins", []), "retorno à oficina deve preservar a configuração")


func _validate_unexpected_collision(configuration: RefCounted) -> void:
	var metrics: Dictionary = MetricsScript.evaluate(configuration)
	var simulator: RefCounted = SimulatorScript.new()
	simulator.call("setup", _simulator_config(configuration.call("snapshot"), metrics), 99, Transform3D.IDENTITY, 0.0)
	simulator.call("launch")
	for _index: int in range(60):
		simulator.call("advance_fixed_steps", 1)
	simulator.call("register_impact", Vector3(0.0, 0.1, 0.0), &"validation_collision")
	for _index: int in range(120):
		simulator.call("advance_fixed_steps", 1)
		if bool(simulator.call("is_finished")):
			break
	_expect(bool(simulator.call("is_finished")), "simulação deve terminar após colisão inesperada")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finite_vector(value: Vector3) -> bool:
	return is_finite(value.x) and is_finite(value.y) and is_finite(value.z)
