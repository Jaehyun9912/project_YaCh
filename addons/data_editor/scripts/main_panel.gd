@tool
extends Control

const PathUtils = preload("res://addons/data_editor/scripts/editor_path_utils.gd")
const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")

@export var package_title: Label
@export var file_system : DE_FileSystem
@export var editor : DE_Editor
@export var inspector : DE_EditorInspector
# 상단 버튼들은 씬에서 직접 연결하도록 export로 노출합니다.
@export var save_button: Button
@export var open_folder_button: Button
@export var add_file_button: Button
@export var add_folder_button: Button

var package_path = "res://Data"
var _view_mode_selector: OptionButton
var _status_label: Label
var _add_file_dialog: FileDialog
var _loaded_file_path := ""
var _status_message_serial := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# MainPanel은 파일 목록, 트리 에디터, Inspector를 연결하는 조정자 역할만 맡습니다.
	_setup_save_controls()
	_setup_add_array_element_controls()
	_setup_new_file_dialog_controls()
	_setup_view_mode_selector()
	editor.set_show_implicit_default_fields(false)

	# 패키지 경로에 있는 파일들을 트리에 표시합니다.
	load_package(package_path)
	editor.item_selected_for_edit.connect(inspector.show_field)
	inspector.value_confirmed.connect(editor.apply_external_edit)
	if not inspector.map_key_rename_requested.is_connected(_on_map_key_rename_requested):
		inspector.map_key_rename_requested.connect(_on_map_key_rename_requested)
	if not inspector.entry_delete_requested.is_connected(_on_entry_delete_requested):
		inspector.entry_delete_requested.connect(_on_entry_delete_requested)
	editor.file_loaded.connect(_on_editor_file_loaded)
	editor.dirty_state_changed.connect(_on_editor_dirty_state_changed)
	editor.file_saved.connect(_on_editor_file_saved)
	editor.save_failed.connect(_on_editor_save_failed)
	_refresh_header_text()
	_update_save_button_state()


func _setup_save_controls() -> void:
	# 버튼 노드는 scene에서 연결되고, 여기서는 신호와 상태 라벨만 붙입니다.
	if save_button != null and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
		save_button.tooltip_text = "현재 JSON 파일 저장 (Ctrl+S)"

	var top_bar = get_node_or_null("VBoxContainer/TopBar/MarginContainer/HBoxContainer") as HBoxContainer
	if top_bar == null:
		return

	# 상태 라벨은 씬에 고정 노드로 두지 않고 코드에서 만들어 상단바 끝에 붙입니다.
	_status_label = Label.new()
	_status_label.name = "SaveStatus"
	_status_label.text = ""
	_status_label.visible = false
	_status_label.modulate = Color(0.7, 0.7, 0.7)
	_status_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_bar.add_child(_status_label)


func _setup_add_array_element_controls() -> void:
	# 상단 + 버튼은 선택 항목이 없으면 현재 열린 파일 루트 기준으로 항목을 추가합니다.
	if add_file_button != null and not add_file_button.pressed.is_connected(_on_add_array_element_pressed):
		add_file_button.pressed.connect(_on_add_array_element_pressed)
		add_file_button.tooltip_text = "현재 파일 기준 항목 추가"


func _on_add_array_element_pressed() -> void:
	if _loaded_file_path.is_empty():
		_set_status_message("열린 파일이 없습니다.", Color(1.0, 0.55, 0.55), 2.0)
		return

	# 1) 선택된 항목이 있으면 우선 사용합니다.
	var selected_meta = _get_selected_item_meta()
	if not selected_meta.is_empty():
		var selected_type = str(selected_meta.get("expected_type", "")).strip_edges().to_lower()
		if selected_type == "array":
			inspector.trigger_add_array_element(selected_meta)
			return
		if selected_type == "map":
			if _append_item_to_map(selected_meta):
				return

	# 2) 선택이 없거나 대상이 아니면 열린 파일 루트 기준으로 처리합니다.
	var root_meta = _build_open_file_root_meta()
	if root_meta.is_empty():
		_set_status_message("열린 파일의 루트 타입을 확인할 수 없습니다.", Color(1.0, 0.55, 0.55), 2.0)
		return

	var root_type = str(root_meta.get("expected_type", "")).strip_edges().to_lower()
	if root_type == "array":
		inspector.trigger_add_array_element(root_meta)
		return
	if root_type == "map":
		if _append_item_to_map(root_meta):
			return

	_set_status_message("현재 파일에서는 자동 추가를 지원하지 않습니다.", Color(1.0, 0.55, 0.55), 2.5)


func _on_map_key_rename_requested(path: Array, new_key: String) -> void:
	var result = editor.rename_map_key(path, new_key)
	if bool(result.get("ok", false)):
		var old_key_text = str(result.get("old_key", ""))
		var new_key_text = str(result.get("new_key", ""))
		_set_status_message("키 변경됨: %s -> %s" % [old_key_text, new_key_text], Color(0.56, 0.92, 0.62), 2.0)
		return

	_set_status_message(str(result.get("message", "키 변경 실패")), Color(1.0, 0.55, 0.55), 2.5)


func _on_entry_delete_requested(path: Array) -> void:
	var result = editor.delete_entry(path)
	if bool(result.get("ok", false)):
		_set_status_message(str(result.get("message", "항목 삭제 완료")), Color(0.56, 0.92, 0.62), 2.0)
		return

	_set_status_message(str(result.get("message", "항목 삭제 실패")), Color(1.0, 0.55, 0.55), 2.5)


func _get_selected_item_meta() -> Dictionary:
	var selected_item = editor.get_selected()
	if selected_item == null:
		return {}

	var meta = selected_item.get_metadata(2)
	if meta is Dictionary:
		return meta

	return {}


func _build_open_file_root_meta() -> Dictionary:
	var current_data = editor.current_data
	var root_schema = SchemaUtils.build_root_schema(editor.current_schema, current_data)
	var expected_type = str(root_schema.get("type", "")).strip_edges().to_lower()

	if expected_type.is_empty():
		if current_data is Array:
			expected_type = "array"
		elif current_data is Dictionary:
			expected_type = "map"

	if expected_type.is_empty():
		return {}

	var meta := {
		"path": [],
		"expected_type": expected_type,
		"last_value": _duplicate_variant(current_data)
	}

	if expected_type == "array":
		var item_schema = SchemaUtils.get_array_item_schema(root_schema)
		if item_schema is Dictionary:
			meta["array_item_schema"] = item_schema
	elif expected_type == "map":
		var map_entry_schema = SchemaUtils.get_map_entry_schema(root_schema)
		if map_entry_schema is Dictionary:
			meta["map_entry_schema"] = map_entry_schema

	return meta


func _append_item_to_map(meta: Dictionary) -> bool:
	var current_value = meta.get("last_value", null)
	if not (current_value is Dictionary):
		_set_status_message("맵 항목을 추가할 수 없습니다.", Color(1.0, 0.55, 0.55), 2.0)
		return false

	var next_map: Dictionary = current_value.duplicate(true)
	var new_key = _generate_unique_map_key(next_map)
	var entry_schema = meta.get("map_entry_schema", {})
	next_map[new_key] = _build_default_map_entry_value(entry_schema)

	var path: Array = meta.get("path", [])
	editor.apply_external_edit(path, next_map, {})
	_set_status_message("항목 추가됨: %s" % new_key, Color(0.56, 0.92, 0.62), 2.0)
	return true


func _build_default_map_entry_value(entry_schema: Variant) -> Variant:
	if entry_schema is Dictionary:
		var default_info = SchemaUtils.get_schema_default_info(entry_schema)
		if bool(default_info.get("has_default", false)):
			return _duplicate_variant(default_info.get("value", null))

		var placeholder = SchemaUtils.get_missing_placeholder(entry_schema)
		if placeholder != null:
			return placeholder

	return {}


func _generate_unique_map_key(map_data: Dictionary, base_key: String = "new_item") -> String:
	var key = base_key
	var serial = 1
	while map_data.has(key):
		key = "%s_%d" % [base_key, serial]
		serial += 1

	return key


func _duplicate_variant(value: Variant) -> Variant:
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


func _setup_new_file_dialog_controls() -> void:
	# 파일시스템의 추가 폴더 버튼은 저장 다이얼로그로 목표 경로를 받고, 해당 폴더 규칙으로 새 JSON을 생성합니다.
	if add_folder_button != null and not add_folder_button.pressed.is_connected(_on_create_new_file_pressed):
		add_folder_button.pressed.connect(_on_create_new_file_pressed)
		add_folder_button.tooltip_text = "경로를 선택해 새 JSON 파일 생성"

	if _add_file_dialog != null:
		return

	_add_file_dialog = FileDialog.new()
	_add_file_dialog.name = "AddFileDialog"
	_add_file_dialog.access = FileDialog.ACCESS_RESOURCES
	_add_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_add_file_dialog.title = "새 JSON 파일 생성"
	_add_file_dialog.clear_filters()
	_add_file_dialog.add_filter("*.json ; JSON")
	add_child(_add_file_dialog)

	if not _add_file_dialog.file_selected.is_connected(_on_new_file_target_selected):
		_add_file_dialog.file_selected.connect(_on_new_file_target_selected)


func _on_create_new_file_pressed() -> void:
	if _add_file_dialog == null:
		return

	_add_file_dialog.current_path = _get_default_add_target_path()
	_add_file_dialog.popup_centered_ratio(0.75)


func _on_new_file_target_selected(raw_path: String) -> void:
	var target_path = _normalize_resource_json_path(raw_path)
	var result = _create_json_file_from_schema(target_path)
	if not bool(result.get("ok", false)):
		_set_status_message(str(result.get("message", "파일 생성 실패")), Color(1.0, 0.55, 0.55), 3.5)
		return

	file_system.refresh_tree(package_path)
	editor.load_json_data(target_path)

	var status_text = "새 파일 생성됨: %s" % target_path
	var schema_name = str(result.get("schema_name", ""))
	if bool(result.get("schema_found", false)) and not schema_name.is_empty():
		status_text = "새 파일 생성됨 (%s 스키마): %s" % [schema_name, target_path]
	elif not schema_name.is_empty():
		status_text = "새 파일 생성됨 (스키마 없음): %s" % target_path

	_set_status_message(status_text, Color(0.56, 0.92, 0.62), 3.0)


func _normalize_resource_json_path(raw_path: String) -> String:
	var localized_path = ProjectSettings.localize_path(raw_path)
	var normalized_path = localized_path if not localized_path.is_empty() else raw_path
	if not normalized_path.ends_with(".json"):
		normalized_path += ".json"
	return normalized_path


func _get_default_add_target_path() -> String:
	var base_dir = package_path
	var selected_item = file_system.get_selected()
	if selected_item != null:
		var selected_path = str(selected_item.get_metadata(0))
		if not selected_path.is_empty():
			base_dir = selected_path.get_base_dir() if FileAccess.file_exists(selected_path) else selected_path

	var candidate = base_dir.path_join("new_data.json")
	var serial = 1
	while FileAccess.file_exists(candidate):
		candidate = base_dir.path_join("new_data_%d.json" % serial)
		serial += 1

	return candidate


func _create_json_file_from_schema(target_path: String) -> Dictionary:
	if not target_path.begins_with("res://"):
		return {"ok": false, "message": "프로젝트 내부(res://) 경로만 생성할 수 있습니다."}

	if FileAccess.file_exists(target_path):
		return {"ok": false, "message": "이미 존재하는 파일입니다: %s" % target_path}

	var target_dir = target_path.get_base_dir()
	if DirAccess.open(target_dir) == null:
		return {"ok": false, "message": "선택한 폴더를 열 수 없습니다: %s" % target_dir}

	var schema_info = _detect_schema_for_data_path(target_path)
	var schema_data: Dictionary = schema_info.get("schema", {})
	var initial_data = _build_new_file_data(schema_data)

	var file = FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "파일을 생성할 수 없습니다: %s" % target_path}

	file.store_string(JSON.stringify(initial_data, "\t", false) + "\n")
	file.close()

	return {
		"ok": true,
		"path": target_path,
		"schema_name": str(schema_info.get("schema_name", "")),
		"schema_found": bool(schema_info.get("schema_found", false))
	}


func _detect_schema_for_data_path(data_path: String) -> Dictionary:
	var primary_name = PathUtils.get_primary_data_name(data_path)
	if primary_name.is_empty():
		return {"schema_name": "", "schema_found": false, "schema": {}}

	var schema_path = "res://addons/data_editor/schemas/%s.json" % primary_name
	if not FileAccess.file_exists(schema_path):
		return {"schema_name": primary_name, "schema_found": false, "schema": {}}

	var loaded = _load_schema_dictionary(schema_path)
	if not bool(loaded.get("ok", false)):
		return {"schema_name": primary_name, "schema_found": false, "schema": {}}

	return {
		"schema_name": primary_name,
		"schema_found": true,
		"schema": loaded.get("schema", {})
	}


func _load_schema_dictionary(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "schema": {}}

	var json_text = file.get_as_text()
	file.close()

	var parser = JSON.new()
	var parse_result = parser.parse(json_text)
	if parse_result != OK or not (parser.data is Dictionary):
		return {"ok": false, "schema": {}}

	return {"ok": true, "schema": parser.data}


func _build_new_file_data(schema: Dictionary) -> Variant:
	# 스키마가 있으면 default 구조를 만들고, 없으면 빈 object로 시작합니다.
	if schema.is_empty():
		return {}

	var root_schema = SchemaUtils.build_root_schema(schema, {})
	var default_info = SchemaUtils.get_schema_default_info(root_schema)
	if bool(default_info.get("has_default", false)):
		return default_info.get("value")

	var fallback = SchemaUtils.get_missing_placeholder(root_schema)
	return {} if fallback == null else fallback


func _setup_view_mode_selector() -> void:
	# 보기 모드는 코드에서 생성해도 충분하므로 scene 구조를 단순하게 유지합니다.
	var top_bar = get_node_or_null("VBoxContainer/TopBar/MarginContainer/HBoxContainer") as HBoxContainer
	if top_bar == null:
		return

	var search = top_bar.get_node_or_null("Search") as LineEdit

	_view_mode_selector = OptionButton.new()
	_view_mode_selector.name = "ViewMode"
	_view_mode_selector.custom_minimum_size = Vector2(120, 0)
	_view_mode_selector.add_item("간단 모드", 0)
	_view_mode_selector.add_item("전체 모드", 1)
	_view_mode_selector.selected = 0
	_view_mode_selector.tooltip_text = "간단 모드: 파일에 없는 기본값 필드를 숨깁니다.\n전체 모드: 기본값 필드까지 모두 표시합니다."
	_view_mode_selector.item_selected.connect(_on_view_mode_selected)

	top_bar.add_child(_view_mode_selector)
	if search != null:
		# Search 앞에 배치해 상단바의 기존 흐름을 크게 바꾸지 않습니다.
		top_bar.move_child(_view_mode_selector, search.get_index())


func _on_view_mode_selected(index: int) -> void:
	# 0=간단 모드, 1=전체 모드 규약은 OptionButton item id와 맞춰 둡니다.
	editor.set_show_implicit_default_fields(index == 1)

func load_package(path: String):
	# 패키지 경로를 업데이트하고 트리를 새로 고칩니다.
	package_path = path
	file_system.refresh_tree(package_path)
	_refresh_header_text()
	print("Package loaded: ", package_path)


func _on_editor_file_loaded(path: String) -> void:
	# 파일을 새로 열면 header, 저장 버튼, 상태 문구를 함께 갱신합니다.
	_loaded_file_path = path
	_refresh_header_text()
	_update_save_button_state()
	_set_status_message("파일 로드됨", Color(0.72, 0.82, 1.0), 1.5)


func _on_editor_dirty_state_changed(_new_state: bool) -> void:
	# dirty 변화는 header의 * 표시와 저장 가능 상태에만 직접 연결합니다.
	_refresh_header_text()
	_update_save_button_state()


func _on_editor_file_saved(path: String) -> void:
	_loaded_file_path = path
	_refresh_header_text()
	_update_save_button_state()
	_set_status_message("저장됨", Color(0.56, 0.92, 0.62), 2.0)


func _on_editor_save_failed(message: String) -> void:
	_update_save_button_state()
	_set_status_message(message, Color(1.0, 0.55, 0.55), 3.0)


func _on_save_pressed() -> void:
	# editor.gd에서도 실패 signal을 보내지만, 반환값도 확인해 즉시 메시지를 띄웁니다.
	var result = editor.save_current_file()
	if not bool(result.get("ok", false)):
		_set_status_message(str(result.get("message", "저장 실패")), Color(1.0, 0.55, 0.55), 3.0)


func _refresh_header_text() -> void:
	# 파일 미선택 상태에서는 패키지 경로를, 선택 후에는 파일 경로와 dirty 표시를 보여 줍니다.
	if package_title == null:
		return

	if _loaded_file_path.is_empty():
		package_title.text = "Package: " + package_path
		return

	var label_text = "File: " + _loaded_file_path
	if editor.is_dirty:
		label_text += " *"
	package_title.text = label_text


func _update_save_button_state() -> void:
	# 현재는 파일이 선택된 경우에만 저장 버튼을 활성화합니다.
	if save_button == null:
		return

	save_button.disabled = _loaded_file_path.is_empty()


func _set_status_message(text: String, color: Color, clear_after: float = 0.0) -> void:
	# 로드/저장 결과를 상단 한 줄로 보여 주고 일정 시간이 지나면 자동으로 지웁니다.
	if _status_label == null:
		return

	# 이전 타이머의 지연 콜백이 최신 메시지를 지우지 못하도록 일련번호를 함께 비교합니다.
	_status_message_serial += 1
	var serial = _status_message_serial

	_status_label.text = text
	_status_label.modulate = color
	_status_label.visible = not text.is_empty()

	if clear_after <= 0.0:
		return

	await get_tree().create_timer(clear_after).timeout
	if not is_inside_tree():
		return
	if serial != _status_message_serial:
		return

	_status_label.text = ""
	_status_label.visible = false

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree():
			# 숨김 상태였다가 다시 보일 때 Tree/Inspector 레이아웃이 깨지지 않도록 갱신합니다.
			queue_redraw()


func _unhandled_input(event):
	# 단축키는 패널이 보이는 동안에만 가로채 다른 탭과 충돌하지 않게 합니다.
	if not is_visible_in_tree():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_S:
			get_viewport().set_input_as_handled()
			_on_save_pressed()

func _on_file_system_item_selected():
	# 파일 트리에서는 JSON 파일만 editor.gd로 넘기고 폴더/다른 확장자는 무시합니다.
	var selected_item = file_system.get_selected()
	var path = selected_item.get_metadata(0) # 메타데이터에서 경로 가져오기

	if not path:
		printerr("선택된 항목의 경로가 존재하지 않습니다.")
		return

	if FileAccess.file_exists(path) and path.ends_with(".json"):
		editor.load_json_data(path)
	else:
		print("선택된 항목이 유효한 JSON 파일이 아닙니다: ", path)

