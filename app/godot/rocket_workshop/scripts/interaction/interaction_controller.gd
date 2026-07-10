extends Node
class_name InteractionController

signal hover_description_requested(part)
signal hover_description_cleared
signal snap_missed(part)

@export var table_y: float = 0.20
@export var rotate_step_degrees: float = 8.0
@export var zoom_min: float = 5.8
@export var zoom_max: float = 10.2
@export var hover_description_delay: float = 0.45

var camera: Camera3D = null
var assembly: Node = null
var telemetry: Node = null
var launch_controller: Node = null

var selected_part: Node = null
var hovered_part: Node = null
var dragging: bool = false
var last_table_position: Vector3 = Vector3.ZERO
var _hover_started_at: float = 0.0
var _hover_description_visible: bool = false


func configure(new_camera: Camera3D, new_assembly: Node, new_telemetry: Node, new_launch_controller: Node) -> void:
	camera = new_camera
	assembly = new_assembly
	telemetry = new_telemetry
	launch_controller = new_launch_controller
	set_process(true)
	set_process_input(true)
	set_process_unhandled_input(true)


func _process(_delta: float) -> void:
	if dragging or hovered_part == null or _hover_description_visible:
		return
	if Time.get_unix_time_from_system() - _hover_started_at >= hover_description_delay:
		_hover_description_visible = true
		hover_description_requested.emit(hovered_part)


func _input(event: InputEvent) -> void:
	_handle_input_event(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_input_event(event)


func _handle_input_event(event: InputEvent) -> void:
	if camera == null or assembly == null:
		return
	if launch_controller != null and launch_controller.launching:
		return
	if _is_gui_event(event):
		return

	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion != null:
		last_table_position = _mouse_to_table(mouse_motion.position)
		if dragging and selected_part != null:
			selected_part.update_drag_position(last_table_position)
			assembly.update_snap_previews(selected_part)
		else:
			_update_hover(mouse_motion.position)
		return

	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button != null:
		_handle_mouse_button(mouse_button)
		return

	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		_handle_key(key_event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_pointer_drag(event.position)
		else:
			_end_pointer_drag(event.position)
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		if selected_part != null:
			_rotate_selected(1.0)
		else:
			_zoom(-0.35)
		return

	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		if selected_part != null:
			_rotate_selected(-1.0)
		else:
			_zoom(0.35)


func _handle_key(event: InputEventKey) -> void:
	if event.keycode == KEY_Q:
		_rotate_selected(-1.0)
	elif event.keycode == KEY_E:
		_rotate_selected(1.0)


func _begin_pointer_drag(mouse_position: Vector2) -> void:
	var part: Node = _pick_part(mouse_position)
	if part == null:
		if _pick_launch_stand(mouse_position) and assembly.is_ready_for_launch():
			launch_controller.request_launch()
			get_viewport().set_input_as_handled()
		return
	if not part.can_drag:
		return
	_clear_hover_description()
	selected_part = part
	dragging = true
	last_table_position = _mouse_to_table(mouse_position)
	if part.is_snapped:
		assembly.remove_part(part)
	part.begin_drag()
	if telemetry != null:
		telemetry.record_part_touch(part.part_id, part.part_type)
	get_viewport().set_input_as_handled()


func _end_pointer_drag(mouse_position: Vector2) -> void:
	if not dragging or selected_part == null:
		return
	last_table_position = _mouse_to_table(mouse_position)
	var zone: Node = assembly.find_best_snap_zone(selected_part)
	var duration: float = 0.0
	if zone != null:
		duration = selected_part.end_drag(last_table_position)
		assembly.snap_part(selected_part, zone)
	else:
		duration = selected_part.end_drag(last_table_position)
		assembly.update_snap_previews(null)
		snap_missed.emit(selected_part)
		if telemetry != null:
			telemetry.record_snap_attempt(selected_part.part_id, "", false, 0.0)

	if telemetry != null:
		telemetry.record_drag(selected_part.part_id, duration, selected_part.global_position)

	dragging = false
	selected_part = null
	get_viewport().set_input_as_handled()


func _rotate_selected(direction: float) -> void:
	if selected_part == null:
		return
	var radians: float = deg_to_rad(rotate_step_degrees) * direction
	selected_part.rotate_by(radians)
	if telemetry != null:
		telemetry.record_rotation(selected_part.part_id, selected_part.rotation_degrees)
	if dragging:
		assembly.update_snap_previews(selected_part)
	get_viewport().set_input_as_handled()


func _update_hover(mouse_position: Vector2) -> void:
	var part: Node = _pick_part(mouse_position)
	if part == hovered_part:
		return
	if hovered_part != null:
		hovered_part.set_hovered(false)
	_clear_hover_description()
	hovered_part = part
	if hovered_part != null:
		hovered_part.set_hovered(true)
		_hover_started_at = Time.get_unix_time_from_system()
		_hover_description_visible = false
	else:
		_clear_hover_description()


func _pick_part(mouse_position: Vector2) -> Node:
	var from: Vector3 = camera.project_ray_origin(mouse_position)
	var direction: Vector3 = camera.project_ray_normal(mouse_position)
	var to: Vector3 = from + direction * 100.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 1
	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Object = result.get("collider") as Object
	if collider == null:
		return null
	if not collider.has_meta("part"):
		return null
	var part_object: Object = collider.get_meta("part") as Object
	return part_object as Node


func _pick_launch_stand(mouse_position: Vector2) -> bool:
	var from: Vector3 = camera.project_ray_origin(mouse_position)
	var direction: Vector3 = camera.project_ray_normal(mouse_position)
	var to: Vector3 = from + direction * 100.0
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 2
	var result: Dictionary = camera.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return false
	var collider: Object = result.get("collider") as Object
	return collider != null and collider.has_meta("launch_stand")


func _mouse_to_table(mouse_position: Vector2) -> Vector3:
	var from: Vector3 = camera.project_ray_origin(mouse_position)
	var direction: Vector3 = camera.project_ray_normal(mouse_position)
	if absf(direction.y) < 0.001:
		return last_table_position
	var distance: float = (table_y - from.y) / direction.y
	return from + direction * distance


func _zoom(delta: float) -> void:
	camera.size = clampf(camera.size + delta, zoom_min, zoom_max)
	get_viewport().set_input_as_handled()


func _is_gui_event(event: InputEvent) -> bool:
	var mouse_button: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button != null:
		return _is_position_over_gui(mouse_button.position)
	var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion != null:
		return _is_position_over_gui(mouse_motion.position)
	return false


func _is_position_over_gui(position: Vector2) -> bool:
	var hovered: Control = get_viewport().gui_get_hovered_control()
	if hovered == null:
		return false
	if hovered.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	return hovered.get_global_rect().has_point(position)


func _clear_hover_description() -> void:
	if _hover_description_visible:
		hover_description_cleared.emit()
	_hover_description_visible = false
