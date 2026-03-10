@tool
class_name DE_Editor
extends Tree

const PathUtils = preload("res://addons/data_editor/scripts/editor_path_utils.gd")
const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")
const TreeRenderer = preload("res://addons/data_editor/scripts/editor_tree_renderer.gd")

signal item_selected_for_edit(meta: Dictionary)

var current_data: Variant = {}
var current_schema: Dictionary = {}
var current_file_path: String = ""


func _ready() -> void:
	TreeRenderer.configure_columns(self)
	hide_root = true
	select_mode = SELECT_ROW
	if not item_selected.is_connected(_on_item_selected):
		item_selected.connect(_on_item_selected)


# Editor 노드로, JSON 데이터를 로드하고 트리에 표시하는 기능을 담당합니다.
func load_json_data(path: String) -> void:
	TreeRenderer.configure_columns(self)

	var data = parse_json(path)
	if data == null:
		return
	current_data = data
	current_file_path = path

	var root_folder = PathUtils.get_primary_data_name(path)
	if root_folder.is_empty():
		printerr("경로에 'Data' 이후 폴더가 없습니다: ", path)
		return

	var schema_path = "res://addons/data_editor/schemas/%s.json" % root_folder
	var schema: Dictionary = {}
	if FileAccess.file_exists(schema_path):
		var parsed_schema = parse_json(schema_path)
		if parsed_schema is Dictionary:
			schema = parsed_schema
			current_schema = schema
		else:
			printerr("스키마 파일은 object(JSON Dictionary)여야 합니다: ", schema_path)
	else:
		print("스키마 파일이 없어 데이터 타입 추론으로 표시합니다: ", schema_path)
		current_schema = {}

	var root_schema = SchemaUtils.build_root_schema(schema, data)
	TreeRenderer.render_data(self, data, root_schema)


func _on_item_selected() -> void:
	var selected_item = get_selected()
	if selected_item == null:
		return
	var meta = selected_item.get_metadata(2)
	if meta is Dictionary:
		item_selected_for_edit.emit(meta)


func apply_external_edit(path: Array, new_value: Variant) -> void:
	if not _set_value_by_path(current_data, path, new_value):
		printerr("값 반영 실패: 경로를 찾을 수 없습니다.")
		return

	# 변경된 셀의 TreeItem을 찾아서 표시 텍스트만 업데이트합니다.
	_update_item_display_by_path(get_root(), path, 0, new_value)


func _update_item_display_by_path(parent: TreeItem, path: Array, depth: int, new_value: Variant) -> bool:
	if parent == null:
		return false

	var child = parent.get_first_child()
	while child != null:
		var meta = child.get_metadata(2)
		if meta is Dictionary and meta.get("path", []) == path:
			child.set_text(2, _variant_to_text(new_value))
			var meta_mut: Dictionary = meta.duplicate(true)
			meta_mut["last_value"] = new_value
			child.set_metadata(2, meta_mut)
			return true

		if _update_item_display_by_path(child, path, depth + 1, new_value):
			return true

		child = child.get_next()
	return false


func _variant_to_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL: return "null"
		TYPE_BOOL: return "true" if value else "false"
		_: return str(value)


func _set_value_by_path(root: Variant, path: Variant, new_value: Variant) -> bool:
	if not (path is Array):
		return false

	var typed_path: Array = path
	if typed_path.is_empty():
		return false

	return _set_value_by_path_recursive(root, typed_path, 0, new_value)


func _set_value_by_path_recursive(node: Variant, path: Array, depth: int, new_value: Variant) -> bool:
	if depth >= path.size():
		return false

	var key = path[depth]
	var is_last = depth == path.size() - 1

	if node is Dictionary:
		var dict_node: Dictionary = node
		if not dict_node.has(key):
			var string_key = str(key)
			if dict_node.has(string_key):
				key = string_key
			else:
				return false

		if is_last:
			dict_node[key] = new_value
			return true

		return _set_value_by_path_recursive(dict_node[key], path, depth + 1, new_value)

	if node is Array:
		if not (key is int):
			return false

		var array_node: Array = node
		var index: int = key
		if index < 0 or index >= array_node.size():
			return false

		if is_last:
			array_node[index] = new_value
			return true

		return _set_value_by_path_recursive(array_node[index], path, depth + 1, new_value)

	return false



# JSON 파일을 파싱하여 Variant로 반환하는 함수
func parse_json(path: String) -> Variant:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()

		var json = JSON.new()
		var json_error = json.parse(json_text)
		if json_error == OK:
			return json.data
		else:
			printerr("JSON 파싱 오류: ", json.error_string())
	else:
		printerr("파일을 열 수 없습니다: ", path)

	return {}
