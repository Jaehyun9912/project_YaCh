@tool
class_name DE_EditorSchemaUtils
extends RefCounted


static func build_root_schema(schema: Dictionary, data: Variant) -> Dictionary:
	# 최상위 데이터가 ID -> object 맵처럼 보이면 object 목록으로 취급해 동일 스키마를 반복 적용합니다.
	# 예를 들어 skill ID -> skill 데이터 구조라면 각 skill 엔트리에 같은 스키마를 공통 적용합니다.
	if schema.is_empty():
		return {}

	if schema.has("type"):
		var root_type = str(schema.get("type", ""))
		if root_type == "array" and data is Dictionary and looks_like_id_map(data):
			# 루트를 array로 선언해도 기존 ID -> object 파일은 map으로 호환 렌더링합니다.
			var item_schema = get_array_item_schema(schema)
			var item_field_map = get_object_child_schema_map(item_schema)
			if item_field_map.is_empty() or not has_overlapping_keys(item_field_map, data):
				return {
					"type": "map",
					"value_type": "object",
					"entry_schema": item_schema if item_schema is Dictionary else {"type": "object", "default": {}}
				}

		return schema

	if is_schema_field_map(schema):
		# 데이터의 최상위 키가 ID 맵이면, 각 엔트리에 동일 스키마를 적용합니다.
		if data is Dictionary and looks_like_id_map(data) and not has_overlapping_keys(schema, data):
			return {
				"type": "map",
				"value_type": "object",
				"entry_schema": {"type": "object", "default": schema}
			}
		return {"type": "object", "default": schema}

	return {"type": "object", "default": schema}


static func lookup_schema_for_key(schema_map: Dictionary, raw_key: Variant) -> Variant:
	# JSON 키는 문자열로 다루는 경우가 많지만, 실제 데이터 쪽 키 타입 차이도 흡수합니다.
	if schema_map.has(raw_key):
		return schema_map[raw_key]

	var key_text = str(raw_key)
	if schema_map.has(key_text):
		return schema_map[key_text]

	return {}


static func get_object_child_schema_map(schema_node: Variant) -> Dictionary:
	# object 스키마는 축약형 field map과 {type:"object", default:field map} 두 형태를 모두 허용합니다.
	if not (schema_node is Dictionary):
		return {}

	if schema_node.has("default") and schema_node["default"] is Dictionary:
		var default_dict: Dictionary = schema_node["default"]
		if is_schema_field_map(default_dict):
			return default_dict

	if is_schema_field_map(schema_node):
		return schema_node

	return {}


static func get_array_item_schema(schema_node: Variant) -> Variant:
	# 배열 아이템도 object field map 축약형을 허용해 schema JSON의 중첩을 줄입니다.
	if not (schema_node is Dictionary):
		return {}

	if schema_node.has("item_schema") and schema_node["item_schema"] is Dictionary:
		var item_schema: Dictionary = schema_node["item_schema"]
		if item_schema.has("type"):
			return item_schema
		if is_schema_field_map(item_schema):
			return {"type": "object", "default": item_schema}

	return {}


static func get_map_entry_schema(schema_node: Variant) -> Variant:
	# map은 key보다 value 구조가 중요하므로 entry_schema 또는 value_type만 해석합니다.
	if not (schema_node is Dictionary):
		return {}

	if schema_node.has("entry_schema"):
		return schema_node["entry_schema"]

	var value_type = str(schema_node.get("value_type", ""))
	if value_type.is_empty() or value_type == "any":
		return {}
	if value_type == "object":
		return {"type": "object", "default": {}}

	return {"type": value_type}


static func get_schema_default_info(schema_node: Variant) -> Dictionary:
	# 렌더러와 Inspector가 동일한 인터페이스로 기본값을 읽도록 {has_default, value} 형태로 정규화합니다.
	if not (schema_node is Dictionary):
		return {"has_default": false, "value": null}

	var schema_dict: Dictionary = schema_node
	var type_text = schema_type(schema_dict)

	if schema_dict.has("default"):
		var raw_default = schema_dict["default"]
		# object의 default는 실제 기본값일 수도 있고, 자식 필드 스키마 맵일 수도 있습니다.
		if type_text == "object" and raw_default is Dictionary and is_schema_field_map(raw_default):
			return {"has_default": true, "value": _build_default_object_from_field_map(raw_default)}
		return {"has_default": true, "value": _duplicate_variant(raw_default)}

	if type_text == "object":
		var field_map = get_object_child_schema_map(schema_dict)
		if not field_map.is_empty():
			return {"has_default": true, "value": _build_default_object_from_field_map(field_map)}

	return {"has_default": false, "value": null}


static func can_omit_field(schema_node: Variant) -> bool:
	# "생략 가능"은 default가 있다는 사실만으로 결정하지 않고 optional 의미까지 함께 반영합니다.
	if not (schema_node is Dictionary):
		return false

	var schema_dict: Dictionary = schema_node
	if schema_dict.has("optional"):
		return bool(schema_dict["optional"])

	if not schema_dict.has("default"):
		return false

	var type_text = schema_type(schema_dict)
	var raw_default = schema_dict["default"]

	# object의 default가 "필드 스키마 맵"인 경우는 실제 기본값이 아니라 구조 설명이므로
	# optional이 명시되지 않으면 기본적으로 필수로 간주합니다.
	if type_text == "object" and raw_default is Dictionary and is_schema_field_map(raw_default):
		return false

	return true


static func get_missing_placeholder(schema_node: Variant) -> Variant:
	# 파일에 없는 항목을 화면에 임시 표시할 때 사용할 값입니다.
	# 사용자가 실제로 수정하거나 저장 규칙이 바뀌기 전까지는 JSON 본문에 기록되지 않습니다.
	var type_text = schema_type(schema_node)

	if is_enum_schema(schema_node):
		var options = get_schema_enum_options(schema_node)
		if options.size() > 0:
			return options[0]
		return ""

	match type_text:
		"object", "map":
			return {}
		"array":
			return []
		"string", "path":
			return ""
		"number", "int", "float":
			return 0
		"bool", "boolean":
			return false
		_:
			return null


static func _build_default_object_from_field_map(field_map: Dictionary) -> Dictionary:
	# object 자식들의 default를 재귀적으로 조합해 "가상 기본 object"를 만듭니다.
	var result := {}

	for raw_key in field_map.keys():
		var child_info = get_schema_default_info(field_map[raw_key])
		if bool(child_info.get("has_default", false)):
			result[str(raw_key)] = child_info.get("value")

	return result


static func _duplicate_variant(value: Variant) -> Variant:
	# Array/Dictionary 기본값은 참조를 공유하면 원본 스키마까지 오염될 수 있어 deep copy 합니다.
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func schema_type(schema_node: Variant) -> String:
	if schema_node is Dictionary and schema_node.has("type"):
		return str(schema_node["type"])
	return ""


static func is_enum_schema(schema_node: Variant) -> bool:
	# 호출부가 schema 전체를 넘기든 type 문자열만 넘기든 같은 규칙으로 판별하게 합니다.
	if schema_node is Dictionary:
		return is_enum_schema_type(schema_type(schema_node))
	if schema_node is String:
		return is_enum_schema_type(str(schema_node))
	return false


static func is_enum_schema_type(type_text: String) -> bool:
	return type_text.begins_with("enum:")


static func get_enum_options(type_text: String) -> PackedStringArray:
	# "enum:a,b,c" 포맷의 문자열에서 순서를 보존한 옵션 목록을 추출합니다.
	var options := PackedStringArray()
	if not is_enum_schema_type(type_text):
		return options

	var raw_options = type_text.substr("enum:".length()).split(",", false)
	for raw_option in raw_options:
		var option_text = str(raw_option).strip_edges()
		if not option_text.is_empty():
			options.append(option_text)

	return options


static func get_schema_enum_options(schema_node: Variant) -> PackedStringArray:
	# enum 옵션은 세 소스를 합칩니다.
	# 1) type 안의 enum:...
	# 2) enum_options 배열
	# 3) enum_append_keys_from로 지정한 외부 JSON의 최상위 key 목록
	if schema_node is String:
		return get_enum_options(str(schema_node))

	var options := PackedStringArray()
	if not (schema_node is Dictionary):
		return options

	var schema_dict: Dictionary = schema_node
	_append_unique_options(options, get_enum_options(schema_type(schema_dict)))

	var inline_options = schema_dict.get("enum_options", [])
	if inline_options is Array:
		_append_unique_options(options, inline_options)

	# 파일 기반 enum 소스를 추가로 붙여서 stat / element 같은 값 목록을 데이터에서 직접 읽습니다.
	var source_path = str(schema_dict.get("enum_append_keys_from", "")).strip_edges()
	if not source_path.is_empty():
		_append_unique_options(options, _load_json_dict_keys(source_path))

	return options


static func _append_unique_options(target: PackedStringArray, raw_options: Variant) -> void:
	# 여러 소스에서 읽은 옵션을 합칠 때 중복은 제거하고 첫 등장 순서는 유지합니다.
	if raw_options is PackedStringArray:
		for option in raw_options:
			var option_text = str(option).strip_edges()
			if not option_text.is_empty() and not target.has(option_text):
				target.append(option_text)
		return

	if raw_options is Array:
		for option in raw_options:
			var option_text = str(option).strip_edges()
			if not option_text.is_empty() and not target.has(option_text):
				target.append(option_text)


static func _load_json_dict_keys(path: String) -> PackedStringArray:
	# 동적 enum 소스를 읽다가 실패해도 전체 에디터는 계속 동작하도록 빈 목록을 반환합니다.
	var keys := PackedStringArray()
	if path.is_empty() or not FileAccess.file_exists(path):
		return keys

	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return keys

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	if error != OK:
		return keys

	# 동적 enum은 최상위 Dictionary key 목록만 필요하므로 값 자체는 읽지 않습니다.
	if json.data is Dictionary:
		for raw_key in (json.data as Dictionary).keys():
			var key_text = str(raw_key).strip_edges()
			if not key_text.is_empty() and not keys.has(key_text):
				keys.append(key_text)

	return keys


static func is_schema_field_map(schema: Dictionary) -> bool:
	# field map은 모든 값이 {type: ...} 형태의 Dictionary인 구조를 의미합니다.
	if schema.is_empty():
		return false

	for raw_key in schema.keys():
		var field = schema[raw_key]
		if not (field is Dictionary):
			return false
		if not field.has("type"):
			return false

	return true


static func looks_like_id_map(data: Dictionary) -> bool:
	# value가 전부 object라면 ID -> object 모음일 가능성이 높다고 보는 단순 휴리스틱입니다.
	if data.is_empty():
		return false

	for raw_key in data.keys():
		if not (data[raw_key] is Dictionary):
			return false

	return true


static func has_overlapping_keys(schema_map: Dictionary, data: Dictionary) -> bool:
	# 데이터 키와 스키마 필드명이 겹치면 ID 맵이 아니라 일반 object일 가능성이 높습니다.
	for raw_key in data.keys():
		if schema_map.has(raw_key) or schema_map.has(str(raw_key)):
			return true

	return false
