extends CanvasLayer
class_name VS1TransitionController

signal midpoint
signal transition_finished

var _veil: ColorRect
var _running := false


func _ready() -> void:
	layer = 40
	_veil = ColorRect.new()
	_veil.color = Color(0.08, 0.11, 0.10, 0.0)
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_veil)
	visible = false


func play(duration: float = 0.72) -> void:
	if _running:
		return
	_running = true
	visible = true
	_veil.color.a = 0.0
	var half := maxf(0.12, duration * 0.5)
	var tween := create_tween()
	tween.tween_property(_veil, "color:a", 1.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: midpoint.emit())
	tween.tween_property(_veil, "color:a", 0.0, half).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish)


func _finish() -> void:
	visible = false
	_running = false
	transition_finished.emit()
