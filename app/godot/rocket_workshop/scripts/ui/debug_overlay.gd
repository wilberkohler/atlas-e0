extends CanvasLayer
class_name DebugOverlay

var panel: PanelContainer = null
var grid: GridContainer = null
var title_label: Label = null
var session_label: Label = null
var flight_label: Label = null
var params_label: Label = null
var assembly_label: Label = null
var graph_label: Label = null
var timeline_label: Label = null
var json_label: Label = null


func _ready() -> void:
	layer = 80
	_build()
	visible = false


func set_snapshot(snapshot: Dictionary) -> void:
	title_label.text = "DEV / F2 - telemetria do foguete"
	session_label.text = _session_text(snapshot)
	flight_label.text = _flight_text(snapshot)
	params_label.text = _params_text(snapshot)
	assembly_label.text = _assembly_text(snapshot)
	graph_label.text = _graph_text(snapshot)
	timeline_label.text = _timeline_text(snapshot)
	json_label.text = _compact_json_text(snapshot)


func _session_text(snapshot: Dictionary) -> String:
	return "Sessao\nTempo %s\nPrimeira acao %s\nLancamentos %d\nMelhor %s\nEncaixes %d/%d" % [
		_seconds_text(float(snapshot.get("durationSeconds", 0.0))),
		_seconds_text(float(snapshot.get("timeToFirstAction", -1.0))),
		int(snapshot.get("launchCount", 0)),
		String(snapshot.get("bestTrajectory", "none")),
		int(snapshot.get("successfulSnaps", 0)),
		int(snapshot.get("snapAttempts", 0))
	]


func _flight_text(snapshot: Dictionary) -> String:
	var flight: Dictionary = _dict(snapshot.get("lastFlight", {}))
	if flight.is_empty():
		return "Ultimo voo\nSem lancamento ainda."
	return "Ultimo voo\nPerfil %s\nAltura %.2f\nDuracao %.2fs\nDeslocamento %.2f\nImpacto %s" % [
		String(flight.get("profile", "")),
		float(flight.get("max_height", 0.0)),
		float(flight.get("flight_duration", 0.0)),
		float(flight.get("horizontal_displacement", 0.0)),
		_vec3_short(flight.get("impact_position", {}))
	]


func _params_text(snapshot: Dictionary) -> String:
	var flight: Dictionary = _dict(snapshot.get("lastFlight", {}))
	var params: Dictionary = _dict(flight.get("parameters_snapshot", {}))
	if params.is_empty():
		return "Parametros\nAguardando voo."
	return "Parametros\nEnergia %.2f\nAletas %d\nSimetria %.2f\nCone %.2f\nFixacao %.2f\nVento %.2f" % [
		float(params.get("energy", 0.0)),
		int(params.get("fin_count", 0)),
		float(params.get("fin_symmetry", 0.0)),
		float(params.get("nose_alignment", 0.0)),
		float(params.get("attachment_quality", 0.0)),
		float(params.get("wind_strength", 0.0))
	]


func _assembly_text(snapshot: Dictionary) -> String:
	var assembly: Dictionary = _dict(snapshot.get("assembly", {}))
	if assembly.is_empty():
		return "Montagem\nSem dados."

	var missing_items: Array[String] = []
	for item: Variant in _array(assembly.get("missing", [])):
		missing_items.append(String(item))

	var missing_text := "nada"
	if not missing_items.is_empty():
		missing_text = ", ".join(missing_items)

	return "Montagem\nPronto %s\nAletas %d/3\nCone %.2f\nEnergia %.2f\nFaltando %s" % [
		"sim" if bool(assembly.get("readyForLaunch", false)) else "nao",
		int(assembly.get("finCount", 0)),
		float(assembly.get("coneQuality", 0.0)),
		float(assembly.get("energyScore", 0.0)),
		missing_text
	]


func _graph_text(snapshot: Dictionary) -> String:
	var flight: Dictionary = _dict(snapshot.get("lastFlight", {}))
	if flight.is_empty():
		return "Graficos\nAltura --\nVelocidade --"
	return "Graficos\nAltura %s\nVelocidade %s\nGiro medio %.2f\nGiro max %.2f\nRotacoes %.2f" % [
		String(flight.get("height_graph", "")),
		String(flight.get("speed_graph", "")),
		float(flight.get("mean_angular_velocity", 0.0)),
		float(flight.get("max_angular_velocity", 0.0)),
		float(flight.get("rotation_count", 0.0))
	]


func _timeline_text(snapshot: Dictionary) -> String:
	var events: Array = _array(snapshot.get("events", []))
	if events.is_empty():
		return "Timeline\nSem eventos."

	var lines: Array[String] = ["Timeline"]
	var start_index: int = maxi(0, events.size() - 7)
	for index: int in range(start_index, events.size()):
		var event: Dictionary = _dict(events[index])
		lines.append("%02d +%.1fs %s:%s" % [
			int(event.get("order", 0)),
			float(event.get("elapsed", 0.0)),
			String(event.get("kind", "")),
			String(event.get("target", ""))
		])
	return "\n".join(lines)


func _compact_json_text(snapshot: Dictionary) -> String:
	var assembly: Dictionary = _dict(snapshot.get("assembly", {}))
	var flight: Dictionary = _dict(snapshot.get("lastFlight", {}))
	var compact: Dictionary = {
		"session": {
			"duration": snappedf(float(snapshot.get("durationSeconds", 0.0)), 0.01),
			"launchCount": int(snapshot.get("launchCount", 0)),
			"best": String(snapshot.get("bestTrajectory", "none"))
		},
		"assembly": {
			"ready": bool(assembly.get("readyForLaunch", false)),
			"fins": int(assembly.get("finCount", 0)),
			"cone": snappedf(float(assembly.get("coneQuality", 0.0)), 0.01),
			"energy": snappedf(float(assembly.get("energyScore", 0.0)), 0.01)
		},
		"lastFlight": {
			"profile": String(flight.get("profile", "")),
			"height": snappedf(float(flight.get("max_height", 0.0)), 0.01),
			"duration": snappedf(float(flight.get("flight_duration", 0.0)), 0.01),
			"spin": snappedf(float(flight.get("rotation_count", 0.0)), 0.01)
		}
	}
	return "Resumo bruto: %s" % JSON.stringify(compact)


func _build() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	panel = PanelContainer.new()
	panel.anchor_left = 0.03
	panel.anchor_right = 0.97
	panel.anchor_top = 0.06
	panel.anchor_bottom = 0.94
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.05, 0.05, 0.9)
	panel_style.border_color = Color(0.28, 0.34, 0.34, 0.9)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 14
	panel_style.content_margin_right = 14
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(panel)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(outer)

	title_label = _label(20)
	outer.add_child(title_label)

	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(grid)

	session_label = _card()
	flight_label = _card()
	params_label = _card()
	assembly_label = _card()
	graph_label = _card()
	timeline_label = _card()
	grid.add_child(session_label)
	grid.add_child(flight_label)
	grid.add_child(params_label)
	grid.add_child(assembly_label)
	grid.add_child(graph_label)
	grid.add_child(timeline_label)

	json_label = _label(11)
	json_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	json_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	json_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(json_label)


func _card() -> Label:
	var label: Label = _label(13)
	label.custom_minimum_size = Vector2(270.0, 132.0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.10, 0.78)
	style.border_color = Color(0.23, 0.30, 0.30, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	label.add_theme_stylebox_override("normal", style)
	return label


func _label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.84, 0.92, 0.88))
	return label


func _seconds_text(value: float) -> String:
	if value < 0.0:
		return "--"
	return "%.1fs" % value


func _dict(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return value
	return {}


func _array(value: Variant) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return value
	return []


func _vec3_short(value: Variant) -> String:
	var dict: Dictionary = _dict(value)
	if dict.is_empty():
		return "--"
	return "%.1f, %.1f, %.1f" % [
		float(dict.get("x", 0.0)),
		float(dict.get("y", 0.0)),
		float(dict.get("z", 0.0))
	]
