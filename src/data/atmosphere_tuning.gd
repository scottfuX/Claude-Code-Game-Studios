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
