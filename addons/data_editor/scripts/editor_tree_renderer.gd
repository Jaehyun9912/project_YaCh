@tool
class_name DE_EditorTreeRenderer
extends RefCounted

const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")


static func configure_columns(tree: Tree) -> void:
	tree.columns = 3
	tree.column_titles_visible = true
	tree.set_column_title(0, "KEY")
	tree.set_column_title(1, "TYPE")
	tree.set_column_title(2, "VALUE")

	# 0=Key, 1=Type, 2=Value
	tree.set_column_expand(0, true)
	tree.set_column_custom_minimum_width(0, 180)

	tree.set_column_expand(1, false)
	tree.set_column_custom_minimum_width(1, 120)

	tree.set_column_expand(2, true)
	tree.set_column_custom_minimum_width(2, 260)


static func render_data(tree: Tree, data: Variant, root_schema: Dictionary) -> void:
	tree.clear()
	var root = tree.create_item()
	var root_path: Array = []

	if data is Dictionary:
		_render_dictionary(tree, root, data, root_schema, root_path)
	elif data is Array:
		_render_array(tree, root, data, SchemaUtils.get_array_item_schema(root_schema), root_path)
	else:
		_add_value_item(tree, root, "value", data, root_schema, root_path)


static func _render_dictionary(tree: Tree, parent: TreeItem, data_dict: Dictionary, schema_node: Variant, base_path: Array) -> void:
	var child_schema_map = SchemaUtils.get_object_child_schema_map(schema_node)
	var is_map_schema = SchemaUtils.schema_type(schema_node) == "map"
	var map_entry_schema = SchemaUtils.get_map_entry_schema(schema_node)

	for raw_key in data_dict.keys():
		var value = data_dict[raw_key]
		var key_text = str(raw_key)
		var field_schema: Variant = {}
		var child_path = base_path.duplicate()
		child_path.append(raw_key)

		if is_map_schema:
			field_schema = map_entry_schema
		else:
			field_schema = SchemaUtils.lookup_schema_for_key(child_schema_map, raw_key)

		_add_value_item(tree, parent, key_text, value, field_schema, child_path)


static func _render_array(tree: Tree, parent: TreeItem, data_array: Array, item_schema: Variant, base_path: Array) -> void:
	for index in range(data_array.size()):
		var key_text = "[%d]" % index
		var child_path = base_path.duplicate()
		child_path.append(index)
		_add_value_item(tree, parent, key_text, data_array[index], item_schema, child_path)


static func _add_value_item(tree: Tree, parent: TreeItem, key_text: String, value: Variant, schema_node: Variant, value_path: Array) -> void:
	var item = tree.create_item(parent)
	item.set_text(0, key_text)

	var schema_type = SchemaUtils.schema_type(schema_node)
	var type_text = schema_type
	if SchemaUtils.is_enum_schema_type(schema_type):
		type_text = "enum"
	elif type_text.is_empty():
		type_text = _infer_value_type(value)
	item.set_text(1, type_text)
	_apply_type_color(item, type_text)

	if schema_node is Dictionary and schema_node.has("comment"):
		item.set_tooltip_text(0, str(schema_node["comment"]))

	if value is Dictionary:
		item.set_text(2, "{...}")
		_render_dictionary(tree, item, value, schema_node, value_path)
		return

	if value is Array:
		item.set_text(2, "[%d]" % value.size())
		_render_array(tree, item, value, SchemaUtils.get_array_item_schema(schema_node), value_path)
		return

	var expected_type = schema_type
	if expected_type.is_empty():
		expected_type = _infer_precise_type(value)

	var value_meta := {
		"path": value_path.duplicate(),
		"expected_type": expected_type,
		"last_value": value
	}

	if SchemaUtils.is_enum_schema_type(schema_type):
		value_meta["enum_options"] = SchemaUtils.get_enum_options(schema_type)

	item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
	item.set_editable(2, false)
	item.set_selectable(2, true)
	item.set_text(2, _value_to_text(value))
	item.set_metadata(2, value_meta)


static func _apply_type_color(item: TreeItem, type_text: String) -> void:
	var type_color = _get_type_color(type_text)
	item.set_custom_color(1, type_color)

	# VALUE 컬럼은 타입 색을 약하게 적용해 가독성을 유지합니다.
	var value_color = type_color.lerp(Color(1, 1, 1, 1), 0.35)
	item.set_custom_color(2, value_color)


static func _get_type_color(type_text: String) -> Color:
	var normalized_type = type_text.strip_edges().to_lower()

	if normalized_type.begins_with("enum:"):
		normalized_type = "enum"

	if normalized_type.contains("|"):
		normalized_type = normalized_type.get_slice("|", 0)

	match normalized_type:
		"string":
			return Color(0.36, 0.78, 0.98, 1.0)
		"number", "int", "float":
			return Color(0.98, 0.76, 0.34, 1.0)
		"bool", "boolean":
			return Color(0.47, 0.91, 0.56, 1.0)
		"enum":
			return Color(0.96, 0.56, 0.29, 1.0)
		"object", "map":
			return Color(0.71, 0.63, 0.98, 1.0)
		"array":
			return Color(0.90, 0.56, 0.86, 1.0)
		"null":
			return Color(0.62, 0.66, 0.70, 1.0)
		"any":
			return Color(0.86, 0.86, 0.86, 1.0)
		_:
			return Color(0.86, 0.86, 0.86, 1.0)



static func _value_to_text(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if value else "false"
		_:
			return str(value)


static func _infer_precise_type(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "string"
		TYPE_DICTIONARY:
			return "object"
		TYPE_ARRAY:
			return "array"
		_:
			return "any"


static func _infer_value_type(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool"
		TYPE_INT, TYPE_FLOAT:
			return "number"
		TYPE_STRING:
			return "string"
		TYPE_DICTIONARY:
			return "object"
		TYPE_ARRAY:
			return "array"
		_:
			return "any"
