@tool
class_name DE_Editor
extends Tree

const PathUtils = preload("res://addons/data_editor/scripts/editor_path_utils.gd")
const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")
const TreeRenderer = preload("res://addons/data_editor/scripts/editor_tree_renderer.gd")

# MainPanel과 Inspector는 이 신호들을 받아 현재 파일, 선택 항목, 저장 상태를 UI에 반영합니다.
signal item_selected_for_edit(meta: Dictionary)
signal file_loaded(path: String)
signal dirty_state_changed(is_dirty: bool)
signal file_saved(path: String)
signal save_failed(message: String)

# current_data는 편집 중인 실제 JSON 데이터이고, current_schema는 현재 파일에 대응하는 스키마입니다.
# show_implicit_default_fields는 "파일에 없는 기본값 필드"를 렌더링할지 결정합니다.
var current_data: Variant = {}
var current_schema: Dictionary = {}
var current_file_path: String = ""
var show_implicit_default_fields := false
var is_dirty := false


func _ready() -> void:
	# TreeRenderer가 KEY / TYPE / VALUE 3열을 전제로 동작하므로 초기화 시 먼저 맞춰 둡니다.
	TreeRenderer.configure_columns(self)
	hide_root = true
	select_mode = SELECT_ROW
	if not item_selected.is_connected(_on_item_selected):
		item_selected.connect(_on_item_selected)


func _get_tooltip(at_position: Vector2) -> String:
	# TreeItem에 컬럼별 tooltip이 있으면 그것을 우선 쓰고,
	# 없으면 key metadata에 저장한 comment를 보조 설명으로 사용합니다.
	var item = get_item_at_position(at_position)
	if item == null:
		return ""

	var column := get_column_at_position(at_position)
	if column < 0:
		column = 0

	var tooltip_text = item.get_tooltip_text(column)
	if tooltip_text.is_empty() and column != 0:
		tooltip_text = item.get_tooltip_text(0)
	if not tooltip_text.strip_edges().is_empty():
		return tooltip_text

	var key_meta = item.get_metadata(0)
	if key_meta is Dictionary:
		var fallback = str(key_meta.get("comment", ""))
		if not fallback.is_empty():
			return fallback

	return ""


# Editor 노드로, JSON 데이터를 로드하고 트리에 표시하는 기능을 담당합니다.
func load_json_data(path: String) -> void:
	# 파일 전환 시마다 컬럼 구성과 dirty 상태를 초기화해 이전 파일 상태가 섞이지 않게 합니다.
	TreeRenderer.configure_columns(self)

	var data = parse_json(path)
	if data == null:
		return
	current_data = data
	current_file_path = path
	_set_dirty(false)

	var root_folder = PathUtils.get_primary_data_name(path)
	if root_folder.is_empty():
		printerr("경로에 'Data' 이후 폴더가 없습니다: ", path)
		return

	# Data/하위 첫 폴더명을 스키마 이름으로 사용해 같은 규칙의 파일을 자동 연결합니다.
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

	# 렌더러 옵션은 Tree metadata를 통해 전달합니다.
	set_meta("_de_show_implicit_default_fields", show_implicit_default_fields)
	var root_schema = SchemaUtils.build_root_schema(schema, data)
	TreeRenderer.render_data(self, data, root_schema)
	file_loaded.emit(path)


func set_show_implicit_default_fields(show_all: bool) -> void:
	# 보기 모드 변경은 데이터 수정이 아니라 렌더링 정책 변경이므로 트리만 다시 그립니다.
	if show_implicit_default_fields == show_all:
		return

	show_implicit_default_fields = show_all
	set_meta("_de_show_implicit_default_fields", show_implicit_default_fields)
	if current_data != null:
		_refresh_tree_view()


func clear_editor() -> void:
	# 편집 중인 데이터와 경로를 모두 초기화하고 화면을 비웁니다.
	current_data = {}
	current_schema = {}
	current_file_path = ""
	_set_dirty(false)
	TreeRenderer.configure_columns(self)
	# root 가 숨겨져 있으므로 configure_columns 만으로도 비워집니다.


func _on_item_selected() -> void:
	# 컬럼 2 metadata에는 Inspector가 바로 사용할 path, expected_type, default 정보가 들어 있습니다.
	var selected_item = get_selected()
	if selected_item == null:
		return
	var meta = selected_item.get_metadata(2)
	if meta is Dictionary:
		item_selected_for_edit.emit(meta)


func apply_external_edit(path: Array, new_value: Variant, edit_options: Dictionary = {}) -> void:
	# Inspector 입력값을 path 위치에 그대로 반영합니다.
	# 기본값이라도 키를 생략하지 않고 항상 명시적으로 저장합니다.
	if path.is_empty():
		# 루트 값 전체 교체(예: root array append)는 경로 탐색 없이 바로 반영합니다.
		current_data = new_value
		_set_dirty(true)
		_refresh_tree_view()
		return

	if not _set_value_by_path(current_data, path, new_value):
		printerr("값 반영 실패: 경로를 찾을 수 없습니다.")
		return

	_set_dirty(true)
	_refresh_tree_view()


func delete_entry(path: Array) -> Dictionary:
	# 배열 원소(index) 또는 map 엔트리(key)를 한 단계만 삭제합니다.
	if path.is_empty():
		return {"ok": false, "message": "루트는 삭제할 수 없습니다."}

	var parent_path = path.slice(0, path.size() - 1)
	var target_key = path[path.size() - 1]
	var parent_node: Variant = current_data if parent_path.is_empty() else _get_value_by_path(current_data, parent_path)

	if parent_node is Array:
		if not (target_key is int):
			return {"ok": false, "message": "배열 인덱스가 아닙니다."}

		var parent_array: Array = parent_node
		var index: int = target_key
		if index < 0 or index >= parent_array.size():
			return {"ok": false, "message": "배열 인덱스 범위를 벗어났습니다."}

		parent_array.remove_at(index)
		_set_dirty(true)
		_refresh_tree_view()
		return {"ok": true, "message": "배열 원소 삭제 완료"}

	if parent_node is Dictionary:
		var parent_dict: Dictionary = parent_node
		var resolved_key = target_key
		if not parent_dict.has(resolved_key):
			var key_text = str(target_key)
			if parent_dict.has(key_text):
				resolved_key = key_text
			else:
				return {"ok": false, "message": "삭제할 key를 찾을 수 없습니다."}

		parent_dict.erase(resolved_key)
		_set_dirty(true)
		_refresh_tree_view()
		return {"ok": true, "message": "map 엔트리 삭제 완료"}

	return {"ok": false, "message": "상위 항목이 배열/map이 아닙니다."}


func rename_map_key(path: Array, new_key: String) -> Dictionary:
	# path 마지막 키를 같은 부모 Dictionary 안에서 새 이름으로 교체합니다.
	if path.is_empty():
		return {"ok": false, "message": "루트 key는 변경할 수 없습니다."}

	var trimmed_new_key = new_key.strip_edges()
	if trimmed_new_key.is_empty():
		return {"ok": false, "message": "새 key 이름이 비어 있습니다."}

	var parent_path = path.slice(0, path.size() - 1)
	var old_key = path[path.size() - 1]
	var parent_node: Variant = current_data if parent_path.is_empty() else _get_value_by_path(current_data, parent_path)
	if not (parent_node is Dictionary):
		return {"ok": false, "message": "상위 항목이 map(Dictionary)이 아닙니다."}

	var parent_dict: Dictionary = parent_node
	var resolved_old_key = old_key
	if not parent_dict.has(resolved_old_key):
		var old_key_text = str(old_key)
		if parent_dict.has(old_key_text):
			resolved_old_key = old_key_text
		else:
			return {"ok": false, "message": "기존 key를 찾을 수 없습니다."}

	if str(resolved_old_key) == trimmed_new_key:
		return {"ok": false, "message": "같은 key 이름입니다."}

	if parent_dict.has(trimmed_new_key):
		return {"ok": false, "message": "이미 존재하는 key입니다: %s" % trimmed_new_key}

	if not _rename_dictionary_key_preserve_order(parent_dict, resolved_old_key, trimmed_new_key):
		return {"ok": false, "message": "key 변경에 실패했습니다."}

	_set_dirty(true)
	_refresh_tree_view()
	return {
		"ok": true,
		"message": "key 변경 완료",
		"old_key": str(resolved_old_key),
		"new_key": trimmed_new_key
	}


func save_current_file() -> Dictionary:
	# 저장은 항상 current_data를 직렬화해 전체 파일을 다시 쓰는 방식으로 단순화합니다.
	# 부분 저장을 하지 않기 때문에 트리에 보이는 상태와 디스크의 내용이 어긋날 가능성이 줄어듭니다.
	if current_file_path.is_empty():
		var no_file_message = "저장할 파일이 선택되지 않았습니다."
		save_failed.emit(no_file_message)
		return {"ok": false, "message": no_file_message}

	var file = FileAccess.open(current_file_path, FileAccess.WRITE)
	if file == null:
		var open_fail_message = "파일을 쓰기 모드로 열 수 없습니다: %s" % current_file_path
		save_failed.emit(open_fail_message)
		return {"ok": false, "message": open_fail_message}

	var json_text = JSON.stringify(current_data, "\t", false)
	file.store_string(json_text + "\n")
	file.close()

	_set_dirty(false)
	file_saved.emit(current_file_path)
	return {"ok": true, "message": "저장 완료", "path": current_file_path}


func _set_dirty(value: bool) -> void:
	# 상태가 실제로 바뀔 때만 신호를 내보내 UI 갱신과 상태 메시지 중복을 줄입니다.
	if is_dirty == value:
		return

	is_dirty = value
	dirty_state_changed.emit(is_dirty)


func _refresh_tree_view() -> void:
	# default/optional 표시는 형제 필드와도 연관되므로 부분 갱신보다 전체 재렌더가 더 안전합니다.
	var root_schema = SchemaUtils.build_root_schema(current_schema, current_data)
	TreeRenderer.render_data(self, current_data, root_schema)


func _update_item_display_by_path(parent: TreeItem, path: Array, depth: int, new_value: Variant) -> bool:
	# 현재는 전체 refresh를 사용하지만, 이후 최적화 시 재활용할 수 있게 path 기반 갱신 로직을 남겨 둡니다.
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


func _get_value_by_path(root: Variant, path: Array) -> Variant:
	# path로 부모 노드를 찾아 key 변경 같은 구조 편집에 재사용합니다.
	var node: Variant = root
	for raw_key in path:
		if node is Dictionary:
			var dict_node: Dictionary = node
			var resolved_key = raw_key
			if not dict_node.has(resolved_key):
				var string_key = str(raw_key)
				if dict_node.has(string_key):
					resolved_key = string_key
				else:
					return null
			node = dict_node[resolved_key]
			continue

		if node is Array:
			if not (raw_key is int):
				return null

			var array_node: Array = node
			var index: int = raw_key
			if index < 0 or index >= array_node.size():
				return null
			node = array_node[index]
			continue

		return null

	return node


func _rename_dictionary_key_preserve_order(dict_node: Dictionary, old_key: Variant, new_key: String) -> bool:
	# Dictionary 순서를 유지하려고 재구성 방식으로 key를 교체합니다.
	if not dict_node.has(old_key):
		return false

	var rebuilt := {}
	for existing_key in dict_node.keys():
		if existing_key == old_key:
			rebuilt[new_key] = dict_node[existing_key]
		else:
			rebuilt[existing_key] = dict_node[existing_key]

	dict_node.clear()
	for rebuilt_key in rebuilt.keys():
		dict_node[rebuilt_key] = rebuilt[rebuilt_key]

	return true


func _set_value_by_path(root: Variant, path: Variant, new_value: Variant) -> bool:
	# 외부에서 들어온 path 타입을 먼저 확인해 재귀 함수는 순수 탐색/기록에만 집중하게 합니다.
	if not (path is Array):
		return false

	var typed_path: Array = path
	if typed_path.is_empty():
		return false

	return _set_value_by_path_recursive(root, typed_path, 0, new_value)


func _set_value_by_path_recursive(node: Variant, path: Array, depth: int, new_value: Variant) -> bool:
	# path는 ["requirements", "condition", "stat"] 또는 ["actions", 0, "chance"] 같은 형태입니다.
	if depth >= path.size():
		return false

	var key = path[depth]
	var is_last = depth == path.size() - 1

	if node is Dictionary:
		var dict_node: Dictionary = node
		var resolved_key = key

		if not dict_node.has(resolved_key):
			var string_key = str(key)
			if dict_node.has(string_key):
				resolved_key = string_key
			elif is_last:
				# 마지막 단계면 키가 없어도 새 값을 그대로 생성할 수 있습니다.
				dict_node[resolved_key] = new_value
				return true
			else:
				# 중간 경로가 비어 있으면 다음 path 타입에 맞춰 Dictionary/Array를 자동 생성합니다.
				var next_key = path[depth + 1]
				dict_node[resolved_key] = [] if next_key is int else {}

		if is_last:
			dict_node[resolved_key] = new_value
			return true

		return _set_value_by_path_recursive(dict_node[resolved_key], path, depth + 1, new_value)

	if node is Array:
		if not (key is int):
			return false

		var array_node: Array = node
		var index: int = key
		if index < 0:
			return false

		if index >= array_node.size():
			if index != array_node.size():
				return false

			if is_last:
				# 배열 끝 index를 지정한 경우 append로 자연스럽게 확장합니다.
				array_node.append(new_value)
				return true

			var next_key = path[depth + 1]
			array_node.append([] if next_key is int else {})

		if index < 0 or index >= array_node.size():
			return false

		if is_last:
			array_node[index] = new_value
			return true

		return _set_value_by_path_recursive(array_node[index], path, depth + 1, new_value)

	return false


func _remove_value_by_path(root: Variant, path: Array) -> bool:
	# 기본값 생략 기능은 결국 JSON key 제거이므로 별도 삭제 helper를 둡니다.
	if path.is_empty():
		return false

	return _remove_value_by_path_recursive(root, path, 0)


func _remove_value_by_path_recursive(node: Variant, path: Array, depth: int) -> bool:
	# 삭제 뒤 비어 버린 부모 object/array도 함께 정리해 의미 없는 빈 구조가 남지 않게 합니다.
	if depth >= path.size():
		return false

	var key = path[depth]
	var is_last = depth == path.size() - 1

	if node is Dictionary:
		var dict_node: Dictionary = node
		var resolved_key = key

		if not dict_node.has(resolved_key):
			var string_key = str(key)
			if dict_node.has(string_key):
				resolved_key = string_key
			else:
				return false

		if is_last:
			dict_node.erase(resolved_key)
			return true

		if not _remove_value_by_path_recursive(dict_node[resolved_key], path, depth + 1):
			return false

		if dict_node.has(resolved_key):
			# 자식이 빈 컨테이너가 되면 부모 키도 제거해 optional object가 자연스럽게 접히게 합니다.
			var child = dict_node[resolved_key]
			if child is Dictionary and child.is_empty():
				dict_node.erase(resolved_key)
			elif child is Array and child.is_empty():
				dict_node.erase(resolved_key)

		return true

	if node is Array:
		if not (key is int):
			return false

		var array_node: Array = node
		var index: int = key

		if index < 0 or index >= array_node.size():
			return false

		if is_last:
			array_node.remove_at(index)
			return true

		if not _remove_value_by_path_recursive(array_node[index], path, depth + 1):
			return false

		if index >= 0 and index < array_node.size():
			# 배열 내부의 빈 object/array도 함께 정리해 저장 결과를 최대한 간결하게 유지합니다.
			var child = array_node[index]
			if child is Dictionary and child.is_empty():
				array_node.remove_at(index)
			elif child is Array and child.is_empty():
				array_node.remove_at(index)

		return true

	return false



# JSON 파일을 파싱하여 Variant로 반환하는 함수
func parse_json(path: String) -> Variant:
	# data 파일과 schema 파일 모두 같은 파서를 사용해 오류 메시지 형식을 통일합니다.
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
