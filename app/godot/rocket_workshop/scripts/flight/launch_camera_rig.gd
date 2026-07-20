extends Node
class_name LaunchCameraRig

var camera: Camera3D = null
var target: Node3D = null
var mode: StringName = &"bench"
var bench_position: Vector3 = Vector3.ZERO
var bench_size: float = 7.4
var follow_offset: Vector3 = Vector3(4.6, 4.8, 5.2)
var result_offset: Vector3 = Vector3(4.0, 3.2, 4.4)
var smoothing: float = 5.0
var shake_time: float = 0.0
var shake_strength: float = 0.0


func configure(new_camera: Camera3D) -> void:
	camera = new_camera
	if camera != null:
		bench_position = camera.position
		bench_size = camera.size
	set_process(true)


func show_bench() -> void:
	mode = &"bench"
	target = null


func follow_launch(new_target: Node3D) -> void:
	mode = &"follow"
	target = new_target
	shake(0.22, 0.045)


func show_result(new_target: Node3D) -> void:
	mode = &"result"
	target = new_target


func shake(duration: float, strength: float) -> void:
	shake_time = maxf(shake_time, duration)
	shake_strength = maxf(shake_strength, strength)


func _process(delta: float) -> void:
	if camera == null:
		return
	var desired_position: Vector3 = bench_position
	var desired_size: float = bench_size
	var look_target: Vector3 = Vector3(0.0, 0.3, 0.0)

	if mode == &"follow" and target != null:
		var height: float = maxf(0.0, target.global_position.y - 0.52)
		desired_position = target.global_position + follow_offset + Vector3(0.0, height * 0.28, 0.0)
		desired_size = clampf(6.0 + height * 0.75, 6.2, 12.0)
		look_target = target.global_position
	elif mode == &"result" and target != null:
		desired_position = target.global_position + result_offset
		desired_size = 7.2
		look_target = target.global_position

	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		var amount: float = shake_strength * (shake_time / maxf(0.001, shake_time + delta))
		desired_position += Vector3(
			sin(Time.get_ticks_msec() * 0.041) * amount,
			cos(Time.get_ticks_msec() * 0.037) * amount,
			sin(Time.get_ticks_msec() * 0.029) * amount
		)

	var alpha: float = 1.0 - exp(-smoothing * delta)
	camera.position = camera.position.lerp(desired_position, alpha)
	camera.size = lerpf(camera.size, desired_size, alpha)
	camera.look_at(look_target, Vector3.UP)
