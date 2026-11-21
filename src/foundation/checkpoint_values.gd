class_name CheckpointValues extends RefCounted

static func keys(value: Variant, expected: Array) -> bool:
	if not value is Dictionary or value.size() != expected.size():
		return false
	for key: String in expected:
		if not value.has(key):
			return false
	return true

static func number(value: Variant, low: float, high: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high

static func integer(value: Variant, low: int, high: int) -> bool:
	return number(value, low, high) and float(value) == floor(float(value))

static func text(value: Variant) -> bool:
	return value is String or value is StringName

static func decimal(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(value.to_int()) == value

static func vector(value: Variant) -> bool:
	return value is Array and value.size() == 3 and number(value[0], -100000, 100000) and number(value[1], -100000, 100000) and number(value[2], -100000, 100000)

static func encode_vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func decode_vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])
