extends Node
class_name VS1ObjectGrabber3D

signal hover_changed(part)
signal grab_started(part)
signal grab_released(part)
signal interaction(part, kind)

@export var camera_path: NodePath
@export var rotation_controller_path: NodePath
@export_flags_3d_physics var pick_collision_mask: int = 1
@export_range(1.0, 200.0, 1.0) var ray_length: float = 100.0
@export var drag_plane_y: float = 0.0
@export var ignore_pointer_over_gui: bool = true

var active_part: Node3D = null
var hovered_part: Node3D = null

var _enabled: bool = true
var _camera: Camera3D = null
var _rotation_controller: Node = null


func _ready() -> void:
	_resolve_camera()
	if not rotation_controller_path.is_empty():
		_rotation_controller = get_node_or_null(rotation_controller_path)
	if _rotation_controller == null:
		_rotation_controller = VS1RotationController.new()
		_rotation_controller.name = "RuntimeRotationController"
		add_child(_rotation_controller)
	set_process_unhandled_input(true)


func set_enabled(value: bool) -> void:
	_enabled = value
	set_process_unhandled_input(value)
	if not value:
		if active_part != null and active_part.has_method("end_grab"):
			active_part.call("end_grab")
		_set_hovered(null)
		active_part = null
		_set_rotation_target(null)
	for candidate: Node in get_tree().get_nodes_in_group(&"vs1_interactive_objects"):
		if candidate.has_method("set_enabled"):
			candidate.call("set_enabled", value)


func is_enabled() -> bool:
	return _enabled


func set_camera(value: Camera3D) -> void:
	_camera = value


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return
	_resolve_camera()
	if _camera == null:
		return

	if active_part != null and _route_rotation_input(event):
		_emit_interaction(active_part, &"rotated")
		get_viewport().set_input_as_handled()
		return

	var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if motion_event != null:
		if active_part != null:
			var pointer_world: Vector3 = _pointer_to_drag_plane(motion_event.position)
			active_part.call("drag_to", pointer_world)
			_apply_magnetic_pull(active_part)
			_update_snap_previews(active_part)
			_emit_interaction(active_part, &"dragged")
		else:
			_update_hover(motion_event.position)
		return

	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event == null or button_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if ignore_pointer_over_gui and _is_pointer_over_gui(button_event.position):
		return
	if button_event.pressed:
		_begin_pointer_grab(button_event.position)
	else:
		_end_pointer_grab(button_event.position)


func _begin_pointer_grab(pointer: Vector2) -> void:
	var pick: Dictionary = _pick(pointer)
	var part: Node3D = pick.get("part") as Node3D
	if part == null:
		return
	if not bool(_read_property(part, &"grabbable", true)):
		_emit_interaction(part, &"activated")
		get_viewport().set_input_as_handled()
		return

	_release_previous_zone(part)
	var hit_position: Vector3 = pick.get("position", part.global_position)
	if not bool(part.call("begin_grab", hit_position)):
		return
	active_part = part
	_set_hovered(part)
	_set_rotation_target(part)
	grab_started.emit(part)
	_emit_interaction(part, &"grab_started")
	get_viewport().set_input_as_handled()


func _end_pointer_grab(pointer: Vector2) -> void:
	if active_part == null:
		return
	var released_part: Node3D = active_part
	var zone: Node = _find_best_snap_zone(released_part, true)
	if zone != null and bool(zone.call("commit_snap", released_part)):
		_emit_interaction(released_part, &"snapped")
	else:
		released_part.call("end_grab", _pointer_to_drag_plane(pointer))
		_emit_interaction(released_part, &"grab_released")
	grab_released.emit(released_part)
	active_part = null
	_set_rotation_target(null)
	_update_snap_previews(null)
	get_viewport().set_input_as_handled()


func _update_hover(pointer: Vector2) -> void:
	var pick: Dictionary = _pick(pointer)
	_set_hovered(pick.get("part") as Node3D)


func _set_hovered(part: Node3D) -> void:
	if hovered_part == part:
		return
	if hovered_part != null and is_instance_valid(hovered_part):
		hovered_part.call("set_hovered", false)
	hovered_part = part
	if hovered_part != null:
		hovered_part.call("set_hovered", true)
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	hover_changed.emit(hovered_part)


func _pick(pointer: Vector2) -> Dictionary:
	var from: Vector3 = _camera.project_ray_origin(pointer)
	var to: Vector3 = from + _camera.project_ray_normal(pointer) * ray_length
	var query := PhysicsRayQueryParameters3D.create(from, to, pick_collision_mask)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var result: Dictionary = _camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return {}
	var collider: Object = result.get("collider") as Object
	if collider == null or not collider.has_meta(&"vs1_part"):
		return {}
	var part: Object = collider.get_meta(&"vs1_part") as Object
	if not (part is Node3D) or not part.has_method("begin_grab"):
		return {}
	return {"part": part, "position": result.get("position", Vector3.ZERO)}


func _pointer_to_drag_plane(pointer: Vector2) -> Vector3:
	var origin: Vector3 = _camera.project_ray_origin(pointer)
	var direction: Vector3 = _camera.project_ray_normal(pointer)
	if absf(direction.y) < 0.0001:
		return Vector3(origin.x, drag_plane_y, origin.z)
	var distance: float = (drag_plane_y - origin.y) / direction.y
	return origin + direction * maxf(distance, 0.0)


func _find_best_snap_zone(part: Node3D, capture_only: bool) -> Node:
	var best: Node = null
	var best_score: float = -1.0
	for candidate: Node in get_tree().get_nodes_in_group(&"vs1_snap_zones"):
		if not candidate.has_method("can_accept") or not bool(candidate.call("can_accept", part)):
			continue
		if capture_only and candidate.has_method("is_in_range") and not bool(candidate.call("is_in_range", part)):
			continue
		var score: float = float(candidate.call("get_capture_score", part)) if candidate.has_method("get_capture_score") else 0.0
		if score > best_score:
			best = candidate
			best_score = score
	return best


func _apply_magnetic_pull(part: Node3D) -> void:
	var zone: Node = _find_best_snap_zone(part, false)
	if zone == null or not zone.has_method("get_magnetic_target_position"):
		return
	part.set("target_position", zone.call("get_magnetic_target_position", part, part.get("target_position")))


func _update_snap_previews(part: Node3D) -> void:
	for zone: Node in get_tree().get_nodes_in_group(&"vs1_snap_zones"):
		if not zone.has_method("set_preview"):
			continue
		var compatible: bool = part != null and bool(zone.call("can_accept", part))
		var active: bool = compatible
		if active and zone.has_method("is_in_magnetic_range"):
			active = bool(zone.call("is_in_magnetic_range", part))
		zone.call("set_preview", active, compatible)


func _release_previous_zone(part: Node3D) -> void:
	var previous_id: StringName = StringName(str(_read_property(part, &"snap_zone_id", "")))
	if previous_id.is_empty():
		return
	for zone: Node in get_tree().get_nodes_in_group(&"vs1_snap_zones"):
		if StringName(str(_read_property(zone, &"zone_id", ""))) == previous_id and zone.has_method("release_object"):
			zone.call("release_object", part, false)
			break


func _set_rotation_target(part: Node3D) -> void:
	var controller: Node = _rotation_controller
	if part != null:
		var local_controller: Node = part.get_node_or_null(^"RotationController")
		if local_controller != null and local_controller.has_method("handle_input"):
			controller = local_controller
	_rotation_controller = controller
	if controller == null:
		return
	if part == null:
		controller.call("clear_target")
	else:
		controller.call("set_target", part)


func _route_rotation_input(event: InputEvent) -> bool:
	return _rotation_controller != null and bool(_rotation_controller.call("handle_input", event))


func _emit_interaction(part: Node3D, kind: StringName) -> void:
	interaction.emit(part, kind)
	if part != null and part.has_method("notify_interaction"):
		part.call("notify_interaction", kind)


func _resolve_camera() -> void:
	if _camera != null and is_instance_valid(_camera):
		return
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		_camera = get_viewport().get_camera_3d()


func _is_pointer_over_gui(position: Vector2) -> bool:
	var control: Control = get_viewport().gui_get_hovered_control()
	return control != null and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(position)


func _read_property(object: Object, property_name: StringName, fallback: Variant) -> Variant:
	if object == null:
		return fallback
	for descriptor: Dictionary in object.get_property_list():
		if StringName(descriptor.get("name", "")) == property_name:
			return object.get(property_name)
	return fallback
