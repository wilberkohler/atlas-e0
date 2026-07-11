extends Node3D
class_name VS1VerticalSliceController

const StateScript := preload("res://scripts/vertical_slice/experience_state.gd")
const TelemetryScript := preload("res://scripts/telemetry/experience_telemetry.gd")
const AttemptRecordScript := preload("res://scripts/telemetry/attempt_record.gd")
const HintScript := preload("res://scripts/ui/contextual_hint_controller.gd")
const OverlayScript := preload("res://scripts/ui/developer_overlay.gd")
const AudioScript := preload("res://scripts/audio/experience_audio.gd")
const WORKSHOP_SCENE := "res://scenes/vertical_slice_v1/workshop_scene.tscn"
const FIELD_SCENE := "res://scenes/vertical_slice_v1/field_test_scene.tscn"
const TRANSITION_SCENE := "res://scenes/vertical_slice_v1/transition_scene.tscn"
const PRESET_PATHS := {
	"stable": "res://resources/flight/stable_profile.tres",
	"spin": "res://resources/flight/spin_profile.tres",
	"lateral": "res://resources/flight/lateral_profile.tres",
	"short": "res://resources/flight/short_profile.tres",
}

var experience_state: Node
var telemetry: Node
var workshop: Node3D
var field: Node3D
var transition: CanvasLayer
var hints: CanvasLayer
var developer_overlay: CanvasLayer
var experience_audio: Node

var _transition_target := ""
var _runtime_attempts: Array[Dictionary] = []
var _pending_interactions: Array[Dictionary] = []
var _assembly_started_ticks := 0
var _attempt_active := false
var _last_overlay_update := 0.0
var _developer_autolaunch_energy := -1.0
var _return_was_cancelled := false


func _ready() -> void:
	_build_services()
	_build_workshop()
	_build_transition()
	_wire_ui()
	var session_id: String = experience_state.call("start_session")
	telemetry.call("start_session", session_id)
	workshop.call("setup", experience_state.configuration)
	workshop.call("set_active", true)
	_assembly_started_ticks = Time.get_ticks_msec()
	_pending_interactions.clear()
	_update_developer_overlay()


func _process(delta: float) -> void:
	_last_overlay_update += delta
	if developer_overlay != null and developer_overlay.visible and _last_overlay_update >= 0.20:
		_last_overlay_update = 0.0
		_update_developer_overlay()


func _build_services() -> void:
	experience_state = StateScript.new()
	experience_state.name = "ExperienceState"
	add_child(experience_state)
	telemetry = TelemetryScript.new()
	telemetry.name = "ExperienceTelemetry"
	add_child(telemetry)
	hints = HintScript.new()
	hints.name = "ContextualHints"
	add_child(hints)
	developer_overlay = OverlayScript.new()
	developer_overlay.name = "DeveloperOverlay"
	add_child(developer_overlay)
	experience_audio = AudioScript.new()
	experience_audio.name = "ExperienceAudio"
	add_child(experience_audio)
	experience_state.configuration_changed.connect(_on_state_configuration_changed)


func _build_workshop() -> void:
	var packed: PackedScene = load(WORKSHOP_SCENE) as PackedScene
	workshop = packed.instantiate() as Node3D
	workshop.name = "WorkshopScene"
	add_child(workshop)
	workshop.rocket_placed.connect(_on_rocket_placed)
	workshop.interaction_event.connect(_on_workshop_interaction)
	workshop.readiness_changed.connect(_on_workshop_readiness_changed)
	workshop.tactile_event.connect(_on_tactile_event)


func _build_transition() -> void:
	var packed: PackedScene = load(TRANSITION_SCENE) as PackedScene
	transition = packed.instantiate() as CanvasLayer
	transition.name = "TransitionScene"
	add_child(transition)
	transition.midpoint.connect(_on_transition_midpoint)
	transition.transition_finished.connect(_on_transition_finished)


func _wire_ui() -> void:
	hints.reset_requested.connect(_reset_experience)
	hints.return_requested.connect(_request_manual_return)
	developer_overlay.preset_requested.connect(_on_preset_requested)
	developer_overlay.deterministic_changed.connect(_on_deterministic_changed)


func _on_workshop_interaction(part_id: String, kind: String, payload: Dictionary) -> void:
	hints.call("mark_interaction")
	_pending_interactions.append({
		"piece_id": part_id,
		"action": kind,
		"elapsed": _assembly_elapsed(),
		"payload": payload.duplicate(true),
	})
	if _pending_interactions.size() > 500:
		_pending_interactions.pop_front()


func _on_workshop_readiness_changed(ready: bool) -> void:
	if ready:
		experience_audio.call("play_event", "ready", workshop.bottle.global_position)


func _on_tactile_event(event_name: String, world_position: Vector3) -> void:
	experience_audio.call("play_event", event_name, world_position)


func _on_rocket_placed(configuration_snapshot: Dictionary) -> void:
	if experience_state.get_phase_name() != "workshop":
		return
	_begin_attempt(configuration_snapshot)
	_transition_target = "field"
	experience_state.call("transition_to_field")
	telemetry.call("mark_phase", "transition_to_field")
	transition.call("play", 0.74)


func _begin_attempt(configuration_snapshot: Dictionary) -> void:
	if _attempt_active:
		return
	var changes_before_attempt: int = experience_state.changes_after_last_flight
	if changes_before_attempt > 0:
		telemetry.call("mark_retry_started", changes_before_attempt)
	var attempt_meta: Dictionary = experience_state.call("begin_attempt")
	telemetry.call("begin_attempt", configuration_snapshot, experience_state.call("get_assembly_metrics"), int(attempt_meta.wind_seed), String(attempt_meta.attempt_id))
	if telemetry.current_attempt != null:
		for event: Dictionary in _pending_interactions:
			telemetry.current_attempt.call("record_interaction", String(event.piece_id), String(event.action), float(event.elapsed), event.payload)
	_attempt_active = true


func _on_transition_midpoint() -> void:
	if _transition_target == "field":
		workshop.call("set_active", false)
		_create_field()
		field.call("set_active", true)
		experience_state.call("enter_field_test")
		telemetry.call("mark_phase", "field_test")
		hints.call("set_return_visible", true)
		hints.call("show_context", "Mova o mecanismo da base.", 2.6)
	elif _transition_target == "workshop":
		if field != null:
			field.call("set_active", false)
		workshop.call("prepare_for_retry")
		workshop.call("set_active", true)
		experience_state.call("enter_workshop")
		hints.call("set_return_visible", false)
		hints.call("show_context", "Observe o que mudou.", 2.8)


func _on_transition_finished() -> void:
	if _transition_target == "field" and _developer_autolaunch_energy >= 0.0:
		field.call("apply_developer_energy", _developer_autolaunch_energy)
		var timer := get_tree().create_timer(0.32)
		timer.timeout.connect(func() -> void:
			if field != null:
				field.call("request_developer_launch")
		)
		_developer_autolaunch_energy = -1.0
	elif _transition_target == "workshop":
		if field != null:
			field.queue_free()
			field = null
		_pending_interactions.clear()
		_assembly_started_ticks = Time.get_ticks_msec()
		_attempt_active = false
		if _return_was_cancelled:
			telemetry.call("abandon_current_attempt")
			_return_was_cancelled = false
	_transition_target = ""


func _create_field() -> void:
	if field != null:
		field.queue_free()
	var packed: PackedScene = load(FIELD_SCENE) as PackedScene
	field = packed.instantiate() as Node3D
	field.name = "FieldTestScene"
	add_child(field)
	field.state_changed.connect(_on_field_state_changed)
	field.energy_changed.connect(_on_field_energy_changed)
	field.launch_completed.connect(_on_field_launch_completed)
	field.review_ready.connect(_on_field_review_ready)
	field.return_requested.connect(_on_field_return_requested)
	field.tactile_event.connect(_on_tactile_event)
	field.call("setup", experience_state.call("configuration_snapshot"), experience_state.call("get_assembly_metrics"), experience_state.current_wind_seed, _runtime_attempts)


func _on_field_energy_changed(level: float) -> void:
	experience_state.configuration.call("set_energy_level", level)


func _on_field_state_changed(_previous: StringName, next_state: StringName, _context: Dictionary) -> void:
	telemetry.call("mark_phase", String(next_state).to_lower())
	if next_state == &"ANTICIPATION":
		if telemetry.current_attempt != null:
			telemetry.current_attempt.call("mark_launch", _assembly_elapsed())
		hints.call("show_context", "", 0.0)


func _on_field_launch_completed(summary: Dictionary) -> void:
	if telemetry.current_attempt != null:
		telemetry.current_attempt.configuration_snapshot = experience_state.call("configuration_snapshot")
		telemetry.current_attempt.metrics_snapshot = experience_state.call("get_assembly_metrics")
	var completed: Dictionary = telemetry.call("complete_attempt", summary, 0)
	if not completed.is_empty():
		var record: RefCounted = AttemptRecordScript.from_snapshot(completed)
		experience_state.call("complete_attempt", record)
	_runtime_attempts.append(summary.duplicate(true))
	while _runtime_attempts.size() > 2:
		_runtime_attempts.pop_front()
	_attempt_active = false
	_update_developer_overlay()


func _on_field_review_ready(_summary: Dictionary) -> void:
	hints.call("show_context", "Observe o que mudou.", 2.2)


func _on_field_return_requested(_summary: Dictionary) -> void:
	_start_return_to_workshop(false)


func _request_manual_return() -> void:
	if experience_state.get_phase_name() == "workshop":
		return
	_start_return_to_workshop(true)


func _start_return_to_workshop(cancelled: bool) -> void:
	if _transition_target != "":
		return
	_return_was_cancelled = cancelled
	_transition_target = "workshop"
	experience_state.call("transition_to_workshop")
	if _attempt_active and cancelled:
		telemetry.call("abandon_current_attempt")
		_attempt_active = false
	transition.call("play", 0.70)


func _on_state_configuration_changed(_snapshot: Dictionary) -> void:
	_update_developer_overlay()


func _on_preset_requested(preset_id: String) -> void:
	if not PRESET_PATHS.has(preset_id) or experience_state.get_phase_name() != "workshop":
		return
	var profile: Resource = load(PRESET_PATHS[preset_id])
	if profile == null or not profile.has_method("to_configuration_snapshot"):
		return
	var snapshot: Dictionary = profile.call("to_configuration_snapshot")
	experience_state.call("restore_configuration", snapshot)
	workshop.call("restore_from_configuration", snapshot)
	_pending_interactions.clear()
	_assembly_started_ticks = Time.get_ticks_msec()
	_begin_attempt(snapshot)
	_developer_autolaunch_energy = float(snapshot.get("energy_level", 0.72))
	_transition_target = "field"
	experience_state.call("transition_to_field")
	telemetry.call("mark_phase", "transition_to_field")
	transition.call("play", 0.48)


func _on_deterministic_changed(enabled: bool) -> void:
	experience_state.call("set_keep_wind_for_comparison", enabled)


func _reset_experience() -> void:
	if field != null:
		field.queue_free()
		field = null
	_transition_target = ""
	transition.visible = false
	var session_id: String = experience_state.call("start_session")
	telemetry.call("abandon_current_attempt")
	telemetry.call("start_session", session_id)
	_runtime_attempts.clear()
	_pending_interactions.clear()
	workshop.call("restore_from_configuration", experience_state.call("configuration_snapshot"))
	workshop.call("set_active", true)
	hints.call("set_return_visible", false)
	hints.call("show_context", "", 0.0)
	_assembly_started_ticks = Time.get_ticks_msec()
	_attempt_active = false


func _update_developer_overlay() -> void:
	if developer_overlay == null or experience_state == null:
		return
	var body_snapshot: Dictionary = {}
	var flight_state := "—"
	if field != null and field.sequence != null:
		flight_state = String(field.sequence.current_state)
		if field.rocket_body != null:
			body_snapshot = field.rocket_body.call("get_snapshot")
	developer_overlay.call("set_snapshot", {
		"phase": experience_state.call("get_phase_name"),
		"flight_state": flight_state,
		"wind_seed": experience_state.current_wind_seed,
		"attempt_count": experience_state.attempt_history.call("size"),
		"configuration": experience_state.call("configuration_snapshot"),
		"metrics": experience_state.call("get_assembly_metrics"),
		"forces": {
			"thrust": body_snapshot.get("thrust_force", Vector3.ZERO),
			"drag": body_snapshot.get("drag_force", Vector3.ZERO),
			"wind": body_snapshot.get("wind_force", Vector3.ZERO),
			"stability_torque": body_snapshot.get("stability_torque", Vector3.ZERO),
			"asymmetry_torque": body_snapshot.get("asymmetry_torque", Vector3.ZERO),
		},
		"history": experience_state.call("visual_attempts"),
	})


func _assembly_elapsed() -> float:
	return maxf(0.0, float(Time.get_ticks_msec() - _assembly_started_ticks) / 1000.0)
