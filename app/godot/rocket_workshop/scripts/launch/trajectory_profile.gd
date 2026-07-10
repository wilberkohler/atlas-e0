extends Resource
class_name TrajectoryProfile

@export var id: String = "short_unstable"
@export var label: String = "Voo curto"
@export var apex: Vector3 = Vector3(1.2, 1.4, -0.3)
@export var rotation_degrees: Vector3 = Vector3(0.0, 120.0, 18.0)
@export var duration: float = 0.85


static func from_id(profile_id: String) -> Resource:
	var script: Script = load("res://scripts/launch/trajectory_profile.gd") as Script
	var profile: Resource = script.new() as Resource
	profile.id = profile_id
	if profile_id == "stable":
		profile.label = "Voo estável"
		profile.apex = Vector3(2.7, 3.25, -1.20)
		profile.rotation_degrees = Vector3(-4.0, 18.0, -8.0)
		profile.duration = 1.15
	elif profile_id == "reasonable_spin":
		profile.label = "Voo com giro"
		profile.apex = Vector3(2.0, 2.25, -0.82)
		profile.rotation_degrees = Vector3(10.0, 250.0, 26.0)
		profile.duration = 1.00
	else:
		profile.label = "Voo curto"
		profile.apex = Vector3(1.05, 1.15, -0.20)
		profile.rotation_degrees = Vector3(18.0, 135.0, 34.0)
		profile.duration = 0.78
	return profile
