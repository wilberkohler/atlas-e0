extends CanvasLayer
class_name MinimalHUD

signal launch_requested
signal reset_requested

var title_label: Label = null
var context_label: Label = null
var progress_label: Label = null
var piece_panel: PanelContainer = null
var piece_label: Label = null
var ready_label: Label = null
var launch_button: Button = null
var reset_button: Button = null


func _ready() -> void:
	_build()
	set_ready(false)


func set_context(text: String) -> void:
	if context_label != null:
		context_label.text = text


func set_progress(text: String) -> void:
	if progress_label != null:
		progress_label.text = text
		progress_label.visible = not text.is_empty()


func show_piece_description(title: String, description: String) -> void:
	if piece_panel == null or piece_label == null:
		return
	piece_label.text = "%s\n%s" % [title, description]
	piece_panel.visible = true


func clear_piece_description() -> void:
	if piece_panel != null:
		piece_panel.visible = false


func set_ready(ready: bool) -> void:
	if launch_button != null:
		launch_button.visible = ready
	if ready_label != null:
		ready_label.text = "Base pronta" if ready else ""
		ready_label.visible = ready


func _build() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	title_label = Label.new()
	title_label.text = "Monte, teste e descubra."
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(24.0, 20.0)
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.94, 0.96, 0.92))
	root.add_child(title_label)

	progress_label = Label.new()
	progress_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_label.text = ""
	progress_label.position = Vector2(24.0, 54.0)
	progress_label.add_theme_font_size_override("font_size", 15)
	progress_label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0))
	root.add_child(progress_label)

	piece_panel = PanelContainer.new()
	piece_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece_panel.visible = false
	piece_panel.anchor_left = 0.0
	piece_panel.anchor_right = 0.0
	piece_panel.anchor_top = 1.0
	piece_panel.anchor_bottom = 1.0
	piece_panel.offset_left = 24.0
	piece_panel.offset_right = 390.0
	piece_panel.offset_top = -136.0
	piece_panel.offset_bottom = -72.0
	var piece_style: StyleBoxFlat = StyleBoxFlat.new()
	piece_style.bg_color = Color(0.04, 0.06, 0.06, 0.72)
	piece_style.border_color = Color(0.45, 0.62, 0.62, 0.72)
	piece_style.set_border_width_all(1)
	piece_style.set_corner_radius_all(8)
	piece_style.content_margin_left = 12
	piece_style.content_margin_right = 12
	piece_style.content_margin_top = 10
	piece_style.content_margin_bottom = 10
	piece_panel.add_theme_stylebox_override("panel", piece_style)
	root.add_child(piece_panel)

	piece_label = Label.new()
	piece_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	piece_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	piece_label.add_theme_font_size_override("font_size", 14)
	piece_label.add_theme_color_override("font_color", Color(0.92, 0.97, 0.93))
	piece_panel.add_child(piece_label)

	context_label = Label.new()
	context_label.text = "Arraste peças pela bancada. Q/E ou roda giram a peça durante o arraste."
	context_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_label.add_theme_font_size_override("font_size", 16)
	context_label.add_theme_color_override("font_color", Color(0.90, 0.92, 0.88))
	context_label.anchor_left = 0.15
	context_label.anchor_right = 0.85
	context_label.anchor_top = 1.0
	context_label.anchor_bottom = 1.0
	context_label.offset_top = -58.0
	context_label.offset_bottom = -24.0
	root.add_child(context_label)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.anchor_left = 1.0
	actions.anchor_right = 1.0
	actions.offset_left = -254.0
	actions.offset_right = -24.0
	actions.offset_top = 22.0
	actions.offset_bottom = 68.0
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	reset_button = Button.new()
	reset_button.text = "Reiniciar"
	reset_button.mouse_filter = Control.MOUSE_FILTER_STOP
	reset_button.custom_minimum_size = Vector2(96.0, 38.0)
	reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(reset_button)

	launch_button = Button.new()
	launch_button.text = "Testar"
	launch_button.mouse_filter = Control.MOUSE_FILTER_STOP
	launch_button.custom_minimum_size = Vector2(96.0, 38.0)
	launch_button.pressed.connect(_on_launch_pressed)
	actions.add_child(launch_button)

	ready_label = Label.new()
	ready_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ready_label.position = Vector2(24.0, 76.0)
	ready_label.add_theme_font_size_override("font_size", 15)
	ready_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.68))
	root.add_child(ready_label)


func _on_launch_pressed() -> void:
	launch_requested.emit()


func _on_reset_pressed() -> void:
	reset_requested.emit()
