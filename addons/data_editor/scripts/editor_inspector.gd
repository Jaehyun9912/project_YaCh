@tool
class_name DE_EditorInspector
extends PanelContainer

signal value_confirmed(path: Array, new_value: Variant)

const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")

var _current_meta: Dictionary = {}
var _current_control: Control = null

var _key_label: Label
var _type_label: Label
var _comment_label: Label
var _control_container: VBoxContainer
var _apply_button: Button
var _status_label: Label
var _path_line_edit: LineEdit = null
var _path_file_dialog: FileDialog


func _ready() -> void:
	_build_layout()


func _build_layout() -> void:
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(margin)

	var inner = VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(inner)

	_key_label = Label.new()
	_key_label.text = "KEY: —"
	inner.add_child(_key_label)

	_type_label = Label.new()
	_type_label.text = "TYPE: —"
	inner.add_child(_type_label)

	_comment_label = Label.new()
	_comment_label.text = ""
	_comment_label.modulate = Color(0.7, 0.7, 0.7)
	_comment_label.visible = false
	_comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(_comment_label)

	inner.add_child(HSeparator.new())

	_control_container = VBoxContainer.new()
	_control_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_child(_control_container)

	_apply_button = Button.new()
	_apply_button.text = "Apply"
	_apply_button.visible = false
	_apply_button.pressed.connect(_on_apply_pressed)
	inner.add_child(_apply_button)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(_status_label)

	_path_file_dialog = FileDialog.new()
	_path_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_path_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_path_file_dialog.title = "Select Resource Path"
	_path_file_dialog.file_selected.connect(_on_path_file_selected)
	add_child(_path_file_dialog)


func show_field(meta: Dictionary) -> void:
	_current_meta = meta.duplicate(true)
	_status_label.text = ""

	var path: Array = meta.get("path", [])
	_key_label.text = "KEY: " + (str(path[-1]) if not path.is_empty() else "—")

	var expected_type = str(meta.get("expected_type", ""))
	var display_type = "enum" if SchemaUtils.is_enum_schema_type(expected_type) else expected_type
	_type_label.text = "TYPE: " + display_type

	var comment = str(meta.get("comment", ""))
	_comment_label.text = comment
	_comment_label.visible = not comment.is_empty()

	_rebuild_control(expected_type, meta.get("last_value"))


func _rebuild_control(expected_type: String, current_value: Variant) -> void:
	for child in _control_container.get_children():
		child.queue_free()
	_current_control = null
	_path_line_edit = null
	_apply_button.visible = true

	if SchemaUtils.is_enum_schema_type(expected_type):
		var options = SchemaUtils.get_enum_options(expected_type)
		var btn = OptionButton.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for option in options:
			btn.add_item(option)
		var selected_index = options.find(str(current_value))
		if selected_index >= 0:
			btn.select(selected_index)
		_control_container.add_child(btn)
		_current_control = btn
		return

	var normalized = expected_type.strip_edges().to_lower()

	match normalized:
		"path":
			var path_row = HBoxContainer.new()
			path_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var line_edit = LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = _value_to_text(current_value)
			line_edit.gui_input.connect(func(event):
				if event is InputEventKey and event.pressed:
					if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
						_on_apply_pressed()
			)
			path_row.add_child(line_edit)

			var browse_button = Button.new()
			browse_button.text = "Browse..."
			browse_button.pressed.connect(_on_pick_path_pressed)
			path_row.add_child(browse_button)

			_control_container.add_child(path_row)
			_path_line_edit = line_edit
			_current_control = line_edit
		"bool", "boolean":
			var check = CheckBox.new()
			check.text = "true"
			check.button_pressed = bool(current_value)
			_control_container.add_child(check)
			_current_control = check
		"object", "array":
			var lbl = Label.new()
			lbl.text = "(복합 타입은 직접 편집할 수 없습니다)"
			lbl.modulate = Color(0.6, 0.6, 0.6)
			_control_container.add_child(lbl)
			_apply_button.visible = false
		_:
			var line_edit = LineEdit.new()
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.text = _value_to_text(current_value)
			line_edit.gui_input.connect(func(event):
				if event is InputEventKey and event.pressed:
					if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
						_on_apply_pressed()
			)
			_control_container.add_child(line_edit)
			_current_control = line_edit


func _on_pick_path_pressed() -> void:
	if _path_file_dialog == null:
		return

	_path_file_dialog.clear_filters()
	_path_file_dialog.add_filter("*.png ; PNG Image")
	_path_file_dialog.add_filter("*.jpg ; JPEG Image")
	_path_file_dialog.add_filter("*.jpeg ; JPEG Image")
	_path_file_dialog.add_filter("*.webp ; WEBP Image")
	_path_file_dialog.add_filter("*.svg ; SVG Image")
	_path_file_dialog.add_filter("*.tscn ; Packed Scene")
	_path_file_dialog.add_filter("*.tres ; Resource")
	_path_file_dialog.add_filter("*.res ; Resource")
	_path_file_dialog.add_filter("*.json ; JSON")
	_path_file_dialog.add_filter("*.* ; All Files")

	if _path_line_edit != null and not _path_line_edit.text.is_empty():
		_path_file_dialog.current_path = _path_line_edit.text
	else:
		_path_file_dialog.current_path = "res://"

	_path_file_dialog.popup_centered_ratio(0.7)


func _on_path_file_selected(selected_path: String) -> void:
	if _path_line_edit == null:
		return

	var localized = ProjectSettings.localize_path(selected_path)
	_path_line_edit.text = localized if not localized.is_empty() else selected_path


func _on_apply_pressed() -> void:
	_status_label.text = ""
	_status_label.modulate = Color(1, 0.4, 0.4)

	var expected_type = str(_current_meta.get("expected_type", ""))
	var last_value = _current_meta.get("last_value")
	var result = _read_and_validate(expected_type, last_value)

	if not bool(result.get("ok", false)):
		_status_label.text = str(result.get("reason", "유효하지 않은 값입니다."))
		return

	var new_value = result.get("value")
	var path: Array = _current_meta.get("path", [])

	value_confirmed.emit(path, new_value)

	_current_meta["last_value"] = new_value
	_status_label.modulate = Color(0.4, 1, 0.4)
	_status_label.text = "✓ 적용됨"

	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		_status_label.text = ""


func _read_and_validate(expected_type: String, last_value: Variant) -> Dictionary:
	if _current_control == null:
		return {"ok": false, "reason": "편집 컨트롤이 없습니다."}

	if SchemaUtils.is_enum_schema_type(expected_type):
		var btn := _current_control as OptionButton
		if btn == null:
			return {"ok": false, "reason": "OptionButton을 찾을 수 없습니다."}
		var options = SchemaUtils.get_enum_options(expected_type)
		var idx = btn.get_selected_id()
		if idx < 0 or idx >= options.size():
			return {"ok": false, "reason": "선택된 enum 옵션이 없습니다."}
		return {"ok": true, "value": options[idx]}

	var normalized = expected_type.strip_edges().to_lower()

	if normalized in ["bool", "boolean"]:
		var check := _current_control as CheckBox
		if check == null:
			return {"ok": false, "reason": "CheckBox를 찾을 수 없습니다."}
		return {"ok": true, "value": check.button_pressed}

	var line_edit := _current_control as LineEdit
	if line_edit == null:
		return {"ok": false, "reason": "LineEdit을 찾을 수 없습니다."}
	return _parse_by_type(line_edit.text.strip_edges(), normalized, last_value)


func _parse_by_type(raw_text: String, type_name: String, last_value: Variant) -> Dictionary:
	match type_name:
		"string":
			return {"ok": true, "value": raw_text}
		"path":
			if raw_text.is_empty():
				return {"ok": true, "value": raw_text}
			if raw_text.begins_with("res://") or raw_text.begins_with("user://"):
				return {"ok": true, "value": raw_text}
			return {"ok": false, "reason": "path 타입은 res:// 또는 user:// 경로를 사용하세요."}
		"int":
			if raw_text.is_valid_int():
				return {"ok": true, "value": int(raw_text)}
			return {"ok": false, "reason": "정수(int) 형식이어야 합니다."}
		"float":
			if raw_text.is_valid_float() or raw_text.is_valid_int():
				return {"ok": true, "value": float(raw_text)}
			return {"ok": false, "reason": "실수(float) 형식이어야 합니다."}
		"number":
			if raw_text.is_valid_int():
				return {"ok": true, "value": float(raw_text) if last_value is float else int(raw_text)}
			if raw_text.is_valid_float():
				return {"ok": true, "value": float(raw_text)}
			return {"ok": false, "reason": "숫자 형식이어야 합니다."}
		"bool", "boolean":
			var lowered = raw_text.to_lower()
			if lowered in ["true", "1"]: return {"ok": true, "value": true}
			if lowered in ["false", "0"]: return {"ok": true, "value": false}
			return {"ok": false, "reason": "true/false 또는 1/0만 허용됩니다."}
		"null":
			if raw_text.to_lower() == "null":
				return {"ok": true, "value": null}
			return {"ok": false, "reason": "null 형식이어야 합니다."}
		"any":
			var inferred = _infer_type(last_value)
			if inferred != "any":
				var preserved = _parse_by_type(raw_text, inferred, last_value)
				if bool(preserved.get("ok", false)):
					return preserved
			if raw_text.to_lower() == "null": return {"ok": true, "value": null}
			if raw_text.to_lower() == "true": return {"ok": true, "value": true}
			if raw_text.to_lower() == "false": return {"ok": true, "value": false}
			if raw_text.is_valid_int(): return {"ok": true, "value": int(raw_text)}
			if raw_text.is_valid_float(): return {"ok": true, "value": float(raw_text)}
			return {"ok": true, "value": raw_text}
		_:
			return {"ok": true, "value": raw_text}


func _value_to_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "true" if value else "false"
		_: return str(value)


func _infer_type(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "string"
		TYPE_DICTIONARY: return "object"
		TYPE_ARRAY: return "array"
		_: return "any"
