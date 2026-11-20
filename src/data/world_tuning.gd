class_name WorldTuning extends Resource

@export var half_extent: float = 120.0
@export var lake_bounds: Rect2 = Rect2(25, -35, 90, 55)
@export var kinds: Array[StringName] = [&"bush", &"deadfall", &"birch", &"grass", &"stone"]
@export var ring_counts: Array[Vector3i] = [Vector3i(8, 20, 30), Vector3i(3, 10, 20), Vector3i(0, 6, 8), Vector3i(4, 10, 12), Vector3i(1, 3, 4)]
@export var spacing: Dictionary[StringName, float] = {&"bush": 4.0, &"deadfall": 8.0, &"birch": 3.0, &"grass": 3.0, &"stone": 10.0}
@export var rings: Array[Vector2] = [Vector2(0, 40), Vector2(40, 100), Vector2(100, 170)]
@export var camps: Array[Vector3] = [Vector3(-19, 0, -18), Vector3(17, 0, -23), Vector3(-19, 0, 24)]
@export var count_variance: float = 0.2
@export var placement_retries: int = 30
@export var placement_margin: float = 1.0
@export var camp_clearance: float = 2.0
@export var camp_half_size: float = 4.0
@export var facing_deadfall_distance: Vector2 = Vector2(20, 30)
@export var second_deadfall_distance: Vector2 = Vector2(31, 37)
@export var birch_regions: Array[Rect2] = [Rect2(35, 55, 75, 63)]
@export var stone_regions: Array[Rect2] = [Rect2(-115, -119, 230, 8), Rect2(14, -40, 10, 65), Rect2(25, 21, 90, 12)]
@export var grass_shore: Rect2 = Rect2(15, -35, 9, 55)
@export var primary_yields: Dictionary[StringName, Vector2i] = {&"bush": Vector2i(3, 8), &"deadfall": Vector2i(4, 8), &"grass": Vector2i(2, 4), &"stone": Vector2i(6, 10)}
@export var bark_yield: Vector2i = Vector2i(4, 8)
@export var branch_yield: Vector2i = Vector2i(3, 5)
@export var bonus_grass_yield: Vector2i = Vector2i(0, 2)
@export var sticks_per_bonus_grass: float = 3.0
@export var zone_definitions: Array[Dictionary] = [
	{&"id": &"drifts", &"kind": &"drift", &"bounds": Rect2(-10, 55, 30, 50)},
	{&"id": &"pines_west", &"kind": &"forest", &"bounds": Rect2(-115, -105, 85, 210)},
	{&"id": &"pines_north", &"kind": &"forest", &"bounds": Rect2(-25, -110, 130, 60)},
	{&"id": &"pines_approach", &"kind": &"forest", &"bounds": Rect2(-8, -42, 16, 22)},
	{&"id": &"birch_stand", &"kind": &"forest", &"bounds": Rect2(25, 50, 90, 68)},
	{&"id": &"ridge", &"kind": &"ridge", &"bounds": Rect2(-115, -119, 230, 8)}
]
@export var ice_cell_size: float = 0.5
@export var ice_normal_cm: float = 25.0
@export var thin_ice_cm: Vector2 = Vector2(5, 10)
@export var inlet_width_cells: Vector2i = Vector2i(10, 14)
@export var thin_shore_cells: int = 8
@export var footfall_spacing: float = 0.7
@export var ice_safe_cm: float = 15.0
@export var ice_break_k: float = 0.03
@export var ice_load_k: float = 0.5
@export var ice_hurry_k: float = 2.0
@export var tool_loss_chance: float = 0.1
@export var tool_loss_weights: Dictionary[StringName, int] = {&"hatchet": 2, &"knife": 1, &"ferro_rod": 1}
@export var struggle_seconds: float = 4.0
@export var swim_speed: float = 1.2
@export var shore_clearance: float = 0.6
@export var immersion_depth: float = 0.4
