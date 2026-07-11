extends CanvasLayer
class_name VS1DeveloperOverlay

signal preset_requested(preset_id: String)
signal deterministic_changed(enabled: bool)

var _panel: PanelContainer
var _content: RichTextLabel
var _deterministic: CheckButton
var _snapshot: Dictionary = {}


func _ready() -> void:
	layer = 100
	_build()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F2:
		visible = not visible
		get_viewport().set_input_as_handled()


func set_snapshot(snapshot: Dictionary) -> void:
	_snapshot = snapshot.duplicate(true)
	if visible and _content != null:
		_render()


func _process(_delta: float) -> void:
	if visible and _content != null:
		_render()


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -430.0
	_panel.offset_right = -12.0
	_panel.offset_top = 12.0
	_panel.offset_bottom = -12.0
	add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "VERTICAL SLICE — DESENVOLVIMENTO (F2)"
	title.add_theme_font_size_override("font_size", 16)
	box.add_child(title)

	var presets := HBoxContainer.new()
	presets.add_theme_constant_override("separation", 4)
	box.add_child(presets)
	for item: Dictionary in [
		{"id": "stable", "label": "Stable"},
		{"id": "spin", "label": "Spin"},
		{"id": "lateral", "label": "Lateral"},
		{"id": "short", "label": "Short"},
	]:
		var button := Button.new()
		button.text = item.label
		button.pressed.connect(_emit_preset.bind(item.id))
		presets.add_child(button)

	_deterministic = CheckButton.new()
	_deterministic.text = "Semente fixa entre tentativas"
	_deterministic.button_pressed = true
	_deterministic.toggled.connect(func(enabled: bool) -> void: deterministic_changed.emit(enabled))
	box.add_child(_deterministic)

	_content = RichTextLabel.new()
	_content.fit_content = false
	_content.scroll_active = true
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.add_theme_font_size_override("normal_font_size", 12)
	box.add_child(_content)


func _emit_preset(preset_id: String) -> void:
	preset_requested.emit(preset_id)


func _render() -> void:
	var lines: Array[String] = []
	lines.append("Estado: %s" % String(_snapshot.get("phase", "—")))
	lines.append("Voo: %s" % String(_snapshot.get("flight_state", "—")))
	lines.append("Seed: %s" % str(_snapshot.get("wind_seed", "—")))
	lines.append("Tentativas: %d" % int(_snapshot.get("attempt_count", 0)))
	lines.append("")
	lines.append("CONFIGURAÇÃO")
	lines.append(JSON.stringify(_snapshot.get("configuration", {}), "  "))
	lines.append("")
	lines.append("MÉTRICAS INTERNAS")
	lines.append(JSON.stringify(_snapshot.get("metrics", {}), "  "))
	lines.append("")
	lines.append("FORÇAS / TORQUE")
	lines.append(JSON.stringify(_snapshot.get("forces", {}), "  "))
	lines.append("")
	lines.append("HISTÓRICO (máx. 2 visual)")
	lines.append(JSON.stringify(_snapshot.get("history", []), "  "))
	_content.text = "\n".join(lines)
