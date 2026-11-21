class_name ActionRunner extends RefCounted

var action: StringName = &""
var duration_s: float = 0.0
var elapsed_s: float = 0.0
var cancellable: bool = true
var progress_kept: bool = false

## Starts one action with a fixed start-rate/modifier duration snapshot.
func start(id: StringName, game_minutes: float, seconds_per_minute: float, modifier: float = 1.0) -> bool:
	if action != &"" or id == &"" or not is_finite(game_minutes * seconds_per_minute * modifier) or game_minutes <= 0 or seconds_per_minute <= 0 or modifier <= 0:
		return false
	action = id
	cancellable = true
	progress_kept = false
	duration_s = game_minutes * seconds_per_minute * modifier
	elapsed_s = 0.0
	return true

## Returns a completed action once; paused time adds no progress.
func advance(delta_s: float, paused: bool = false) -> StringName:
	if action == &"" or paused or not is_finite(delta_s) or delta_s <= 0:
		return &""
	elapsed_s += delta_s
	if elapsed_s < duration_s:
		return &""
	var completed := action
	action = &""
	return completed

## Cancels without completion effects, including movement cancellation.
func cancel(forced: bool = true) -> bool:
	if not forced and not cancellable:
		return false
	action = &""
	elapsed_s = 0.0
	return true

## Returns normalized progress for a read-only presentation adapter.
func progress() -> float:
	return clampf(elapsed_s / duration_s, 0.0, 1.0) if duration_s > 0 else 0.0
