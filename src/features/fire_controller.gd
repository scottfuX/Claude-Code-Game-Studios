class_name FireController extends RefCounted

signal loss(kind: StringName)

var tuning: SliceTuning
var id: StringName
var position: Vector3
var interaction_revision: int = 0
var stage: StringName = &"Site":
	set(value):
		if stage != value:
			interaction_revision += 1
		stage = value
var fuel: float = 0.0
var burning_wetness: float = 0.0
var smolder_minutes: int = 0
var ember_minutes: int = 0
var kindling_count: int = 0
var tinder_ready: bool = false
var _tinder_fuel: float = 0.0
var _tinder_wetness: float = 0.0
var _kindling_wetness: float = 0.0
var _tinder_quality: float = 1.0
var _thermal: ThermalField

func material_wetness(action: StringName) -> float:
	return _tinder_wetness if action == &"strike" else (_kindling_wetness if stage == &"Smoldering" else burning_wetness)

func material_quality(action: StringName) -> float:
	return _tinder_quality if action == &"strike" else 1.0

func _init(source_id: StringName, site_position: Vector3, thermal: ThermalField, data: SliceTuning = null) -> void:
	id = source_id
	position = site_position
	_thermal = thermal
	tuning = data if data != null else preload("res://assets/data/slice_defaults.tres")
	_thermal.register_heat_source(id, position, 0.0, tuning.ember_radius, false)

## Returns whether an action can commit without changing any owner.
func can_act(action: StringName, inventory: InventoryModel) -> bool:
	match action:
		&"clear_snow":
			return stage == &"Site"
		&"arrange_tinder":
			return stage in [&"Cleared", &"Out", &"Laid"] and not tinder_ready and (kindling_count == tuning.kindling_sticks or inventory.count(&"stick") >= tuning.kindling_sticks) and (inventory.count(&"bark") >= tuning.tinder_bark or inventory.count(&"grass") >= tuning.tinder_grass)
		&"strike":
			return stage == &"Laid" and tinder_ready and inventory.has_tool(&"ferro_rod")
		&"blow_embers":
			return stage == &"Smoldering" or (stage == &"Embers" and fuel >= tuning.kindling_threshold)
		&"add_fuel":
			var item := _preferred_fuel(inventory)
			return stage in [&"Kindling", &"Burning", &"Embers"] and item != &"" and fuel + _effective_fuel(item, inventory) <= tuning.fuel_cap
	return false

## Returns the remaining kindling count without exposing fuel units.
func missing_sticks(inventory: InventoryModel) -> int:
	return maxi(0, tuning.kindling_sticks - kindling_count - inventory.count(&"stick"))

## Reports whether neither supported tinder recipe is stocked.
func missing_tinder(inventory: InventoryModel) -> bool:
	return inventory.count(&"bark") < tuning.tinder_bark and inventory.count(&"grass") < tuning.tinder_grass

## Returns normalized remaining smolder lifetime for presentation.
func smolder_remaining() -> float:
	return clampf(1.0 - float(smolder_minutes) / maxi(1, tuning.smolder_life), 0.0, 1.0)

## Commits one prevalidated completion; refusals preserve all materials.
func commit_action(action: StringName, inventory: InventoryModel, success: bool = true) -> bool:
	if not can_act(action, inventory):
		return false
	match action:
		&"clear_snow":
			stage = &"Cleared"
		&"arrange_tinder":
			var tinder: StringName = &"bark" if inventory.count(&"bark") >= tuning.tinder_bark else &"grass"
			var amount := tuning.tinder_bark if tinder == &"bark" else tuning.tinder_grass
			_tinder_wetness = inventory.wetness(tinder)
			_tinder_quality = inventory.tinder_quality(tinder)
			inventory.consume(tinder, amount)
			_tinder_fuel = amount * tuning.fuel_values[tinder] * (1.0 - tuning.fuel_damp * _tinder_wetness)
			tinder_ready = true
			if kindling_count == 0:
				_kindling_wetness = inventory.wetness(&"stick")
				inventory.consume(&"stick", tuning.kindling_sticks)
				kindling_count = tuning.kindling_sticks
			stage = &"Laid"
			ember_minutes = 0
		&"strike":
			if success:
				stage = &"Smoldering"
				smolder_minutes = 0
		&"blow_embers":
			if success:
				if stage == &"Smoldering":
					var kindling_fuel := kindling_count * tuning.fuel_values[&"stick"] * (1.0 - tuning.fuel_damp * _kindling_wetness)
					fuel = kindling_fuel + _tinder_fuel
					burning_wetness = (_kindling_wetness * kindling_fuel + _tinder_wetness * _tinder_fuel) / maxf(0.001, fuel)
					kindling_count = 0
					tinder_ready = false
					_tinder_fuel = 0.0
				ember_minutes = 0
				_derive_flame()
			elif stage == &"Smoldering":
				_expire_smolder()
		&"add_fuel":
			var item := _preferred_fuel(inventory)
			var smother := stage == &"Kindling" and item == &"log" and inventory.wetness(item) > tuning.wet_log_smother_threshold
			var added := _effective_fuel(item, inventory)
			burning_wetness = (burning_wetness * fuel + inventory.wetness(item) * added) / (fuel + added)
			inventory.consume(item, 1)
			fuel += added
			if smother:
				stage = &"Embers"
				ember_minutes = 0
			elif stage != &"Embers":
				_derive_flame()
	publish_heat()
	return true

## Burns once/minute, resolves deadlines, then synchronously publishes exact heat.
func step_minute(survivor_position: Vector3 = Vector3.ZERO) -> void:
	if stage == &"Smoldering":
		smolder_minutes += 1
		if smolder_minutes >= tuning.smolder_life:
			_expire_smolder()
	elif stage in [&"Kindling", &"Burning"]:
		fuel = maxf(0.0, fuel - burn_rate())
		burning_wetness = maxf(0.0, burning_wetness - tuning.fire_drying_per_minute)
		_derive_flame()
	elif stage == &"Embers":
		ember_minutes += 1
		if ember_minutes >= tuning.ember_life:
			stage = &"Out"
			fuel = 0.0
			if position.distance_to(survivor_position) > tuning.unattended_distance:
				loss.emit(&"fire_died_unattended")
	publish_heat()

## Returns FI1's diminishing size factor.
func size_factor() -> float:
	return 1.0 - exp(-fuel / tuning.fire_scale)

## Returns FI2 centre heat, zero before flame or after Out.
func heat_c() -> float:
	if stage == &"Embers":
		return tuning.ember_heat
	return tuning.fire_heat * size_factor() * (1.0 - tuning.damp_heat * burning_wetness) if stage in [&"Kindling", &"Burning"] else 0.0

## Returns FI3 radius shared by Thermal and rest eligibility.
func warm_radius() -> float:
	return tuning.ember_radius if stage == &"Embers" else tuning.radius_min + tuning.radius_span * size_factor()

## Returns FI6's cosmetic light radius.
func light_radius() -> float:
	return tuning.light_min if stage == &"Embers" else tuning.light_min + tuning.light_span * size_factor()

## Returns FI4 fuel burn using pre-minute fuel and effective wind.
func burn_rate() -> float:
	return (tuning.burn_base + fuel / tuning.burn_divisor) * (1.0 + tuning.burn_wind * _thermal.wind_eff(position))

## Publishes exact authoritative heat/radius even for sub-0.1 changes.
func publish_heat() -> void:
	_thermal.update_heat_source(id, position, heat_c(), warm_radius(), stage in [&"Kindling", &"Burning", &"Embers"])

## Returns detached display data without exposing mutable owner collections.
func snapshot() -> Dictionary[StringName, Variant]:
	return {&"id": id, &"position": position, &"stage": stage, &"fuel": fuel, &"heat_c": heat_c(), &"warm_radius": warm_radius(), &"light_radius": light_radius()}

func _preferred_fuel(inventory: InventoryModel) -> StringName:
	var preferred: StringName = &""
	var largest := 0.0
	for item: StringName in [&"log", &"stick"]:
		var value := _effective_fuel(item, inventory)
		if inventory.count(item) > 0 and value > largest and fuel + value <= tuning.fuel_cap:
			preferred = item
			largest = value
	return preferred

func _effective_fuel(item: StringName, inventory: InventoryModel) -> float:
	return tuning.fuel_values[item] * (1.0 - tuning.fuel_damp * inventory.wetness(item))

func _expire_smolder() -> void:
	tinder_ready = false
	_tinder_fuel = 0.0
	stage = &"Laid"

func _derive_flame() -> void:
	if fuel >= tuning.burning_threshold:
		stage = &"Burning"
	elif fuel >= tuning.kindling_threshold:
		stage = &"Kindling"
	else:
		stage = &"Embers"
		ember_minutes = 0

func export_state() -> Dictionary:
	return {"id": String(id), "position": CheckpointValues.encode_vector(position), "stage": String(stage), "fuel": fuel,
		"burning_wetness": burning_wetness, "smolder_minutes": smolder_minutes, "ember_minutes": ember_minutes,
		"kindling_count": kindling_count, "tinder_ready": tinder_ready, "tinder_fuel": _tinder_fuel}

func restore_state(dto: Dictionary) -> bool:
	if not CheckpointValues.keys(dto, export_state().keys()) or not CheckpointValues.text(dto.id) or dto.id != String(id) or not CheckpointValues.vector(dto.position):
		return false
	var p := CheckpointValues.decode_vector(dto.position)
	var field: PlayfieldTuning = preload("res://assets/data/playfield_defaults.tres")
	if absf(p.x) >= field.half_extent or absf(p.z) >= field.half_extent or absf(p.y) > 0.01:
		return false
	if not CheckpointValues.text(dto.stage) or dto.stage not in ["Site", "Cleared", "Laid", "Smoldering", "Kindling", "Burning", "Embers", "Out"] or not dto.tinder_ready is bool:
		return false
	if not CheckpointValues.number(dto.fuel, 0, tuning.fuel_cap) or not CheckpointValues.number(dto.burning_wetness, 0, 1) or not CheckpointValues.number(dto.tinder_fuel, 0, tuning.fuel_cap):
		return false
	if not CheckpointValues.integer(dto.smolder_minutes, 0, tuning.smolder_life) or not CheckpointValues.integer(dto.ember_minutes, 0, tuning.ember_life) or not CheckpointValues.integer(dto.kindling_count, 0, tuning.kindling_sticks):
		return false
	if (dto.kindling_count != 0 and dto.kindling_count != tuning.kindling_sticks) or (dto.tinder_ready and dto.kindling_count != tuning.kindling_sticks) or (not dto.tinder_ready and dto.tinder_fuel != 0):
		return false
	if dto.tinder_ready and dto.tinder_fuel not in [tuning.tinder_bark * tuning.fuel_values[&"bark"], tuning.tinder_grass * tuning.fuel_values[&"grass"]]:
		return false
	if dto.stage in ["Site", "Cleared", "Laid", "Smoldering", "Out"] and dto.fuel != 0:
		return false
	if (dto.stage == "Burning" and dto.fuel < tuning.burning_threshold) or (dto.stage == "Kindling" and (dto.fuel < tuning.kindling_threshold or dto.fuel >= tuning.burning_threshold)):
		return false
	if dto.stage == "Smoldering" and (not dto.tinder_ready or dto.smolder_minutes >= tuning.smolder_life):
		return false
	if dto.stage == "Embers" and dto.ember_minutes >= tuning.ember_life:
		return false
	if dto.stage in ["Site", "Cleared", "Kindling", "Burning", "Embers", "Out"] and (dto.kindling_count != 0 or dto.tinder_ready):
		return false
	if dto.stage == "Laid" and dto.kindling_count != tuning.kindling_sticks:
		return false
	position = p
	stage = StringName(dto.stage)
	fuel = float(dto.fuel)
	burning_wetness = float(dto.burning_wetness)
	smolder_minutes = int(dto.smolder_minutes)
	ember_minutes = int(dto.ember_minutes)
	kindling_count = int(dto.kindling_count)
	tinder_ready = dto.tinder_ready
	_tinder_fuel = float(dto.tinder_fuel)
	publish_heat()
	return true
