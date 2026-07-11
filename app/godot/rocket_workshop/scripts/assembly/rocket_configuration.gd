extends RefCounted
class_name VS1RocketConfiguration

signal changed(snapshot: Dictionary)

const SCHEMA_VERSION := 1
const MIN_WATER_LEVEL := 0.05
const MIN_ATTACHMENT_QUALITY := 0.05

var body_present: bool = true
var fins: Dictionary = {}
var cone: Dictionary = {}
var water_level: float = 0.0
var energy_level: float = 0.0
var revision: int = 0


func _init() -> void:
	reset(false)


func reset(emit_change: bool = true) -> void:
	body_present = true
	fins.clear()
	cone = _default_cone()
	water_level = 0.0
	energy_level = 0.0
	revision = 0
	if emit_change:
		changed.emit(snapshot())


func set_body_present(value: bool) -> void:
	if body_present == value:
		return
	body_present = value
	_touch()


func set_fin(
	fin_id: String,
	angular_position: float,
	tilt: float,
	height: float,
	orientation: float,
	attachment_quality: float,
	fixed: bool = true,
	attached: bool = true
) -> void:
	update_fin(fin_id, {
		"attached": attached,
		"angular_position": angular_position,
		"tilt": tilt,
		"height": height,
		"orientation": orientation,
		"attachment_quality": attachment_quality,
		"fixed": fixed
	})


func update_fin(fin_id: String, values: Dictionary) -> void:
	var safe_id := fin_id.strip_edges()
	if safe_id.is_empty():
		return
	var current: Dictionary = fins.get(safe_id, _default_fin(safe_id))
	var merged := current.duplicate(true)
	for key: Variant in values.keys():
		merged[String(key)] = values[key]
	fins[safe_id] = _normalized_fin(safe_id, merged)
	_touch()


func remove_fin(fin_id: String) -> void:
	if not fins.has(fin_id):
		return
	var state: Dictionary = fins[fin_id]
	if not bool(state.get("attached", false)):
		return
	state["attached"] = false
	state["fixed"] = false
	state["attachment_quality"] = 0.0
	state["reposition_count"] = int(state.get("reposition_count", 0)) + 1
	fins[fin_id] = _normalized_fin(fin_id, state)
	_touch()


func mark_fin_repositioned(fin_id: String) -> void:
	if not fins.has(fin_id):
		return
	var state: Dictionary = fins[fin_id]
	state["reposition_count"] = int(state.get("reposition_count", 0)) + 1
	fins[fin_id] = _normalized_fin(fin_id, state)
	_touch()


func get_fin(fin_id: String) -> Dictionary:
	if not fins.has(fin_id):
		return {}
	return (fins[fin_id] as Dictionary).duplicate(true)


func get_attached_fins() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for state: Dictionary in _sorted_fin_states():
		if bool(state.get("attached", false)):
			output.append(state.duplicate(true))
	return output


func get_attached_fin_count() -> int:
	return get_attached_fins().size()


func set_cone(
	present: bool,
	angular_deviation: float = 0.0,
	centering: float = 1.0,
	attachment_quality: float = 0.0,
	fixed: bool = false
) -> void:
	cone = {
		"present": present,
		"angular_deviation": _normalized_signed(angular_deviation),
		"centering": _normalized(centering),
		"attachment_quality": _normalized(attachment_quality),
		"fixed": fixed and present
	}
	_touch()


func remove_cone() -> void:
	set_cone(false)


func get_cone_alignment() -> float:
	if not bool(cone.get("present", false)):
		return 0.0
	var centering := _normalized(float(cone.get("centering", 0.0)))
	var deviation := absf(_normalized_signed(float(cone.get("angular_deviation", 0.0))))
	return _normalized(centering * (1.0 - deviation))


func set_water_level(value: float) -> void:
	var normalized := _normalized(value)
	if is_equal_approx(water_level, normalized):
		return
	water_level = normalized
	_touch()


func set_energy_level(value: float) -> void:
	var normalized := _normalized(value)
	if is_equal_approx(energy_level, normalized):
		return
	energy_level = normalized
	_touch()


func is_minimum_test_ready() -> bool:
	if not body_present or water_level < MIN_WATER_LEVEL:
		return false
	var attached := get_attached_fins()
	if attached.size() < 2:
		return false
	var fixed_count := 0
	for fin: Dictionary in attached:
		if bool(fin.get("fixed", false)) and float(fin.get("attachment_quality", 0.0)) >= MIN_ATTACHMENT_QUALITY:
			fixed_count += 1
	return fixed_count >= 2


func snapshot() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"revision": revision,
		"body_present": body_present,
		"fins": _sorted_fin_states(),
		"cone": cone.duplicate(true),
		"cone_alignment": get_cone_alignment(),
		"water_level": water_level,
		"energy_level": energy_level,
		"minimum_test_ready": is_minimum_test_ready()
	}


func to_dict() -> Dictionary:
	return snapshot()


func apply_snapshot(data: Dictionary, emit_change: bool = true) -> bool:
	body_present = bool(data.get("body_present", true))
	water_level = _normalized(float(data.get("water_level", 0.0)))
	energy_level = _normalized(float(data.get("energy_level", 0.0)))
	cone = _normalized_cone(_dictionary(data.get("cone", {})))
	fins.clear()

	var raw_fins: Variant = data.get("fins", [])
	if typeof(raw_fins) == TYPE_ARRAY:
		for raw_fin: Variant in raw_fins:
			if typeof(raw_fin) != TYPE_DICTIONARY:
				continue
			var fin_data: Dictionary = raw_fin
			var fin_id := String(fin_data.get("fin_id", "")).strip_edges()
			if not fin_id.is_empty():
				fins[fin_id] = _normalized_fin(fin_id, fin_data)
	elif typeof(raw_fins) == TYPE_DICTIONARY:
		var fin_map: Dictionary = raw_fins
		for raw_id: Variant in fin_map.keys():
			var fin_id := String(raw_id).strip_edges()
			if fin_id.is_empty() or typeof(fin_map[raw_id]) != TYPE_DICTIONARY:
				continue
			fins[fin_id] = _normalized_fin(fin_id, fin_map[raw_id])

	revision = maxi(0, int(data.get("revision", 0)))
	if emit_change:
		changed.emit(snapshot())
	return true


func clone() -> RefCounted:
	var copy: RefCounted = get_script().new()
	copy.apply_snapshot(snapshot(), false)
	return copy


static func from_snapshot(data: Dictionary) -> RefCounted:
	var configuration: RefCounted = load("res://scripts/assembly/rocket_configuration.gd").new()
	configuration.apply_snapshot(data, false)
	return configuration


func _touch() -> void:
	revision += 1
	changed.emit(snapshot())


func _sorted_fin_states() -> Array[Dictionary]:
	var ids: Array[String] = []
	for raw_id: Variant in fins.keys():
		ids.append(String(raw_id))
	ids.sort()
	var output: Array[Dictionary] = []
	for fin_id: String in ids:
		output.append((fins[fin_id] as Dictionary).duplicate(true))
	return output


func _default_fin(fin_id: String) -> Dictionary:
	return {
		"fin_id": fin_id,
		"attached": false,
		"angular_position": 0.0,
		"tilt": 0.0,
		"height": 0.5,
		"orientation": 0.0,
		"reposition_count": 0,
		"attachment_quality": 0.0,
		"fixed": false
	}


func _normalized_fin(fin_id: String, source: Dictionary) -> Dictionary:
	var attached := bool(source.get("attached", true))
	return {
		"fin_id": fin_id,
		"attached": attached,
		"angular_position": _normalized_turn(float(source.get("angular_position", 0.0))),
		"tilt": _normalized_signed(float(source.get("tilt", 0.0))),
		"height": _normalized(float(source.get("height", 0.5))),
		"orientation": _normalized_signed(float(source.get("orientation", 0.0))),
		"reposition_count": maxi(0, int(source.get("reposition_count", 0))),
		"attachment_quality": _normalized(float(source.get("attachment_quality", 0.0))) if attached else 0.0,
		"fixed": bool(source.get("fixed", false)) and attached
	}


func _default_cone() -> Dictionary:
	return {
		"present": false,
		"angular_deviation": 0.0,
		"centering": 1.0,
		"attachment_quality": 0.0,
		"fixed": false
	}


func _normalized_cone(source: Dictionary) -> Dictionary:
	var present := bool(source.get("present", false))
	return {
		"present": present,
		"angular_deviation": _normalized_signed(float(source.get("angular_deviation", 0.0))),
		"centering": _normalized(float(source.get("centering", 1.0))),
		"attachment_quality": _normalized(float(source.get("attachment_quality", 0.0))) if present else 0.0,
		"fixed": bool(source.get("fixed", false)) and present
	}


func _normalized(value: float) -> float:
	return clampf(_finite_or_zero(value), 0.0, 1.0)


func _normalized_signed(value: float) -> float:
	return clampf(_finite_or_zero(value), -1.0, 1.0)


func _normalized_turn(value: float) -> float:
	return fposmod(_finite_or_zero(value), 1.0)


func _finite_or_zero(value: float) -> float:
	return value if is_finite(value) else 0.0


func _dictionary(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}
