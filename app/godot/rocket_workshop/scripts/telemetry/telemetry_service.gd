extends Node
class_name TelemetryService

var session_started_at: float = 0.0
var last_event_at: float = 0.0
var events: Array[Dictionary] = []
var first_part_touched: String = ""
var first_action_after_seconds: float = -1.0
var launch_count: int = 0
var best_trajectory: String = "none"
var reposition_counts: Dictionary = {}
var rotation_counts: Dictionary = {}
var snap_attempts: int = 0
var successful_snaps: int = 0
var imperfect_snaps: int = 0


func _ready() -> void:
	reset()


func reset() -> void:
	session_started_at = Time.get_unix_time_from_system()
	last_event_at = session_started_at
	events.clear()
	first_part_touched = ""
	first_action_after_seconds = -1.0
	launch_count = 0
	best_trajectory = "none"
	reposition_counts.clear()
	rotation_counts.clear()
	snap_attempts = 0
	successful_snaps = 0
	imperfect_snaps = 0
	record("session", "start", {"detail": "3D workshop started"})


func record(kind: String, target: String, payload: Dictionary = {}) -> void:
	var now: float = Time.get_unix_time_from_system()
	var elapsed: float = now - session_started_at
	if first_action_after_seconds < 0.0 and kind != "session":
		first_action_after_seconds = elapsed

	var event: Dictionary = {
		"order": events.size() + 1,
		"kind": kind,
		"target": target,
		"elapsed": elapsed,
		"sinceLast": now - last_event_at,
		"timestampUnix": now,
		"payload": payload
	}
	events.append(event)
	last_event_at = now


func record_part_touch(part_id: String, part_type: StringName) -> void:
	if first_part_touched.is_empty():
		first_part_touched = part_id
	record("part_touch", part_id, {"partType": String(part_type)})


func record_drag(part_id: String, duration: float, end_position: Vector3) -> void:
	var count: int = int(reposition_counts.get(part_id, 0)) + 1
	reposition_counts[part_id] = count
	record("drag", part_id, {
		"duration": duration,
		"repositions": count,
		"endPosition": _vec3(end_position)
	})


func record_rotation(part_id: String, rotation_degrees: Vector3) -> void:
	var count: int = int(rotation_counts.get(part_id, 0)) + 1
	rotation_counts[part_id] = count
	record("rotation", part_id, {
		"rotations": count,
		"rotationDegrees": _vec3(rotation_degrees)
	})


func record_snap_attempt(part_id: String, zone_id: String, success: bool, quality: float) -> void:
	snap_attempts += 1
	if success:
		successful_snaps += 1
		if quality < 0.72:
			imperfect_snaps += 1
	record("snap_attempt", part_id, {
		"zone": zone_id,
		"success": success,
		"quality": quality
	})


func record_launch(profile: String, evaluation: Dictionary) -> void:
	launch_count += 1
	best_trajectory = _best_profile(best_trajectory, profile)
	record("launch", profile, {
		"launchCount": launch_count,
		"evaluation": evaluation
	})


func snapshot(assembly_summary: Dictionary = {}) -> Dictionary:
	return {
		"sessionStartedAtUnix": session_started_at,
		"durationSeconds": Time.get_unix_time_from_system() - session_started_at,
		"firstPartTouched": first_part_touched,
		"timeToFirstAction": first_action_after_seconds,
		"launchCount": launch_count,
		"bestTrajectory": best_trajectory,
		"repositionCounts": reposition_counts,
		"rotationCounts": rotation_counts,
		"snapAttempts": snap_attempts,
		"successfulSnaps": successful_snaps,
		"imperfectSnaps": imperfect_snaps,
		"assembly": assembly_summary,
		"events": events
	}


func last_events(limit: int = 10) -> Array[Dictionary]:
	var start_index: int = maxi(0, events.size() - limit)
	var output: Array[Dictionary] = []
	for index: int in range(start_index, events.size()):
		output.append(events[index])
	return output


func seconds_since_last_event() -> float:
	return Time.get_unix_time_from_system() - last_event_at


func _best_profile(current: String, candidate: String) -> String:
	var rank: Dictionary = {
		"none": 0,
		"short_unstable": 1,
		"reasonable_spin": 2,
		"stable": 3
	}
	var current_rank: int = int(rank.get(current, 0))
	var candidate_rank: int = int(rank.get(candidate, 0))
	if candidate_rank > current_rank:
		return candidate
	return current


func _vec3(value: Vector3) -> Dictionary:
	return {
		"x": snappedf(value.x, 0.001),
		"y": snappedf(value.y, 0.001),
		"z": snappedf(value.z, 0.001)
	}
