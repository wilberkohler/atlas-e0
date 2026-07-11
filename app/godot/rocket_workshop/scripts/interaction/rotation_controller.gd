extends Node
class_name VS1RotationController

signal rotated(part)
signal rotation_finished(part, final_rotation)

@export var target_path: NodePath = ^".."
@export var listen_for_input: bool = false
@export_range(0.0005, 0.02, 0.0005) var secondary_drag_sensitivity: float = 0.005

var target: Node3D = null
var _secondary_dragging: bool = false


func _ready() -> void:
	if not target_path.is_empty():
		target = get_node_or_null(target_path) as Node3D
	set_process_unhandled_input(listen_for_input)


func set_target(part: Node3D) -> void:
	target = part
	_secondary_dragging = false


func clear_target() -> void:
	if target != null and _secondary_dragging:
		rotation_finished.emit(target, target.get("target_rotation"))
	target = null
	_secondary_dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if handle_input(event):
		get_viewport().set_input_as_handled()


func handle_input(event: InputEvent) -> bool:
	if not _can_rotate_target():
		_secondary_dragging = false
		return false

	var key_event: InputEventKey = event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo:
		if key_event.keycode == KEY_Q:
			_rotate_step(-1.0)
			return true
		if key_event.keycode == KEY_E:
			_rotate_step(1.0)
			return true

	var button_event: InputEventMouseButton = event as InputEventMouseButton
	if button_event != null:
		if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
			_rotate_step(1.0)
			return true
		if button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
			_rotate_step(-1.0)
			return true
		if button_event.button_index == MOUSE_BUTTON_RIGHT:
			_secondary_dragging = button_event.pressed
			if not button_event.pressed:
				rotation_finished.emit(target, target.get("target_rotation"))
			return true

	var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if motion_event != null and _secondary_dragging:
		var delta_euler := Vector3(
			-motion_event.relative.y * secondary_drag_sensitivity,
			-motion_event.relative.x * secondary_drag_sensitivity,
			0.0
		)
		target.call("nudge_rotation", delta_euler)
		rotated.emit(target)
		return true
	return false


func _can_rotate_target() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not target.has_method("rotate_step") or not target.has_method("is_grabbed"):
		return false
	return bool(target.call("is_grabbed"))


func _rotate_step(direction: float) -> void:
	target.call("rotate_step", direction)
	rotated.emit(target)

