extends Resource
class_name FlightParameters

@export_range(0.0, 1.0) var energy: float = 0.6
@export_range(0.0, 1.0) var fin_symmetry: float = 0.7
@export_range(0.0, 1.0) var fin_alignment: float = 0.7
@export_range(0.0, 1.0) var nose_alignment: float = 0.8
@export_range(0.0, 1.0) var attachment_quality: float = 0.7
@export_range(0.0, 1.0) var mass_balance: float = 0.7
@export_range(0.0, 1.0) var body_drag_factor: float = 0.45
@export_range(0.0, 1.0) var wind_strength: float = 0.18
@export var fin_count: int = 2
@export var flight_seed: int = 1001


func to_dict() -> Dictionary:
	return {
		"energy": energy,
		"fin_symmetry": fin_symmetry,
		"fin_alignment": fin_alignment,
		"nose_alignment": nose_alignment,
		"attachment_quality": attachment_quality,
		"mass_balance": mass_balance,
		"body_drag_factor": body_drag_factor,
		"wind_strength": wind_strength,
		"fin_count": fin_count,
		"flight_seed": flight_seed
	}


func clone() -> Resource:
	var copy: Resource = load("res://scripts/flight/flight_parameters.gd").new()
	copy.energy = energy
	copy.fin_symmetry = fin_symmetry
	copy.fin_alignment = fin_alignment
	copy.nose_alignment = nose_alignment
	copy.attachment_quality = attachment_quality
	copy.mass_balance = mass_balance
	copy.body_drag_factor = body_drag_factor
	copy.wind_strength = wind_strength
	copy.fin_count = fin_count
	copy.flight_seed = flight_seed
	return copy
