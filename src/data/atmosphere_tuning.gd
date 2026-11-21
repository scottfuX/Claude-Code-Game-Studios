class_name AtmosphereTuning extends Resource

enum Quality { AUTO, HIGH, LOW }
const SOFTWARE_ADAPTERS: PackedStringArray = ["llvmpipe", "softpipe", "lavapipe", "swiftshader", "software", "microsoft basic render"]
@export var quality: Quality = Quality.AUTO
@export var ambient_audio_enabled: bool = true
@export var low_ambient_audio_enabled: bool = false
@export var snow_count: int = 340
@export var drift_count: int = 32
@export var snow_extent: Vector3 = Vector3(14, 7, 14)
@export var wind_direction: Vector3 = Vector3(0.8, 0, 0.25)
@export var dusk_fog_density: float = 0.012
@export var night_fog_density: float = 0.022
@export var moon_energy: float = 0.28
@export var spark_count: int = 12
@export var smoke_count: int = 10
@export var fire_flicker: float = 0.12
@export var work_sound_interval_s: float = 0.6
@export var wind_volume_db: float = -18.0
@export var fire_volume_db: float = -17.0
@export var foley_volume_db: float = -18.0
@export var sun_shadow_distance: float = 28.0
@export var sun_shadow_opacity: float = 0.5
@export var weather_sun_scale: Dictionary[StringName, float] = {&"Windy": 0.72, &"Snowing": 0.5}
@export var weather_fog_scale: Dictionary[StringName, float] = {&"Windy": 1.3, &"Snowing": 1.8}
@export var weather_snow_scale: Dictionary[StringName, float] = {&"Windy": 1.25, &"Snowing": 1.8}
@export var weather_tint: Color = Color("b3c7df")
@export var weather_tint_strength: float = 0.3
@export var weather_ambient_scale: float = 0.85
@export var cold_snap_tint: Color = Color("99bce8")
@export var cold_snap_tint_strength: float = 0.18
@export var forest_spacing: float = 8.0
@export var forest_jitter: float = 1.5
@export var forest_resource_clearance: float = 1.2
@export var forest_clearing_radius: float = 20.0
@export var forest_scale: Vector2 = Vector2(1.1, 1.7)
@export var forest_boulder_stride: int = 19

## Selects a run-local preset, e.g. uses_low_quality(RenderingServer.get_video_adapter_name()).
func uses_low_quality(adapter: String) -> bool:
	if quality != Quality.AUTO:
		return quality == Quality.LOW
	var normalized := adapter.to_lower()
	for software: String in SOFTWARE_ADAPTERS:
		if normalized.contains(software):
			return true
	return false

## Resolves loop quality without mutating the Resource, e.g. ambient_audio_for(adapter).
func ambient_audio_for(adapter: String) -> bool:
	return low_ambient_audio_enabled if uses_low_quality(adapter) else ambient_audio_enabled
