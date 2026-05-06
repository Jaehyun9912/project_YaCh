@tool
class_name DE_EditorInspector
extends PanelContainer

signal value_confirmed(path: Array, new_value: Variant, edit_options: Dictionary)
signal map_key_rename_requested(path: Array, new_key: String)
signal entry_delete_requested(path: Array)

const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")

# _current_meta는 TreeRenderer가 심어 둔 path, expected_type, default 정보 묶음입니다.
# 선택이 바뀔 때마다 이 값을 교체하고, Apply 시 다시 참고합니다.
var _current_meta: Dictionary = {}
var _current_control: Control = null

@onready var _key_label: Label = $MarginContainer/VBoxContainer/KeyLabel
@onready var _type_label: Label = $MarginContainer/VBoxContainer/TypeLabel
@onready var _comment_label: Label = $MarginContainer/VBoxContainer/CommentLabel
@onready var _default_label: Label = $MarginContainer/VBoxContainer/DefaultLabel
@onready var _omit_default_checkbox: CheckBox = $MarginContainer/VBoxContainer/OmitDefaultCheckbox
@onready var _control_container: VBoxContainer = $MarginContainer/VBoxContainer/ControlContainer
@onready var _apply_button: Button = $MarginContainer/VBoxContainer/ApplyButton
@onready var _status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
var _path_line_edit: LineEdit = null
@onready var _path_file_dialog: FileDialog = $PathFileDialog


func _ready():
	_comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_default_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_omit_default_checkbox.visible = false
	_path_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_path_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_path_file_dialog.title = "Select Resource Path"
	if not _apply_button.pressed.is_connected(_on_apply_pressed):
		_apply_button.pressed.connect(_on_apply_pressed)
	if not _path_file_dialog.file_selected.is_connected(_on_path_file_selected):
		_path_file_dialog.file_selected.connect(_on_path_file_selected)


func trigger_add_array_element(meta: Dictionary) -> void:
	# MainPanel에서 array 선택 후 + 버튼으로 호출되는 공개 메서드입니다.
	_current_meta = meta.duplicate(true)
	_on_add_array_element_pressed()


func show_field(meta: Dictionary) -> void:
	# 선택된 트리 항목의 metadata를 기준으로 라벨, 기본값 안내, 편집기를 한 번에 갱신합니다.
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

	var has_default = bool(meta.get("has_default", false))
	if has_default:
		var default_text = "기본값: %s" % _value_to_text(meta.get("default_value", null))
		_default_label.text = default_text
		_default_label.visible = true
	else:
		_default_label.visible = false

	_omit_default_checkbox.visible = false
	_omit_default_checkbox.button_pressed = false

	if has_default and bool(meta.get("can_omit", false)) and not bool(meta.get("has_explicit_value", true)):
		# 실제 파일에는 키가 없고 기본값만 적용 중이라는 점을 별도 상태 문구로 알려 줍니다.
		_status_label.modulate = Color(0.95, 0.86, 0.48)
		_status_label.text = "현재 파일에는 키가 없고 기본값이 적용 중입니다."

	_rebuild_control(expected_type, meta.get("last_value"))


func clear_inspector() -> void:
	# 인스펙터의 모든 표시 정보와 컨트롤을 초기화합니다.
	_current_meta = {}
	_key_label.text = "선택된 항목 없음"
	_type_label.text = ""
	_comment_label.text = ""
	_default_label.text = ""
	_status_label.text = ""
	for child in _control_container.get_children():
		child.queue_free()
	_current_control = null
	_apply_button.visible = false


func _rebuild_control(expected_type: String, current_value: Variant) -> void:
	# 선택한 값의 타입에 맞는 단일 편집 컨트롤만 다시 생성합니다.
	# 이전 컨트롤은 모두 폐기해 패널 상태가 누적되지 않게 합니다.
	for child in _control_container.get_children():
		child.queue_free()
	_current_control = null
	_path_line_edit = null
	_apply_button.visible = true

	if bool(_current_meta.get("is_map_entry", false)):
		# map 엔트리는 값 타입과 무관하게 key 변경 입력을 먼저 제공합니다.
		_add_map_key_rename_controls()

	if _is_entry_deletable():
		_add_entry_delete_controls()

	if SchemaUtils.is_enum_schema_type(expected_type):
		# enum은 자유 입력보다 선택식 UI가 안전하므로 OptionButton만 사용합니다.
		var options: Variant = _current_meta.get("enum_options", SchemaUtils.get_enum_options(expected_type))
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
			# path 타입은 직접 입력과 파일 브라우저를 함께 제공해 리소스 경로 선택을 쉽게 합니다.
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
			# bool은 문자열보다 체크박스가 의도 전달이 명확합니다.
			var check = CheckBox.new()
			check.text = "true"
			check.button_pressed = bool(current_value)
			_control_container.add_child(check)
			_current_control = check
		"array":
			# 배열은 현재 값 전체를 다시 써 넣는 방식으로 안전하게 원소를 추가합니다.
			var row = HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var count_label = Label.new()
			var count = current_value.size() if current_value is Array else 0
			count_label.text = "원소 수: %d" % count
			count_label.modulate = Color(0.75, 0.75, 0.75)
			count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(count_label)

			var add_button = Button.new()
			add_button.text = "원소 추가"
			add_button.pressed.connect(_on_add_array_element_pressed)
			row.add_child(add_button)

			_control_container.add_child(row)
			_apply_button.visible = false
		"object", "map":
			# 복합 타입은 현재 Inspector에서 부분 편집을 지원하지 않아 읽기 전용 안내만 표시합니다.
			var lbl = Label.new()
			lbl.text = "(복합 타입은 직접 편집할 수 없습니다)"
			lbl.modulate = Color(0.6, 0.6, 0.6)
			_control_container.add_child(lbl)
			_apply_button.visible = false
		_:
			# 나머지 원시 타입은 LineEdit로 받고 Apply 시 타입 검증을 수행합니다.
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


func _on_add_array_element_pressed() -> void:
	# 현재 배열 값을 복사해 새 원소를 append한 뒤 Editor로 전달합니다.
	var path: Array = _current_meta.get("path", [])
	var last_value = _current_meta.get("last_value", null)
	if not (last_value is Array):
		_status_label.modulate = Color(1, 0.4, 0.4)
		_status_label.text = "배열 값을 찾을 수 없습니다."
		return

	var next_array: Array = last_value.duplicate(true)
	var next_value = _build_default_array_item_value(last_value)
	next_array.append(next_value)

	value_confirmed.emit(path, next_array, {})
	_current_meta["last_value"] = next_array

	_status_label.modulate = Color(0.4, 1, 0.4)
	_status_label.text = "✓ 배열 원소가 추가되었습니다"

	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		_status_label.text = ""


func _build_default_array_item_value(current_array: Array) -> Variant:
	# item_schema가 있으면 스키마 기본값을 우선 사용하고, 없으면 현재 배열 원소 타입으로 보정합니다.
	var item_schema = _current_meta.get("array_item_schema", {})
	if item_schema is Dictionary:
		var default_info = SchemaUtils.get_schema_default_info(item_schema)
		if bool(default_info.get("has_default", false)):
			return _duplicate_variant(default_info.get("value", null))

		var placeholder = SchemaUtils.get_missing_placeholder(item_schema)
		if placeholder != null:
			return placeholder

	if current_array.size() > 0:
		var sample = current_array[0]
		match typeof(sample):
			TYPE_DICTIONARY:
				return {}
			TYPE_ARRAY:
				return []
			TYPE_STRING:
				return ""
			TYPE_INT:
				return 0
			TYPE_FLOAT:
				return 0.0
			TYPE_BOOL:
				return false

	return null


func _duplicate_variant(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func _add_map_key_rename_controls() -> void:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var key_edit = LineEdit.new()
	key_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key_edit.placeholder_text = "map key"
	key_edit.text = _get_current_map_key_text()
	key_edit.gui_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_on_rename_map_key_pressed(key_edit.text)
	)
	row.add_child(key_edit)

	var rename_button = Button.new()
	rename_button.text = "키 변경"
	rename_button.pressed.connect(func():
		_on_rename_map_key_pressed(key_edit.text)
	)
	row.add_child(rename_button)

	_control_container.add_child(row)


func _get_current_map_key_text() -> String:
	var path: Array = _current_meta.get("path", [])
	if path.is_empty():
		return str(_current_meta.get("map_key", ""))

	return str(_current_meta.get("map_key", path[path.size() - 1]))


func _on_rename_map_key_pressed(raw_new_key: String) -> void:
	var path: Array = _current_meta.get("path", [])
	if path.is_empty():
		_status_label.modulate = Color(1, 0.4, 0.4)
		_status_label.text = "변경할 key 경로가 없습니다."
		return

	var old_key = str(path[path.size() - 1]).strip_edges()
	var new_key = raw_new_key.strip_edges()
	if new_key.is_empty():
		_status_label.modulate = Color(1, 0.4, 0.4)
		_status_label.text = "새 key를 입력하세요."
		return

	if new_key == old_key:
		_status_label.modulate = Color(0.95, 0.86, 0.48)
		_status_label.text = "같은 key 이름입니다."
		return

	map_key_rename_requested.emit(path, new_key)


func _is_entry_deletable() -> bool:
	# 배열 원소 또는 map 엔트리만 삭제 버튼을 노출합니다.
	if bool(_current_meta.get("is_array_entry", false)):
		return true

	if bool(_current_meta.get("is_map_entry", false)):
		return true

	return false


func _add_entry_delete_controls() -> void:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var delete_button = Button.new()
	delete_button.text = "원소 삭제"
	delete_button.pressed.connect(_on_delete_entry_pressed)
	row.add_child(delete_button)

	_control_container.add_child(row)


func _on_delete_entry_pressed() -> void:
	var path: Array = _current_meta.get("path", [])
	if path.is_empty():
		_status_label.modulate = Color(1, 0.4, 0.4)
		_status_label.text = "삭제할 항목 경로가 없습니다."
		return

	entry_delete_requested.emit(path)


func _on_pick_path_pressed() -> void:
	# 자주 쓰는 리소스 확장자를 먼저 제안해 경로 입력 실수를 줄입니다.
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
	# 가능하면 절대 경로 대신 res:// 또는 user:// 형태로 정규화해 저장합니다.
	if _path_line_edit == null:
		return

	var localized = ProjectSettings.localize_path(selected_path)
	_path_line_edit.text = localized if not localized.is_empty() else selected_path


func _on_apply_pressed() -> void:
	# Apply는 입력 읽기, 타입 검증, edit 옵션 구성, signal emit 순서로 진행됩니다.
	_status_label.text = ""
	_status_label.modulate = Color(1, 0.4, 0.4)

	var expected_type = str(_current_meta.get("expected_type", ""))
	var last_value = _current_meta.get("last_value")
	var result = _read_and_validate(expected_type, last_value)

	if not bool(result.get("ok", false)):
		# 검증 실패 시에는 값을 반영하지 않고 오류 메시지만 남깁니다.
		_status_label.text = str(result.get("reason", "유효하지 않은 값입니다."))
		return

	var new_value = result.get("value")
	var path: Array = _current_meta.get("path", [])
	var has_default = bool(_current_meta.get("has_default", false))
	var default_value = _current_meta.get("default_value", null)

	# 기본값 생략 없이 항상 명시적으로 값을 저장합니다.
	value_confirmed.emit(path, new_value, {})

	_current_meta["last_value"] = new_value
	_current_meta["is_default_value"] = has_default and new_value == default_value
	_current_meta["has_explicit_value"] = true

	# 같은 필드를 연속 편집해도 상태 문구가 어긋나지 않도록 로컬 metadata도 즉시 갱신합니다.
	_status_label.modulate = Color(0.4, 1, 0.4)
	_status_label.text = "✓ 적용됨"

	await get_tree().create_timer(1.5).timeout
	if is_inside_tree():
		_status_label.text = ""


func _read_and_validate(expected_type: String, last_value: Variant) -> Dictionary:
	# 현재 컨트롤 종류에 맞게 raw input을 읽고, 공통 파서로 넘겨 Variant를 얻습니다.
	if _current_control == null:
		return {"ok": false, "reason": "편집 컨트롤이 없습니다."}

	if SchemaUtils.is_enum_schema_type(expected_type):
		var btn := _current_control as OptionButton
		if btn == null:
			return {"ok": false, "reason": "OptionButton을 찾을 수 없습니다."}
		var options: Variant = _current_meta.get("enum_options", SchemaUtils.get_enum_options(expected_type))
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
	# 사용자가 입력한 문자열을 스키마가 기대하는 실제 Variant 타입으로 변환합니다.
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
			# number는 이전 값이 float였는지 보고 int/float 표현을 최대한 유지합니다.
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
			# any 타입은 가능하면 이전 값의 타입을 유지해 숫자/불리언이 문자열로 바뀌는 일을 줄입니다.
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
	# null/bool은 JSON에 가까운 표기로 맞추고 나머지는 일반 문자열 변환을 사용합니다.
	match typeof(value):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "true" if value else "false"
		_: return str(value)


func _infer_type(value: Variant) -> String:
	# any 타입 입력을 해석할 때 이전 값의 타입을 최대한 유지하기 위한 보조 함수입니다.
	match typeof(value):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "string"
		TYPE_DICTIONARY: return "object"
		TYPE_ARRAY: return "array"
		_: return "any"
