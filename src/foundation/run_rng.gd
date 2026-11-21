class_name RunRng extends RefCounted

var _generator := RandomNumberGenerator.new()
var draw_count: int = 0

func _init(seed_value: int = 1) -> void:
	_generator.seed = seed_value

## Draws once from this run's authoritative stream.
func draw_unit() -> float:
	draw_count += 1
	return _generator.randf()

## Returns detached state for deterministic same-engine replay.
func snapshot() -> Dictionary[StringName, int]:
	return {&"seed": _generator.seed, &"state": _generator.state, &"draw_count": draw_count}

func export_state() -> Dictionary:
	return {"seed": str(_generator.seed), "state": str(_generator.state), "draw_count": str(draw_count)}

func restore_state(dto: Dictionary) -> bool:
	if not CheckpointValues.keys(dto, ["seed", "state", "draw_count"]):
		return false
	for key: String in dto:
		if not CheckpointValues.decimal(dto[key]):
			return false
	if dto.draw_count.to_int() < 0:
		return false
	_generator.seed = dto.seed.to_int()
	_generator.state = dto.state.to_int()
	draw_count = dto.draw_count.to_int()
	return true
