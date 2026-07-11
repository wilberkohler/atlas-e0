extends CanvasLayer
class_name VS1ContextualHintController

signal reset_requested
signal return_requested

const IDLE_HINTS := [
	"Experimente pegar uma peça.",
	"Você pode girar o objeto.",
	"Aproxime a peça da garrafa.",
	"Observe o que mudou.",
]

var _intro: Label
var _context: Label
var _reset_button: Button
var _return_button: Button
var _idle_seconds := 0.0
var _context_seconds := 0.0
var _hint_index := 0
var _has_interacted := false


func _ready() -> void:
	layer = 8
	_build()


func _process(delta: float) -> void:
	_idle_seconds += delta
	if not _has_interacted and _idle_seconds >= 3.6:
		_hide_intro()
	if _context_seconds > 0.0:
		_context_seconds = maxf(0.0, _context_seconds - delta)
		if is_zero_approx(_context_seconds):
			_context.visible = false
	if _idle_seconds >= 6.5 and not _context.visible:
		_context.text = IDLE_HINTS[_hint_index % IDLE_HINTS.size()]
		_context.visible = true
		_context_seconds = 3.2
		_hint_index += 1
		_idle_seconds = 0.0


func mark_interaction() -> void:
	_has_interacted = true
	_idle_seconds = 0.0
	_hide_intro()
	_context.visible = false


func show_context(message: String, duration: float = 2.8) -> void:
	_context.text = message
	_context.visible = not message.is_empty()
	_context_seconds = duration
	_idle_seconds = 0.0


func set_return_visible(visible: bool) -> void:
	_return_button.visible = visible


func set_reset_visible(visible: bool) -> void:
	_reset_button.visible = visible


func _hide_intro() -> void:
	if _intro != null:
		_intro.visible = false


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_intro = Label.new()
	_intro.text = "Monte. Teste. Observe."
	_intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_intro.anchor_left = 0.25
	_intro.anchor_right = 0.75
	_intro.offset_top = 28.0
	_intro.offset_bottom = 70.0
	_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_theme_font_size_override("font_size", 25)
	_intro.add_theme_color_override("font_color", Color(0.98, 0.97, 0.90))
	_intro.add_theme_color_override("font_shadow_color", Color(0.05, 0.06, 0.05, 0.72))
	_intro.add_theme_constant_override("shadow_offset_x", 2)
	_intro.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(_intro)

	_context = Label.new()
	_context.visible = false
	_context.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_context.anchor_left = 0.18
	_context.anchor_right = 0.82
	_context.anchor_top = 1.0
	_context.anchor_bottom = 1.0
	_context.offset_top = -58.0
	_context.offset_bottom = -22.0
	_context.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context.add_theme_font_size_override("font_size", 17)
	_context.add_theme_color_override("font_color", Color(0.97, 0.96, 0.90))
	_context.add_theme_color_override("font_shadow_color", Color(0.04, 0.06, 0.05, 0.82))
	_context.add_theme_constant_override("shadow_offset_x", 2)
	_context.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(_context)

	var actions := HBoxContainer.new()
	actions.anchor_left = 1.0
	actions.anchor_right = 1.0
	actions.offset_left = -228.0
	actions.offset_right = -18.0
	actions.offset_top = 16.0
	actions.offset_bottom = 50.0
	actions.mouse_filter = Control.MOUSE_FILTER_PASS
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)

	_return_button = _small_button("Voltar")
	_return_button.visible = false
	_return_button.pressed.connect(func() -> void: return_requested.emit())
	actions.add_child(_return_button)

	_reset_button = _small_button("Reiniciar")
	_reset_button.pressed.connect(func() -> void: reset_requested.emit())
	actions.add_child(_reset_button)


func _small_button(label: String) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(96.0, 34.0)
	button.modulate = Color(1.0, 1.0, 1.0, 0.78)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button
