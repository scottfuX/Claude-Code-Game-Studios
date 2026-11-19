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
