extends Node3D
class_name VS1TactileDragController

signal grab_started(part)
signal grab_released(part)
signal rotated(part)
signal interaction(part, kind)
signal snapped_changed(part, is_snapped, zone_id)

@export_category("Identity")
@export var part_id: StringName = &"part"
@export var part_kind: StringName = &"generic"
@export var grabbable: bool = true
@export var rotatable: bool = true
@export var snap_enabled: bool = true

@export_category("Tactile motion")
@export_range(0.0, 1.0, 0.01) var lift_height: float = 0.16
@export_range(0.0, 3.0, 0.01) var ground_clearance: float = 0.20
@export_range(1.0, 40.0, 0.5) var follow_speed: float = 14.0
@export_range(1.0, 40.0, 0.5) var rotation_follow_speed: float = 16.0
@export_range(1.0, 30.0, 0.5) var highlight_follow_speed: float = 12.0
@export_range(1.0, 30.0, 0.5) var rotation_step_degrees: float = 7.5
@export_range(0.0, 75.0, 1.0) var maximum_tilt_degrees: float = 68.0

@export_category("Scene wiring")
@export var visual_root_path: NodePath = ^"Visual"
@export var hitbox_path: NodePath = ^"Hitbox"
@export var shadow_path: NodePath = ^"BlobShadow"
@export var hover_emission: Color = Color(0.30, 0.78, 1.0)

var snapped: bool = false
var snap_zone_id: StringName = &""
var snap_metadata: Dictionary = {}
var target_position: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var reposition_count: int = 0

var _enabled: bool = true
var _grabbed: bool = false
var _hovered: bool = false
var _grab_offset: Vector3 = Vector3.ZERO
var _release_base_y: float = 0.0
var _shadow_world_y: float = 0.0
var _highlight_amount: float = 0.0
var _highlight_target: float = 0.0
var _visual_root: Node3D = null
var _hitbox: Area3D = null
var _shadow: Node3D = null
var _material_states: Array[Dictionary] = []


func _ready() -> void:
	target_position = global_position
	target_rotation = global_rotation
	_release_base_y = global_position.y
	_shadow_world_y = global_position.y - ground_clearance + 0.008
	configure_visual()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	var movement_weight: float = 1.0 - exp(-follow_speed * delta)
	global_position = global_position.lerp(target_position, movement_weight)

	var rotation_weight: float = 1.0 - exp(-rotation_follow_speed * delta)
	var current_quaternion: Quaternion = global_basis.orthonormalized().get_rotation_quaternion()
	var target_quaternion: Quaternion = Basis.from_euler(target_rotation).get_rotation_quaternion()
	var current_scale: Vector3 = global_basis.get_scale()
	global_basis = Basis(current_quaternion.slerp(target_quaternion, rotation_weight)).scaled(current_scale)

	var highlight_weight: float = 1.0 - exp(-highlight_follow_speed * delta)
	_highlight_amount = lerpf(_highlight_amount, _highlight_target, highlight_weight)
	_apply_highlight()
	_update_shadow()


func configure_visual(
		visual: Node3D = null,
		hitbox: Area3D = null,
		shadow: Node3D = null
) -> void:
	_visual_root = visual
	if _visual_root == null and not visual_root_path.is_empty():
		_visual_root = get_node_or_null(visual_root_path) as Node3D

	_hitbox = hitbox
	if _hitbox == null and not hitbox_path.is_empty():
		_hitbox = get_node_or_null(hitbox_path) as Area3D
	if _hitbox != null:
		_hitbox.input_ray_pickable = true
		_hitbox.set_meta(&"vs1_part", self)
		if not _hitbox.mouse_entered.is_connected(_on_hitbox_mouse_entered):
			_hitbox.mouse_entered.connect(_on_hitbox_mouse_entered)
		if not _hitbox.mouse_exited.is_connected(_on_hitbox_mouse_exited):
			_hitbox.mouse_exited.connect(_on_hitbox_mouse_exited)

	_shadow = shadow
	if _shadow == null and not shadow_path.is_empty():
		_shadow = get_node_or_null(shadow_path) as Node3D

	_material_states.clear()
	if _visual_root != null:
		_collect_materials(_visual_root)


func set_enabled(value: bool) -> void:
	_enabled = value
	if _hitbox != null:
		_hitbox.input_ray_pickable = value
	if not value:
		_grabbed = false
		_hovered = false
		_highlight_target = 0.0


func is_enabled() -> bool:
	return _enabled


func is_grabbed() -> bool:
	return _grabbed


func get_part_kind() -> StringName:
	return part_kind


func get_hitbox() -> Area3D:
	return _hitbox


func begin_grab(hit_position: Vector3 = Vector3.INF) -> bool:
	if not _enabled or not grabbable or _grabbed:
		return false
	if snapped:
		detach()
	_release_base_y = global_position.y
	if hit_position.is_finite():
		_grab_offset = Vector3(
			global_position.x - hit_position.x,
			0.0,
			global_position.z - hit_position.z
		)
	else:
		_grab_offset = Vector3.ZERO
	_grabbed = true
	_hovered = false
	target_position = global_position + Vector3.UP * lift_height
	_highlight_target = 0.72
	grab_started.emit(self)
	interaction.emit(self, &"grab_started")
	return true


func drag_to(world_position: Vector3) -> void:
	if not _enabled or not _grabbed or not world_position.is_finite():
		return
	var desired: Vector3 = world_position + _grab_offset
	desired.y = maxf(world_position.y + ground_clearance, _release_base_y) + lift_height
	target_position = desired
	interaction.emit(self, &"dragged")


func end_grab(release_position: Vector3 = Vector3.INF) -> void:
	if not _grabbed:
		return
	_grabbed = false
	if release_position.is_finite():
		target_position.x = release_position.x + _grab_offset.x
		target_position.z = release_position.z + _grab_offset.z
		target_position.y = release_position.y + ground_clearance
		_release_base_y = target_position.y
		_shadow_world_y = release_position.y + 0.008
	else:
		target_position.y = _release_base_y
	_highlight_target = 0.34 if _hovered else 0.0
	grab_released.emit(self)
	interaction.emit(self, &"grab_released")


func rotate_step(direction: float) -> void:
	if not _enabled or not rotatable:
		return
	target_rotation.y = wrapf(
		target_rotation.y + deg_to_rad(rotation_step_degrees) * direction,
		-PI,
		PI
	)
	rotated.emit(self)
	interaction.emit(self, &"rotated")


func nudge_rotation(delta_euler: Vector3) -> void:
	if not _enabled or not rotatable:
		return
	target_rotation += delta_euler
	var maximum_tilt: float = deg_to_rad(maximum_tilt_degrees)
	target_rotation.x = clampf(target_rotation.x, -maximum_tilt, maximum_tilt)
	target_rotation.z = clampf(target_rotation.z, -maximum_tilt, maximum_tilt)
	target_rotation.y = wrapf(target_rotation.y, -PI, PI)
	rotated.emit(self)
	interaction.emit(self, &"rotated")


func set_target_rotation(rotation_radians: Vector3) -> void:
	if not _enabled or not rotatable:
		return
	target_rotation = rotation_radians
	rotated.emit(self)
	interaction.emit(self, &"rotated")


func set_hovered(value: bool) -> void:
	if not _enabled:
		value = false
	if _hovered == value:
		return
	_hovered = value
	if not _grabbed:
		_highlight_target = 0.34 if value else (0.12 if snapped else 0.0)
	interaction.emit(self, &"hover_enter" if value else &"hover_exit")


func snap_to(snap_transform: Transform3D, metadata: Dictionary = {}) -> void:
	if not snap_enabled:
		return
	_grabbed = false
	snapped = true
	snap_metadata = metadata.duplicate(true)
	snap_zone_id = StringName(str(metadata.get("zone_id", "")))
	target_position = snap_transform.origin
	target_rotation = snap_transform.basis.orthonormalized().get_euler()
	_release_base_y = target_position.y
	_highlight_target = 0.14
	snapped_changed.emit(self, true, snap_zone_id)
	grab_released.emit(self)
	interaction.emit(self, &"snapped")


func detach() -> void:
	if not snapped:
		return
	snapped = false
	snap_zone_id = &""
	snap_metadata.clear()
	reposition_count += 1
	_highlight_target = 0.34 if _hovered else 0.0
	snapped_changed.emit(self, false, snap_zone_id)
	interaction.emit(self, &"detached")


func notify_interaction(kind: StringName) -> void:
	interaction.emit(self, kind)


func get_target_transform() -> Transform3D:
	return Transform3D(Basis.from_euler(target_rotation), target_position)


func _on_hitbox_mouse_entered() -> void:
	set_hovered(true)
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_hitbox_mouse_exited() -> void:
	set_hovered(false)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _collect_materials(node: Node) -> void:
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface_index: int in range(mesh_instance.mesh.get_surface_count()):
			var source: Material = mesh_instance.get_active_material(surface_index)
			var standard: StandardMaterial3D = source as StandardMaterial3D
			if standard == null:
				continue
			var unique: StandardMaterial3D = standard.duplicate(true) as StandardMaterial3D
			mesh_instance.set_surface_override_material(surface_index, unique)
			_material_states.append({
				"material": unique,
				"emission_enabled": unique.emission_enabled,
				"emission": unique.emission,
				"energy": unique.emission_energy_multiplier,
			})
	for child: Node in node.get_children():
		_collect_materials(child)


func _apply_highlight() -> void:
	for state: Dictionary in _material_states:
		var material: StandardMaterial3D = state.get("material") as StandardMaterial3D
		if material == null:
			continue
		var base_color: Color = state.get("emission", Color.BLACK)
		var base_enabled: bool = bool(state.get("emission_enabled", false))
		var base_energy: float = float(state.get("energy", 1.0))
		material.emission_enabled = base_enabled or _highlight_amount > 0.002
		material.emission = base_color.lerp(hover_emission, _highlight_amount)
		material.emission_energy_multiplier = maxf(base_energy, 0.65 + _highlight_amount * 0.75)


func _update_shadow() -> void:
	if _shadow == null:
		return
	_shadow.global_position = Vector3(global_position.x, _shadow_world_y, global_position.z)
	_shadow.global_rotation = Vector3(-PI * 0.5, 0.0, 0.0)

