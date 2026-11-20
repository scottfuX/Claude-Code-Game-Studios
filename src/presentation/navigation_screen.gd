class_name NavigationScreen extends CanvasLayer

signal selected(action: StringName)
signal back_requested

var confirmation: bool = false
var _root: Control
var _column: VBoxContainer
var _heading: Label
var _detail: Label
var _status: Label
var _buttons: Array[Button] = []
var _saved_heading: String = ""
var _saved_detail: String = ""
var _saved_entries: Array = []
var _saved_focus: int = 0
var _confirm_action: StringName

func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = _theme()
	add_child(_root)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.025, 0.05, 0.82)
	_root.add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(centre)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	centre.add_child(panel)
	_column = VBoxContainer.new()
	_column.custom_minimum_size.x = 360
	_column.add_theme_constant_override("separation", 14)
	panel.add_child(_column)
	_heading = _label(28)
	_detail = _label(20)
	_status = _label(20)
	hide()

func show_menu(heading: String, detail: String, entries: Array) -> void:
	confirmation = false
	_saved_heading = heading
	_saved_detail = detail
	_saved_entries = entries.duplicate(true)
	_populate(heading, detail, entries)

func _populate(heading: String, detail: String, entries: Array) -> void:
	for button: Button in _buttons:
		_column.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_heading.text = heading
	_detail.text = detail
	_detail.visible = not detail.is_empty()
	_status.text = ""
	for entry: Array in entries:
		var button := Button.new()
		button.name = String(entry[0])
		button.text = tr(entry[1])
		button.custom_minimum_size = Vector2(360, 46)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_activate.bind(StringName(entry[0])))
		_column.add_child(button)
		_column.move_child(button, _column.get_child_count() - 2)
		_buttons.append(button)
		if entry.size() > 2:
			button.visible = entry[2]
	show()
	_focus(0)

func ask_confirmation(action: StringName, message: StringName) -> void:
	if confirmation:
		return
	_saved_focus = _focus_index()
	_confirm_action = action
	confirmation = true
	_populate(tr(message), "", [[&"cancel", &"MENU_CANCEL"], [&"confirm", &"MENU_CONFIRM"]])

func cancel_confirmation() -> void:
	if not confirmation:
		return
	confirmation = false
	_populate(_saved_heading, _saved_detail, _saved_entries)
	_focus(_saved_focus)

func handle_action(action: StringName) -> void:
	if not visible:
		return
	match action:
		&"ui_up", &"ui_left", &"ui_focus_prev":
			_move_focus(-1)
		&"ui_down", &"ui_right", &"ui_focus_next":
			_move_focus(1)
		&"ui_accept":
			var index := _focus_index()
			if index >= 0:
				_buttons[index].pressed.emit()
		&"ui_cancel", &"pause_menu":
			if confirmation:
				cancel_confirmation()
			else:
				back_requested.emit()

func show_error(key: StringName) -> void:
	_status.text = tr(key)

func _activate(action: StringName) -> void:
	if action == &"cancel":
		cancel_confirmation()
	elif action == &"confirm":
		var accepted := _confirm_action
		cancel_confirmation()
		selected.emit(accepted)
	else:
		selected.emit(action)

func _focus_index() -> int:
	for index: int in _buttons.size():
		if _buttons[index].has_focus():
			return index
	return -1

func _focus(index: int) -> void:
	if _buttons.is_empty():
		return
	for offset: int in _buttons.size():
		var candidate := _buttons[posmod(index + offset, _buttons.size())]
		if candidate.visible and not candidate.disabled:
			candidate.grab_focus()
			return

func _move_focus(direction: int) -> void:
	var index := _focus_index()
	for offset: int in range(1, _buttons.size() + 1):
		var next := posmod(index + direction * offset, _buttons.size())
		if _buttons[next].visible and not _buttons[next].disabled:
			_focus(next)
			return

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 360
	label.add_theme_font_size_override("font_size", font_size)
	_column.add_child(label)
	return label

func _theme() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", Color("eee7d6"))
	theme.set_color("font_shadow_color", "Label", Color(0.02, 0.04, 0.07, 0.95))
	theme.set_constant("shadow_offset_y", "Label", 2)
	theme.set_font_size("font_size", "Label", 20)
	theme.set_font_size("font_size", "Button", 20)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("eee7d6")
	focus.set_border_width_all(3)
	theme.set_stylebox("focus", "Button", focus)
	return theme

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.065, 0.09, 0.97)
	style.border_color = Color("9b9c94")
	style.set_border_width_all(1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	return style
