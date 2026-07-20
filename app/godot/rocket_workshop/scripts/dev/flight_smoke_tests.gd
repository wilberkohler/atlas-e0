extends SceneTree

const FlightParametersScript := preload("res://scripts/flight/flight_parameters.gd")
const FlightModelScript := preload("res://scripts/flight/flight_model.gd")


func _initialize() -> void:
	var stable: Dictionary = _run_case(_params(0.92, 3, 0.95, 0.96, 0.94, 0.92, 0.22, 4242))
	var misaligned_fin: Dictionary = _run_case(_params(0.92, 3, 0.42, 0.96, 0.70, 0.70, 0.30, 4242))
	var low_energy: Dictionary = _run_case(_params(0.28, 3, 0.95, 0.96, 0.90, 0.92, 0.20, 4242))
	var crooked_nose: Dictionary = _run_case(_params(0.88, 3, 0.90, 0.28, 0.62, 0.70, 0.30, 4242))
	var deterministic_a: Dictionary = _run_case(_params(0.74, 2, 0.66, 0.84, 0.76, 0.74, 0.26, 777))
	var deterministic_b: Dictionary = _run_case(_params(0.74, 2, 0.66, 0.84, 0.76, 0.74, 0.26, 777))

	_assert(float(stable.summary.max_height) > 4.0, "stable flight should reach visible height")
	_assert(stable.profile == "stable", "stable setup should classify as stable")
	_assert(float(misaligned_fin.summary.mean_angular_velocity) > float(stable.summary.mean_angular_velocity), "misaligned fin should increase spin")
	_assert(float(low_energy.summary.max_height) < float(stable.summary.max_height), "low energy should reduce max height")
	_assert(float(crooked_nose.summary.horizontal_displacement) > float(stable.summary.horizontal_displacement) * 0.65, "crooked nose should create visible lateral displacement")
	_assert(_close(float(deterministic_a.summary.max_height), float(deterministic_b.summary.max_height)), "same seed should repeat max height")
	_assert(_close(float(deterministic_a.summary.horizontal_displacement), float(deterministic_b.summary.horizontal_displacement)), "same seed should repeat displacement")

	print("Flight smoke tests passed.")
	quit(0)


func _params(energy: float, fin_count: int, fin_alignment: float, nose: float, attachment: float, mass: float, wind: float, seed: int) -> Resource:
	var params: Resource = FlightParametersScript.new()
	params.energy = energy
	params.fin_count = fin_count
	params.fin_symmetry = clampf(float(fin_count) / 3.0 * 0.76 + fin_alignment * 0.24, 0.0, 1.0)
	params.fin_alignment = fin_alignment
	params.nose_alignment = nose
	params.attachment_quality = attachment
	params.mass_balance = mass
	params.body_drag_factor = clampf(0.20 + (1.0 - nose) * 0.35 + (1.0 - params.fin_symmetry) * 0.20, 0.0, 1.0)
	params.wind_strength = wind
	params.flight_seed = seed
	return params


func _run_case(params: Resource) -> Dictionary:
	var model: RefCounted = FlightModelScript.new()
	model.setup(1, "test", params, Vector3(0.0, 0.52, 0.0), Vector3.ZERO)
	for _i: int in range(720):
		model.step(1.0 / 60.0)
		if model.impacted:
			break
	var summary: Dictionary = model.finish_summary()
	var profile: String = model.result_profile()
	return {"summary": summary, "profile": profile}


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	printerr("Flight smoke test failed: %s" % message)
	quit(1)


func _close(a: float, b: float, tolerance: float = 0.001) -> bool:
	return absf(a - b) <= tolerance
