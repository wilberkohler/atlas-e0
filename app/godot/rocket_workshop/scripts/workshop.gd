extends Control

const PANEL_BG := Color(0.96, 0.97, 0.94)
const PANEL_STROKE := Color(0.58, 0.64, 0.61)
const TEXT_DARK := Color(0.11, 0.14, 0.16)
const TEXT_MUTED := Color(0.32, 0.38, 0.38)
const ACCENT := Color(0.09, 0.47, 0.58)
const ACCENT_DARK := Color(0.04, 0.28, 0.34)
const WARNING := Color(0.82, 0.32, 0.18)
const SUCCESS := Color(0.18, 0.53, 0.33)

const PARTS := [
	{
		"id": "nose",
		"name": "Bico",
		"symbol": "A",
		"hint": "O bico corta o ar e protege os instrumentos."
	},
	{
		"id": "tank",
		"name": "Tanque",
		"symbol": "T",
		"hint": "O tanque define por quanto tempo o motor respira."
	},
	{
		"id": "engine",
		"name": "Motor",
		"symbol": "M",
		"hint": "O motor transforma pressão em empuxo."
	},
	{
		"id": "fins",
		"name": "Aletas",
		"symbol": "F",
		"hint": "As aletas reduzem a oscilação durante a subida."
	},
	{
		"id": "sensor",
		"name": "Sensor",
		"symbol": "S",
		"hint": "O sensor registra altitude, estabilidade e tentativas."
	},
]

var rocket_canvas: RocketCanvas
var fuel_slider: HSlider
var fins_slider: HSlider
var nozzle_slider: HSlider
var status_label: Label
var observation_label: Label
var timeline_label: Label
var explored_label: Label
var score_label: Label
var launch_button: Button
var part_buttons := {}
var part_touch_counts := {}
var explored_parts := {}
var events: Array = []
var session_started_at := 0.0
var last_event_at := 0.0
var launch_attempts := 0
var best_score := 0.0


class RocketCanvas:
	extends Control

	var fuel_ratio := 0.55
	var fins_ratio := 0.52
	var nozzle_ratio := 0.58
	var launch_active := false
	var launch_progress := 0.0
	var launch_score := 0.0
	var shake_seed := 0.0
	var explored_count := 0
	var last_message := "A bancada está pronta."

	func _ready() -> void:
		set_process(true)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configure(new_fuel: float, new_fins: float, new_nozzle: float, new_explored_count: int) -> void:
		fuel_ratio = new_fuel
		fins_ratio = new_fins
		nozzle_ratio = new_nozzle
		explored_count = new_explored_count
		queue_redraw()

	func start_launch(score: float) -> void:
		launch_active = true
		launch_progress = 0.0
		launch_score = score
		shake_seed = randf() * 100.0
		if score >= 0.72:
			last_message = "Trajetória estável."
		elif score >= 0.48:
			last_message = "Subida curta, mas controlada."
		else:
			last_message = "Teste interrompido cedo."
		queue_redraw()

	func reset_launch() -> void:
		launch_active = false
		launch_progress = 0.0
		last_message = "A bancada está pronta."
		queue_redraw()

	func _process(delta: float) -> void:
		if launch_active:
			var speed: float = lerpf(0.22, 0.74, launch_score)
			launch_progress = minf(1.0, launch_progress + delta * speed)
			if launch_progress >= 1.0:
				launch_active = false
		queue_redraw()

	func _draw() -> void:
		_draw_background()
		_draw_workbench()
		_draw_progress_lights()
		_draw_rocket()
		_draw_readout()

	func _draw_background() -> void:
		var bands := 18
		for i in range(bands):
			var t := float(i) / float(max(1, bands - 1))
			var color := Color(0.08, 0.15, 0.20).lerp(Color(0.22, 0.36, 0.42), t)
			draw_rect(Rect2(0, size.y * t, size.x, size.y / bands + 1.0), color)

		var star_positions := [
			Vector2(0.12, 0.12), Vector2(0.32, 0.20), Vector2(0.74, 0.10),
			Vector2(0.88, 0.22), Vector2(0.62, 0.30), Vector2(0.18, 0.34)
		]
		for pos in star_positions:
			var center := Vector2(size.x * pos.x, size.y * pos.y)
			draw_circle(center, 2.0, Color(0.91, 0.94, 0.83, 0.78))

	func _draw_workbench() -> void:
		var floor_y := size.y * 0.78
		draw_rect(Rect2(0, floor_y, size.x, size.y - floor_y), Color(0.16, 0.21, 0.21))
		draw_rect(Rect2(size.x * 0.08, floor_y + 28.0, size.x * 0.84, 20.0), Color(0.44, 0.34, 0.25))
		draw_rect(Rect2(size.x * 0.15, floor_y + 48.0, 22.0, 90.0), Color(0.30, 0.24, 0.19))
		draw_rect(Rect2(size.x * 0.78, floor_y + 48.0, 22.0, 90.0), Color(0.30, 0.24, 0.19))
		draw_line(Vector2(size.x * 0.42, floor_y + 20.0), Vector2(size.x * 0.42, size.y * 0.16), Color(0.62, 0.70, 0.68), 4.0)
		draw_line(Vector2(size.x * 0.57, floor_y + 20.0), Vector2(size.x * 0.57, size.y * 0.16), Color(0.62, 0.70, 0.68), 4.0)
		draw_line(Vector2(size.x * 0.42, size.y * 0.16), Vector2(size.x * 0.57, size.y * 0.16), Color(0.62, 0.70, 0.68), 4.0)

	func _draw_progress_lights() -> void:
		var start := Vector2(size.x * 0.12, size.y * 0.12)
		for i in range(5):
			var lit := i < explored_count
			var color := Color(0.23, 0.72, 0.50) if lit else Color(0.33, 0.42, 0.42)
			draw_circle(start + Vector2(i * 28.0, 0.0), 9.0, color)

	func _draw_rocket() -> void:
		var floor_y := size.y * 0.78
		var ascent: float = launch_progress * size.y * lerpf(0.35, 0.96, launch_score)
		var instability: float = clampf(1.0 - fins_ratio, 0.0, 1.0)
		var wobble: float = sin(Time.get_ticks_msec() * 0.009 + shake_seed) * instability * launch_progress * 34.0
		var center := Vector2(size.x * 0.495 + wobble, floor_y - 40.0 - ascent)
		var body_h := 116.0
		var body_w := 42.0
		var nose_h := 42.0
		var body_color := Color(0.91, 0.94, 0.92)
		var accent_color := Color(0.10, 0.53, 0.63).lerp(Color(0.89, 0.30, 0.22), 1.0 - nozzle_ratio)

		var body := Rect2(center.x - body_w * 0.5, center.y - body_h * 0.5, body_w, body_h)
		draw_polygon(
			PackedVector2Array([
				Vector2(center.x, body.position.y - nose_h),
				Vector2(body.position.x, body.position.y + 6.0),
				Vector2(body.position.x + body_w, body.position.y + 6.0)
			]),
			PackedColorArray([Color(0.95, 0.95, 0.90)])
		)
		draw_rect(body, body_color)
		draw_rect(Rect2(body.position.x, body.position.y + body_h * 0.48, body_w, 10.0), accent_color)
		draw_circle(Vector2(center.x, body.position.y + 35.0), 11.0, Color(0.28, 0.72, 0.88))
		draw_circle(Vector2(center.x - 4.0, body.position.y + 31.0), 3.0, Color(0.83, 0.96, 1.00, 0.85))

		var fin_height: float = lerpf(22.0, 44.0, fins_ratio)
		draw_polygon(
			PackedVector2Array([
				Vector2(body.position.x, body.end.y - 12.0),
				Vector2(body.position.x - 28.0, body.end.y + fin_height),
				Vector2(body.position.x + 8.0, body.end.y)
			]),
			PackedColorArray([Color(0.83, 0.25, 0.20)])
		)
		draw_polygon(
			PackedVector2Array([
				Vector2(body.end.x, body.end.y - 12.0),
				Vector2(body.end.x + 28.0, body.end.y + fin_height),
				Vector2(body.end.x - 8.0, body.end.y)
			]),
			PackedColorArray([Color(0.83, 0.25, 0.20)])
		)

		var nozzle_w: float = lerpf(18.0, 36.0, nozzle_ratio)
		draw_polygon(
			PackedVector2Array([
				Vector2(center.x - nozzle_w * 0.5, body.end.y),
				Vector2(center.x + nozzle_w * 0.5, body.end.y),
				Vector2(center.x + 12.0, body.end.y + 22.0),
				Vector2(center.x - 12.0, body.end.y + 22.0)
			]),
			PackedColorArray([Color(0.20, 0.22, 0.23)])
		)

		if launch_active or launch_progress > 0.0:
			var flame_h: float = lerpf(34.0, 96.0, fuel_ratio) * (0.45 + launch_score)
			draw_polygon(
				PackedVector2Array([
					Vector2(center.x - 18.0, body.end.y + 16.0),
					Vector2(center.x + 18.0, body.end.y + 16.0),
					Vector2(center.x, body.end.y + flame_h)
				]),
				PackedColorArray([Color(0.94, 0.37, 0.12, 0.90)])
			)
			draw_polygon(
				PackedVector2Array([
					Vector2(center.x - 9.0, body.end.y + 16.0),
					Vector2(center.x + 9.0, body.end.y + 16.0),
					Vector2(center.x, body.end.y + flame_h * 0.74)
				]),
				PackedColorArray([Color(1.00, 0.86, 0.32, 0.95)])
			)

	func _draw_readout() -> void:
		var meter_rect := Rect2(size.x * 0.66, size.y * 0.12, size.x * 0.24, 104.0)
		draw_rect(meter_rect, Color(0.06, 0.10, 0.11, 0.72))
		draw_rect(Rect2(meter_rect.position + Vector2(16.0, 24.0), Vector2((meter_rect.size.x - 32.0) * fuel_ratio, 10.0)), Color(0.91, 0.54, 0.18))
		draw_rect(Rect2(meter_rect.position + Vector2(16.0, 52.0), Vector2((meter_rect.size.x - 32.0) * fins_ratio, 10.0)), Color(0.22, 0.64, 0.48))
		draw_rect(Rect2(meter_rect.position + Vector2(16.0, 80.0), Vector2((meter_rect.size.x - 32.0) * nozzle_ratio, 10.0)), Color(0.29, 0.65, 0.78))


func _ready() -> void:
	randomize()
	session_started_at = Time.get_unix_time_from_system()
	last_event_at = session_started_at
	_setup_theme()
	_build_ui()
	_record_event("session", "start", "Bancada iniciada.")
	_refresh_all()


func _setup_theme() -> void:
	var base_theme := Theme.new()
	base_theme.default_font_size = 16
	theme = base_theme


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var controls := _make_panel()
	controls.custom_minimum_size = Vector2(360, 0)
	controls.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(controls)

	var controls_box := VBoxContainer.new()
	controls_box.add_theme_constant_override("separation", 12)
	controls.add_child(controls_box)

	_add_header(controls_box)
	_add_part_buttons(controls_box)
	_add_sliders(controls_box)
	_add_actions(controls_box)

	rocket_canvas = RocketCanvas.new()
	rocket_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rocket_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(rocket_canvas)

	var report := _make_panel()
	report.custom_minimum_size = Vector2(330, 0)
	report.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(report)

	var report_box := VBoxContainer.new()
	report_box.add_theme_constant_override("separation", 12)
	report.add_child(report_box)
	_add_report(report_box)


func _add_header(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Oficina do Foguete"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", TEXT_DARK)
	parent.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Explore peças, ajuste a montagem e observe como o foguete responde."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(subtitle)

	status_label = Label.new()
	status_label.text = "Toque nas peças para acender a bancada."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", ACCENT_DARK)
	parent.add_child(status_label)


func _add_part_buttons(parent: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Peças da bancada"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", TEXT_DARK)
	parent.add_child(label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)

	for part in PARTS:
		var button := Button.new()
		button.text = "%s  %s" % [part.symbol, part.name]
		button.custom_minimum_size = Vector2(150, 54)
		button.focus_mode = Control.FOCUS_NONE
		button.tooltip_text = part.hint
		button.pressed.connect(_on_part_pressed.bind(part.id))
		part_buttons[part.id] = button
		part_touch_counts[part.id] = 0
		grid.add_child(button)


func _add_sliders(parent: VBoxContainer) -> void:
	var label := Label.new()
	label.text = "Ajustes de teste"
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", TEXT_DARK)
	parent.add_child(label)

	fuel_slider = _make_slider(parent, "Combustível", 20.0, 100.0, 62.0)
	fins_slider = _make_slider(parent, "Aletas", 20.0, 100.0, 58.0)
	nozzle_slider = _make_slider(parent, "Bocal", 20.0, 100.0, 64.0)


func _add_actions(parent: VBoxContainer) -> void:
	launch_button = Button.new()
	launch_button.text = "Lançar teste"
	launch_button.custom_minimum_size = Vector2(0, 48)
	launch_button.pressed.connect(_on_launch_pressed)
	launch_button.add_theme_stylebox_override("normal", _style(ACCENT, ACCENT_DARK, 8))
	launch_button.add_theme_stylebox_override("hover", _style(Color(0.12, 0.57, 0.68), ACCENT_DARK, 8))
	launch_button.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(launch_button)

	var reset_button := Button.new()
	reset_button.text = "Reiniciar bancada"
	reset_button.custom_minimum_size = Vector2(0, 42)
	reset_button.pressed.connect(_on_reset_pressed)
	parent.add_child(reset_button)

	var copy_button := Button.new()
	copy_button.text = "Copiar JSON da sessão"
	copy_button.custom_minimum_size = Vector2(0, 42)
	copy_button.pressed.connect(_on_copy_json_pressed)
	parent.add_child(copy_button)


func _add_report(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "Observação"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", TEXT_DARK)
	parent.add_child(title)

	explored_label = Label.new()
	explored_label.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(explored_label)

	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	score_label.add_theme_color_override("font_color", ACCENT_DARK)
	parent.add_child(score_label)

	observation_label = Label.new()
	observation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	observation_label.add_theme_color_override("font_color", TEXT_DARK)
	parent.add_child(observation_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	parent.add_child(spacer)

	var timeline_title := Label.new()
	timeline_title.text = "Linha do tempo"
	timeline_title.add_theme_font_size_override("font_size", 18)
	timeline_title.add_theme_color_override("font_color", TEXT_DARK)
	parent.add_child(timeline_title)

	timeline_label = Label.new()
	timeline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	timeline_label.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(timeline_label)


func _make_slider(parent: VBoxContainer, label_text: String, minimum: float, maximum: float, value: float) -> HSlider:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", TEXT_MUTED)
	parent.add_child(label)

	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = 1.0
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(_on_tuning_changed)
	parent.add_child(slider)
	return slider


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(PANEL_BG, PANEL_STROKE, 8))
	return panel


func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _on_part_pressed(part_id: String) -> void:
	part_touch_counts[part_id] += 1
	explored_parts[part_id] = true
	var part_name := _part_name(part_id)
	var hint := _part_hint(part_id)
	status_label.text = hint
	_record_event("part", part_name, "Explorou %s pela %dª vez." % [part_name, part_touch_counts[part_id]])
	_refresh_all()


func _on_tuning_changed(_value: float) -> void:
	_record_event("tuning", "ajuste", "Combustível %.0f, aletas %.0f, bocal %.0f." % [fuel_slider.value, fins_slider.value, nozzle_slider.value])
	_refresh_all()


func _on_launch_pressed() -> void:
	launch_attempts += 1
	var score := _calculate_launch_score()
	best_score = max(best_score, score)
	rocket_canvas.start_launch(score)
	if explored_parts.size() < 3:
		status_label.text = "Lançamento cedo: a bancada ainda tinha peças sem inspeção."
	elif score >= 0.72:
		status_label.text = "O foguete subiu com estabilidade. A oficina registrou um bom equilíbrio."
	elif score >= 0.48:
		status_label.text = "O foguete saiu do trilho, mas perdeu energia no caminho."
	else:
		status_label.text = "O teste falhou cedo. Ajuste combustível, aletas e bocal."
	_record_event("launch", "teste %d" % launch_attempts, "Pontuação %.2f." % score)
	_refresh_all()


func _on_reset_pressed() -> void:
	events.clear()
	explored_parts.clear()
	for id in part_touch_counts.keys():
		part_touch_counts[id] = 0
	launch_attempts = 0
	best_score = 0.0
	session_started_at = Time.get_unix_time_from_system()
	last_event_at = session_started_at
	rocket_canvas.reset_launch()
	status_label.text = "Bancada reiniciada. Explore as peças antes do próximo teste."
	_record_event("session", "restart", "Sessão reiniciada.")
	_refresh_all()


func _on_copy_json_pressed() -> void:
	var json := JSON.stringify(_session_snapshot(), "\t")
	DisplayServer.clipboard_set(json)
	status_label.text = "JSON da sessão copiado para a área de transferência."
	_record_event("export", "clipboard", "JSON copiado.")
	_refresh_all()


func _refresh_all() -> void:
	_refresh_part_buttons()
	if rocket_canvas != null:
		rocket_canvas.configure(_ratio(fuel_slider), _ratio(fins_slider), _ratio(nozzle_slider), explored_parts.size())
	_refresh_report()


func _refresh_part_buttons() -> void:
	for part in PARTS:
		var button: Button = part_buttons[part.id]
		var count: int = part_touch_counts[part.id]
		if count == 0:
			button.add_theme_stylebox_override("normal", _style(Color(0.88, 0.91, 0.88), PANEL_STROKE, 8))
			button.add_theme_color_override("font_color", TEXT_DARK)
		elif count == 1:
			button.add_theme_stylebox_override("normal", _style(Color(0.76, 0.91, 0.84), SUCCESS, 8))
			button.add_theme_color_override("font_color", TEXT_DARK)
		else:
			button.add_theme_stylebox_override("normal", _style(Color(0.92, 0.86, 0.68), WARNING, 8))
			button.add_theme_color_override("font_color", TEXT_DARK)


func _refresh_report() -> void:
	explored_label.text = "%d de %d peças exploradas | %d eventos" % [explored_parts.size(), PARTS.size(), events.size()]

	if launch_attempts == 0:
		score_label.text = "Nenhum lançamento testado."
	else:
		score_label.text = "Melhor lançamento: %d%%" % roundi(best_score * 100.0)

	observation_label.text = _build_observation_text()
	timeline_label.text = _build_timeline_text()


func _build_observation_text() -> String:
	var repeated := _repeated_parts_count()
	if launch_attempts == 0 and explored_parts.size() == 0:
		return "A sessão acabou de começar. A bancada observa a ordem das peças exploradas, os ajustes e o momento do primeiro lançamento."
	if launch_attempts > 0 and explored_parts.size() < 3:
		return "O primeiro teste veio antes de uma inspeção ampla. Isso é útil para observar tentativa rápida, não acerto ou erro."
	if explored_parts.size() >= 4 and repeated > 0:
		return "Você explorou várias peças e voltou a pelo menos uma delas, criando uma trilha de confirmação antes do lançamento."
	if best_score >= 0.72:
		return "Os ajustes ficaram equilibrados. Combustível, estabilidade e bocal trabalharam juntos no teste."
	if launch_attempts > 1:
		return "A sessão mostra iteração: testar, observar resposta e ajustar a montagem."
	return "A oficina já tem sinais suficientes para comparar exploração, ajustes e tentativa de lançamento."


func _build_timeline_text() -> String:
	if events.is_empty():
		return "Sem eventos registrados."

	var lines: Array[String] = []
	var start_index: int = maxi(0, events.size() - 8)
	for i in range(start_index, events.size()):
		var event: Dictionary = events[i]
		lines.append("%02d  +%.1fs  %s: %s" % [event.order, event.elapsed, event.kind, event.target])
	return "\n".join(lines)


func _record_event(kind: String, target: String, detail: String) -> void:
	var now := Time.get_unix_time_from_system()
	var event := {
		"order": events.size() + 1,
		"kind": kind,
		"target": target,
		"detail": detail,
		"elapsed": now - session_started_at,
		"since_last": now - last_event_at,
		"timestamp_unix": now
	}
	events.append(event)
	last_event_at = now


func _calculate_launch_score() -> float:
	var fuel := _ratio(fuel_slider)
	var fins := _ratio(fins_slider)
	var nozzle := _ratio(nozzle_slider)
	var fuel_balance: float = 1.0 - minf(absf(fuel - 0.72) * 1.65, 1.0)
	var fin_balance: float = 1.0 - minf(absf(fins - 0.66) * 1.9, 1.0)
	var nozzle_balance: float = 1.0 - minf(absf(nozzle - 0.60) * 1.75, 1.0)
	var exploration_bonus: float = clampf(float(explored_parts.size()) / float(PARTS.size()), 0.0, 1.0) * 0.12
	return clampf((fuel_balance * 0.36) + (fin_balance * 0.34) + (nozzle_balance * 0.30) + exploration_bonus, 0.0, 1.0)


func _session_snapshot() -> Dictionary:
	return {
		"project": "Oficina do Foguete",
		"sessionStartedAtUnix": session_started_at,
		"durationSeconds": Time.get_unix_time_from_system() - session_started_at,
		"exploredParts": explored_parts.keys(),
		"partTouchCounts": part_touch_counts,
		"launchAttempts": launch_attempts,
		"bestLaunchScore": best_score,
		"settings": {
			"fuel": fuel_slider.value,
			"fins": fins_slider.value,
			"nozzle": nozzle_slider.value
		},
		"events": events
	}


func _ratio(slider: HSlider) -> float:
	return float(slider.value) / 100.0


func _repeated_parts_count() -> int:
	var repeated := 0
	for id in part_touch_counts.keys():
		if part_touch_counts[id] > 1:
			repeated += 1
	return repeated


func _part_name(part_id: String) -> String:
	for part in PARTS:
		if part.id == part_id:
			return part.name
	return part_id


func _part_hint(part_id: String) -> String:
	for part in PARTS:
		if part.id == part_id:
			return part.hint
	return ""
