extends Node3D
class_name RocketAssembly

signal readiness_changed(ready: bool)
signal assembly_changed(summary: Dictionary)
signal part_snapped(message: String)

var telemetry: Node = null
var loose_parts_root: Node3D = null
var snap_zones: Array[Node] = []
var _ready_for_launch: bool = false
var _home_position: Vector3 = Vector3.ZERO
var _home_rotation: Vector3 = Vector3.ZERO


func configure(new_telemetry: Node, new_loose_parts_root: Node3D) -> void:
	telemetry = new_telemetry
	loose_parts_root = new_loose_parts_root
	_home_position = position
	_home_rotation = rotation
	_update_readiness()


func register_snap_zone(zone: Node) -> void:
	if not snap_zones.has(zone):
		snap_zones.append(zone)
	_update_readiness()


func find_best_snap_zone(part: Node) -> Node:
	var best_zone: Node = null
	var best_score: float = -1.0
	for zone: Node in snap_zones:
		if not zone.can_accept(part):
			continue
		var distance: float = part.global_position.distance_to(zone.global_position)
		if distance > zone.tolerance:
			continue
		var quality: float = zone.estimate_quality(part)
		var distance_score: float = 1.0 - clampf(distance / zone.tolerance, 0.0, 1.0)
		var score: float = maxf(quality, distance_score)
		if score > best_score:
			best_score = score
			best_zone = zone
	return best_zone


func update_snap_previews(part: Node) -> void:
	for zone: Node in snap_zones:
		if part == null:
			zone.show_idle_hint()
			continue
		var compatible: bool = zone.can_accept(part)
		var distance: float = part.global_position.distance_to(zone.global_position)
		var active: bool = compatible and distance <= zone.tolerance * 2.8
		if active:
			zone.set_preview(true, compatible)
		else:
			zone.show_idle_hint()


func snap_part(part: Node, zone: Node) -> bool:
	if part == null or zone == null:
		return false
	if not zone.can_accept(part):
		if telemetry != null:
			telemetry.record_snap_attempt(part.part_id, zone.zone_id, false, 0.0)
		return false

	var quality: float = maxf(zone.estimate_quality(part), 0.42)
	if part.is_snapped:
		remove_part(part)

	if part.get_parent() != self:
		part.reparent(self, true)

	zone.occupied_part = part
	part.snap_to_zone(zone, quality)
	zone.set_occupied_visual(true)
	update_snap_previews(null)
	if telemetry != null:
		telemetry.record_snap_attempt(part.part_id, zone.zone_id, true, quality)
		telemetry.record("snap", part.part_id, {
			"zone": zone.zone_id,
			"quality": quality,
			"rotationDegrees": _vec3(part.rotation_degrees),
			"position": _vec3(part.global_position)
		})
	part_snapped.emit(_snap_message(part, zone))
	_update_readiness()
	return true


func remove_part(part: Node) -> void:
	if part == null:
		return
	var old_zone: Node = part.snap_zone
	if old_zone != null:
		old_zone.clear()
	if loose_parts_root != null and part.get_parent() != loose_parts_root:
		part.reparent(loose_parts_root, true)
	part.detach_from_snap()
	if telemetry != null:
		telemetry.record("unsnap", part.part_id, {"zone": old_zone.zone_id if old_zone != null else ""})
	_update_readiness()


func is_ready_for_launch() -> bool:
	return _ready_for_launch


func get_summary() -> Dictionary:
	var snapped: Dictionary = {}
	for zone: Node in snap_zones:
		if zone.occupied_part != null:
			snapped[zone.zone_id] = {
				"partId": zone.occupied_part.part_id,
				"partType": String(zone.occupied_part.part_type),
				"quality": zone.occupied_part.snap_quality
			}
	return {
		"readyForLaunch": _ready_for_launch,
		"snapped": snapped,
		"finCount": get_snapped_fin_count(),
		"coneQuality": get_zone_quality("nose"),
		"energyScore": get_energy_score(),
		"missing": get_missing_requirements()
	}


func get_missing_requirements() -> Array[String]:
	var missing: Array[String] = []
	if get_zone_quality("nose") <= 0.0:
		missing.append("cone")
	var fins_remaining: int = maxi(0, 2 - get_snapped_fin_count())
	if fins_remaining == 1:
		missing.append("1 aleta")
	elif fins_remaining > 1:
		missing.append("%d aletas" % fins_remaining)
	if get_energy_score() <= 0.0:
		missing.append("elástico")
	return missing


func get_snapped_fin_count() -> int:
	var count: int = 0
	for zone: Node in snap_zones:
		if zone.accepted_type == &"fin" and zone.occupied_part != null:
			count += 1
	return count


func get_fin_qualities() -> Array[float]:
	var qualities: Array[float] = []
	for zone: Node in snap_zones:
		if zone.accepted_type == &"fin" and zone.occupied_part != null:
			qualities.append(zone.occupied_part.snap_quality)
	return qualities


func get_zone_quality(zone_id: String) -> float:
	for zone: Node in snap_zones:
		if zone.zone_id == zone_id and zone.occupied_part != null:
			return zone.occupied_part.snap_quality
	return 0.0


func get_energy_score() -> float:
	for zone: Node in snap_zones:
		if zone.accepted_type == &"energy" and zone.occupied_part != null:
			var energy_part: Node = zone.occupied_part
			return clampf((energy_part.energy_level * 0.72) + (energy_part.snap_quality * 0.28), 0.0, 1.0)
	return 0.0


func reset_parts(parts: Array[Node]) -> void:
	for zone: Node in snap_zones:
		zone.clear()
	for part: Node in parts:
		part.reset_to_initial()
	position = _home_position
	rotation = _home_rotation
	_update_readiness()


func _update_readiness() -> void:
	var has_cone: bool = get_zone_quality("nose") > 0.0
	var has_energy: bool = get_energy_score() > 0.0
	var has_fins: bool = get_snapped_fin_count() >= 2
	var new_ready: bool = has_cone and has_energy and has_fins
	if new_ready != _ready_for_launch:
		_ready_for_launch = new_ready
		readiness_changed.emit(_ready_for_launch)
	assembly_changed.emit(get_summary())


func _snap_message(part: Node, zone: Node) -> String:
	if zone.accepted_type == &"nose":
		return "Cone encaixado no bico."
	if zone.accepted_type == &"fin":
		return "%s encaixada. Aletas: %d/3." % [part.display_name, get_snapped_fin_count()]
	if zone.accepted_type == &"energy":
		return "Elástico encaixado na base."
	return "%s encaixada." % part.display_name


func _vec3(value: Vector3) -> Dictionary:
	return {
		"x": snappedf(value.x, 0.001),
		"y": snappedf(value.y, 0.001),
		"z": snappedf(value.z, 0.001)
	}
