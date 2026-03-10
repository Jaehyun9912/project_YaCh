@tool
class_name DE_EditorSchemaUtils
extends RefCounted


static func build_root_schema(schema: Dictionary, data: Variant) -> Dictionary:
	if schema.is_empty():
		return {}

	if is_schema_field_map(schema):
		# 데이터의 최상위 키가 ID 맵이면, 각 엔트리에 동일 스키마를 적용합니다.
		if data is Dictionary and looks_like_id_map(data) and not has_overlapping_keys(schema, data):
			return {
				"type": "map",
				"value_type": "object",
				"entry_schema": {"type": "object", "default": schema}
			}
		return {"type": "object", "default": schema}

	if schema.has("type"):
		return schema

	return {"type": "object", "default": schema}


static func lookup_schema_for_key(schema_map: Dictionary, raw_key: Variant) -> Variant:
	if schema_map.has(raw_key):
		return schema_map[raw_key]

	var key_text = str(raw_key)
	if schema_map.has(key_text):
		return schema_map[key_text]

	return {}


static func get_object_child_schema_map(schema_node: Variant) -> Dictionary:
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


static func schema_type(schema_node: Variant) -> String:
	if schema_node is Dictionary and schema_node.has("type"):
		return str(schema_node["type"])
	return ""


static func is_enum_schema_type(type_text: String) -> bool:
	return type_text.begins_with("enum:")


static func get_enum_options(type_text: String) -> PackedStringArray:
	var options := PackedStringArray()
	if not is_enum_schema_type(type_text):
		return options

	var raw_options = type_text.substr("enum:".length()).split(",", false)
	for raw_option in raw_options:
		var option_text = str(raw_option).strip_edges()
		if not option_text.is_empty():
			options.append(option_text)

	return options


static func is_schema_field_map(schema: Dictionary) -> bool:
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
	if data.is_empty():
		return false

	for raw_key in data.keys():
		if not (data[raw_key] is Dictionary):
			return false

	return true


static func has_overlapping_keys(schema_map: Dictionary, data: Dictionary) -> bool:
	for raw_key in data.keys():
		if schema_map.has(raw_key) or schema_map.has(str(raw_key)):
			return true

	return false
