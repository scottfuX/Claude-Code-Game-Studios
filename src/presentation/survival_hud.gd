class_name SurvivalHud extends CanvasLayer

signal restart_requested
signal resume_requested
signal quit_requested

var model := HudModel.new()
var _canvas: HudCanvas
var _prompt: Label
var _cue: Label
var _hint: Label
var _debug: Label
var _shade: ColorRect
var _panel: PanelContainer
var _menu_text: Label
var _resume: Button
var _restart: Button
var _quit: Button
var _context: StringName = &"gameplay"
var _previous_context: StringName = &""
var _debug_open: bool = false
var _help_open: bool = false
var _cue_text: String = ""
var _cue_remaining: float = 0.0
var _invalid_reported: bool = false

func _ready() -> void:
	_canvas = HudCanvas.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.set_color("font_color", "Label", Color("eee7d6"))
	theme.set_color("font_shadow_color", "Label", Color(0.02, 0.04, 0.07, 0.95))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_constant("shadow_outline_size", "Label", 2)
	theme.set_font_size("font_size", "Label", 20)
	theme.set_font_size("font_size", "Button", 20)
	_canvas.theme = theme
	add_child(_canvas)
	_prompt = _label(_canvas)
	_cue = _label(_canvas)
	_hint = _label(_canvas)
	_hint.add_theme_font_size_override("font_size", 18)
	_shade = ColorRect.new()
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.color = Color(0.015, 0.025, 0.05, 0.60)
	_canvas.add_child(_shade)
	_panel = PanelContainer.new()
	_canvas.add_child(_panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.065, 0.09, 0.97)
	style.border_color = Color("9b9c94")
	style.set_border_width_all(1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	_panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	_panel.add_child(column)
	_menu_text = _label(column)
	_menu_text.add_theme_font_size_override("font_size", 26)
	_menu_text.custom_minimum_size = Vector2(360, 48)
	_resume = _button(column, &"HUD_RESUME", func() -> void: resume_requested.emit())
	_restart = _button(column, &"HUD_RESTART", func() -> void: restart_requested.emit())
	_quit = _button(column, &"HUD_QUIT", func() -> void: quit_requested.emit())
	_debug = _label(_canvas)
	_debug.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_debug.add_theme_font_size_override("font_size", 18)
	_panel.hide()
	_shade.hide()
	_debug.hide()

## Sets explicit visibility precedence without pausing or querying gameplay owners.
func set_visibility_context(context: StringName) -> void:
	_context = context

## Shows the newest localized refusal/mishap for an unpaused real-second lifetime.
func show_cue(message: String) -> void:
	_cue_text = message
	_cue_remaining = model.tuning.cue_s

## Reopens controls independently of the first-fire onboarding latch.
func toggle_help() -> void:
	_help_open = not _help_open

## Toggles the isolated developer surface; release builds cannot enable it.
func toggle_debug() -> void:
	if OS.is_debug_build():
		_debug_open = not _debug_open

## Renders only a detached end-of-update snapshot; the HUD never owns game state.
func render_snapshot(snapshot: Dictionary) -> void:
	var dt: float = snapshot.get(&"real_delta_s", 0.0)
	var paused: bool = snapshot.get(&"paused", false)
	if not model.update(snapshot, dt, paused) and not _invalid_reported:
		push_warning("Invalid HUD snapshot; holding last valid band and arc")
		_invalid_reported = true
	if not paused:
		_cue_remaining = maxf(0.0, _cue_remaining - maxf(0.0, dt))
	var terminal: StringName = snapshot.get(&"terminal", &"")
	var context := &"end" if terminal != &"" else _context
	var ordinary := context not in [&"end", &"ritual", &"sleep", &"pause", &"backpack"]
	_canvas.view = {
		&"context": context, &"fill": model.fill, &"arrow": model.arrow,
		&"arc": model.arc, &"moon": model.moon, &"twilight": model.twilight,
		&"opacity": model.opacity, &"band_alpha": model.band_opacity(context, snapshot.get(&"body_stage", &"") == &"Critical"),
		&"energy_fill": model.energy_fill, &"energy_trend": model.energy_trend,
		&"energy_level": model.energy_level, &"elapsed_s": model.elapsed_s,
		&"progress": snapshot.get(&"progress", 0.0) if snapshot.get(&"action", &"") != &"" else -1.0,
	}
	_canvas.queue_redraw()
	_prompt.text = snapshot.get(&"prompt", "")
	_prompt.visible = ordinary and not _prompt.text.is_empty()
	_cue.text = _cue_text
	_cue.visible = ordinary and _cue_remaining > 0
	_hint.text = tr(&"HUD_FIRST_FIRE_HINT") + "\n" + tr(&"HUD_CONTROLS")
	_hint.visible = (ordinary and (not model.hint_gone or _help_open)) or context == &"pause"
	var menu := context in [&"end", &"pause", &"backpack"]
	_panel.visible = menu
	_shade.visible = menu and context != &"backpack"
	_resume.visible = context == &"pause"
	_restart.visible = context != &"backpack"
	_quit.visible = context == &"pause"
	if context == &"end":
		_menu_text.text = tr(&"HUD_DAWN" if terminal == &"dawn_survived" else &"HUD_DEATH")
	elif context == &"pause":
		_menu_text.text = tr(&"HUD_PAUSED")
	elif context == &"backpack":
		var lines := PackedStringArray([tr(&"HUD_BACKPACK"), tr(&"HUD_PACK_LIVE"), ""])
		for tool: StringName in snapshot.get(&"tools", []):
			lines.append(tr(StringName("TOOL_" + String(tool).to_upper())))
		var inventory: Dictionary = snapshot.get(&"inventory", {})
		var any_items := false
		for item: StringName in [&"stick", &"log", &"grass", &"bark"]:
			var count: int = inventory.get(item, 0)
			if count > 0:
				any_items = true
				lines.append(tr(model.quantity_key(count)) % tr(StringName("ITEM_" + String(item).to_upper())))
		if not any_items:
			lines.append(tr(&"HUD_PACK_EMPTY"))
		_menu_text.text = "\n".join(lines)
	if menu and context != &"backpack" and context != _previous_context:
		if context == &"end":
			_restart.grab_focus()
		else:
			_resume.grab_focus()
	_previous_context = context
	_debug.visible = OS.is_debug_build() and _debug_open
	if _debug.visible:
		var clock: Dictionary = snapshot.get(&"clock", {})
		var fuel := PackedStringArray()
		for fire: Dictionary in snapshot.get(&"fires", []):
			fuel.append("%.2f" % float(fire.get(&"fuel", 0.0)))
		var minute: int = clock.get(&"minute_of_day", 0)
		_debug.text = tr(&"HUD_DEBUG") % [snapshot.get(&"core_temp_c", 0.0), snapshot.get(&"felt_temp_c", NAN), snapshot.get(&"energy", 0.0), clock.get(&"day", 1), minute / 60, minute % 60, ", ".join(fuel)]
	_layout()

func _layout() -> void:
	var safe := _canvas.safe_rect()
	var centre := safe.get_center().x
	_prompt.position = Vector2(centre - minf(380, safe.size.x / 2), safe.end.y - 116)
	_prompt.size = Vector2(minf(760, safe.size.x), 65)
	_cue.position = Vector2(centre - minf(360, safe.size.x / 2), safe.get_center().y + 75)
	_cue.size = Vector2(minf(720, safe.size.x), 62)
	var hint_width := maxf(200, safe.size.x - 210)
	_hint.position = Vector2(centre - hint_width / 2 - 35, safe.position.y + 6)
	_hint.size = Vector2(hint_width, 100)
	_panel.size = _panel.get_combined_minimum_size()
	_panel.position = Vector2(safe.position.x, safe.position.y + 110) if _context == &"backpack" else safe.get_center() - _panel.size / 2
	_debug.position = safe.position + Vector2(0, 115)
	_debug.size = Vector2(minf(700, safe.size.x), 160)

func _label(parent: Node) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Node, key: StringName, callback: Callable) -> Button:
	var button := Button.new()
	button.text = tr(key)
	button.custom_minimum_size = Vector2(0, 42)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
