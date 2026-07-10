extends CanvasLayer
class_name DebugOverlay

var panel: PanelContainer = null
var text_label: Label = null


func _ready() -> void:
	_build()
	visible = false


func set_snapshot(snapshot: Dictionary) -> void:
	if text_label == null:
		return
	var lines: Array[String] = []
	lines.append("DEV / F2")
	lines.append("Primeira peça: %s" % String(snapshot.get("firstPartTouched", "")))
	lines.append("Tempo até ação: %.2fs" % float(snapshot.get("timeToFirstAction", -1.0)))
	lines.append("Testes: %d | Melhor: %s" % [int(snapshot.get("launchCount", 0)), String(snapshot.get("bestTrajectory", "none"))])
	lines.append("Snaps: %d / %d | Imperfeitos: %d" % [
		int(snapshot.get("successfulSnaps", 0)),
		int(snapshot.get("snapAttempts", 0)),
		int(snapshot.get("imperfectSnaps", 0))
	])
	lines.append("")
	lines.append("JSON")
	lines.append(JSON.stringify(snapshot, "  "))
	text_label.text = "\n".join(lines)


func _build() -> void:
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -430.0
	panel.offset_right = -18.0
	panel.offset_top = 86.0
	panel.offset_bottom = -24.0
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.05, 0.86)
	style.border_color = Color(0.28, 0.34, 0.34, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 13)
	text_label.add_theme_color_override("font_color", Color(0.84, 0.92, 0.88))
	scroll.add_child(text_label)
