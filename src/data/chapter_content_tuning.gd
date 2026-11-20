class_name ChapterContentTuning extends Resource

@export var frame_minutes: float
@export var cover_minutes: float
@export var shelter_exposure: float
@export var shelter_bonus_c: float
@export var wire_durability: int
@export var set_minutes: float
@export var check_minutes: float
@export var cook_minutes: float
@export var pickup_minutes: float
@export var crossing_start_minute: int
@export var crossing_length_minutes: int
@export var carry_capacity_kg: float
@export var item_mass_kg: Dictionary[StringName, float]

## Rejects invalid chapter-only data before the run accepts input.
func is_valid() -> bool:
	for minutes: float in [frame_minutes, cover_minutes, set_minutes, check_minutes, cook_minutes, pickup_minutes]:
		if not (minutes >= 0.25 and minutes <= 30.0):
			return false
	if wire_durability <= 0 or crossing_start_minute < 0 or crossing_length_minutes <= 0 or crossing_start_minute + crossing_length_minutes >= 1440:
		return false
	if not (shelter_exposure >= 0.0 and shelter_exposure <= 1.0 and shelter_bonus_c >= 0.0 and shelter_bonus_c <= 10.0 and carry_capacity_kg >= 10.0 and carry_capacity_kg <= 40.0):
		return false
	for item: StringName in [&"hatchet", &"knife", &"ferro_rod", &"snare_wire", &"tarp", &"pemmican", &"stick", &"log", &"grass", &"bark", &"hare_raw", &"hare_cooked"]:
		var mass: float = item_mass_kg.get(item, 0.0)
		if not (mass >= 0.01 and mass <= 10.0):
			return false
	return true
