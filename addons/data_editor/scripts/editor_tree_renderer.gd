@tool
class_name DE_EditorTreeRenderer
extends RefCounted

const SchemaUtils = preload("res://addons/data_editor/scripts/editor_schema_utils.gd")


static func configure_columns(tree: Tree) -> void:
	# 컬럼 구조는 tooltip, metadata, Inspector 연동의 기준이 되므로 한곳에서 고정합니다.
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
	# show_implicit_default_fields는 editor.gd가 Tree 메타데이터로 넘겨 준 렌더링 옵션입니다.
	# 루트 데이터 타입에 따라 Dictionary / Array / Scalar 진입점을 분기합니다.
	var show_implicit_default_fields = bool(tree.get_meta("_de_show_implicit_default_fields", true))
	tree.clear()
	var root = tree.create_item()
	var root_path: Array = []

	if data is Dictionary:
		_render_dictionary(tree, root, data, root_schema, root_path, false, show_implicit_default_fields)
	elif data is Array:
		# 루트가 배열일 때도 선택 가능한 컨테이너를 하나 두어 Inspector에서 원소 추가를 수행할 수 있게 합니다.
		_add_value_item(tree, root, "root", data, root_schema, root_path, {"has_explicit_value": true}, false, show_implicit_default_fields)
	else:
		_add_value_item(tree, root, "value", data, root_schema, root_path, {"has_explicit_value": true}, false, show_implicit_default_fields)


static func _render_dictionary(tree: Tree, parent: TreeItem, data_dict: Dictionary, schema_node: Variant, base_path: Array, parent_virtual_default: bool = false, show_implicit_default_fields: bool = true) -> void:
	# parent_virtual_default가 true면 상위 object 자체가 실제 파일에는 없고 기본값으로만 가상 렌더링 중이라는 뜻입니다.
	var child_schema_map = SchemaUtils.get_object_child_schema_map(schema_node)
	var is_map_schema = SchemaUtils.schema_type(schema_node) == "map"
	var map_entry_schema = SchemaUtils.get_map_entry_schema(schema_node)
	var rendered_schema_keys := {}

	if not is_map_schema and not child_schema_map.is_empty():
		# 스키마에만 있고 파일에는 없는 키도 기본값/placeholder 기반으로 렌더링할 수 있습니다.
		for raw_schema_key in child_schema_map.keys():
			var schema_key_text = str(raw_schema_key)
			var field_schema: Variant = child_schema_map[raw_schema_key]
			var child_path = base_path.duplicate()
			child_path.append(schema_key_text)

			var has_explicit_value := false
			var value: Variant = null

			if not parent_virtual_default:
				if data_dict.has(raw_schema_key):
					has_explicit_value = true
					value = data_dict[raw_schema_key]
					child_path[child_path.size() - 1] = raw_schema_key
				elif data_dict.has(schema_key_text):
					has_explicit_value = true
					value = data_dict[schema_key_text]

			var default_info = SchemaUtils.get_schema_default_info(field_schema)
			var has_default = bool(default_info.get("has_default", false))
			var default_value = default_info.get("value")
			var can_omit = SchemaUtils.can_omit_field(field_schema)

			if not has_explicit_value:
				# 간단 모드에서는 생략 가능하고 기본값이 있는 가상 필드만 숨깁니다.
				if has_default and can_omit and not show_implicit_default_fields:
					continue

				if has_default:
					value = default_value
				else:
					value = SchemaUtils.get_missing_placeholder(field_schema)

			# field_state는 텍스트, 색상, tooltip, Inspector metadata 생성에 공통으로 쓰입니다.
			var field_state := {
				"has_explicit_value": has_explicit_value,
				"has_default": has_default,
				"can_omit": can_omit,
				"default_value": default_value,
				"is_default_value": has_default and value == default_value
			}

			_add_value_item(tree, parent, schema_key_text, value, field_schema, child_path, field_state, parent_virtual_default, show_implicit_default_fields)
			rendered_schema_keys[schema_key_text] = true

	for raw_key in data_dict.keys():
		var key_text = str(raw_key)
		if not is_map_schema and rendered_schema_keys.has(key_text):
			continue

		var value = data_dict[raw_key]
		var field_schema: Variant = {}
		var child_path = base_path.duplicate()
		child_path.append(raw_key)

		if is_map_schema:
			field_schema = map_entry_schema
		else:
			field_schema = SchemaUtils.lookup_schema_for_key(child_schema_map, raw_key)

		var default_info = SchemaUtils.get_schema_default_info(field_schema)
		var has_default = bool(default_info.get("has_default", false))
		var default_value = default_info.get("value")
		var can_omit = SchemaUtils.can_omit_field(field_schema)

		var field_state := {
			"has_explicit_value": not parent_virtual_default,
			"has_default": has_default,
			"can_omit": can_omit,
			"default_value": default_value,
			"is_default_value": has_default and value == default_value
		}

		if is_map_schema:
			# map 엔트리는 key 변경 UI를 띄울 수 있도록 부모 경로/현재 key를 메타로 남깁니다.
			field_state["is_map_entry"] = true
			field_state["map_key"] = key_text
			field_state["map_parent_path"] = base_path.duplicate()

		_add_value_item(tree, parent, key_text, value, field_schema, child_path, field_state, parent_virtual_default, show_implicit_default_fields)


static func _render_array(tree: Tree, parent: TreeItem, data_array: Array, item_schema: Variant, base_path: Array, parent_virtual_default: bool = false, show_implicit_default_fields: bool = true) -> void:
	# 배열 항목은 index까지 path에 포함시켜 Inspector가 정확한 원소를 다시 찾을 수 있게 합니다.
	for index in range(data_array.size()):
		var key_text = "[%d]" % index
		var child_path = base_path.duplicate()
		child_path.append(index)

		var value = data_array[index]
		var default_info = SchemaUtils.get_schema_default_info(item_schema)
		var has_default = bool(default_info.get("has_default", false))
		var default_value = default_info.get("value")
		var can_omit = SchemaUtils.can_omit_field(item_schema)

		var field_state := {
			"has_explicit_value": not parent_virtual_default,
			"has_default": has_default,
			"can_omit": can_omit,
			"default_value": default_value,
			"is_default_value": has_default and value == default_value
		}
		field_state["is_array_entry"] = true

		_add_value_item(tree, parent, key_text, value, item_schema, child_path, field_state, parent_virtual_default, show_implicit_default_fields)


static func _add_value_item(tree: Tree, parent: TreeItem, key_text: String, value: Variant, schema_node: Variant, value_path: Array, field_state: Dictionary = {}, parent_virtual_default: bool = false, show_implicit_default_fields: bool = true) -> void:
	# TreeItem 하나가 곧 한 필드의 표시 상태와 편집 메타데이터를 함께 담는 단위입니다.
	var item = tree.create_item(parent)
	item.set_text(0, key_text)

	var schema_type = SchemaUtils.schema_type(schema_node)
	var type_text = schema_type
	if SchemaUtils.is_enum_schema(schema_node):
		type_text = "enum"
	elif type_text.is_empty():
		type_text = _infer_value_type(value)
	item.set_text(1, type_text)
	_apply_type_color(item, type_text)
	item.set_selectable(0, true)
	item.set_selectable(1, true)
	item.set_selectable(2, true)

	var has_explicit_value = bool(field_state.get("has_explicit_value", true))
	var has_default = bool(field_state.get("has_default", false))
	var can_omit = bool(field_state.get("can_omit", false))
	var default_value = field_state.get("default_value", null)
	var is_default_value = bool(field_state.get("is_default_value", false))
	var expected_type = schema_type
	if expected_type.is_empty():
		expected_type = _infer_precise_type(value)

	if has_default and not field_state.has("is_default_value"):
		is_default_value = value == default_value

	if has_default and not field_state.has("can_omit"):
		can_omit = SchemaUtils.can_omit_field(schema_node)

	var comment_text := ""

	var key_meta := {}
	if schema_node is Dictionary and schema_node.has("comment"):
		comment_text = str(schema_node["comment"])
		key_meta["comment"] = comment_text

	if has_default:
		key_meta["has_default"] = true
		key_meta["default_value"] = default_value
		key_meta["can_omit"] = can_omit

	if not key_meta.is_empty():
		item.set_metadata(0, key_meta)

	var tooltip_text = _build_tooltip_text(comment_text, has_default, can_omit, default_value, has_explicit_value)
	for column in range(tree.columns):
		item.set_tooltip_text(column, tooltip_text)

	# 원시 타입/복합 타입 모두 Inspector가 같은 인터페이스로 읽을 수 있도록 공통 메타를 구성합니다.
	var value_meta := {
		"path": value_path.duplicate(),
		"expected_type": expected_type,
		"last_value": _duplicate_variant(value),
		"has_explicit_value": has_explicit_value,
		"has_default": has_default,
		"can_omit": can_omit,
		"default_value": default_value,
		"is_default_value": is_default_value
	}

	if not comment_text.is_empty():
		value_meta["comment"] = comment_text

	if bool(field_state.get("is_map_entry", false)):
		value_meta["is_map_entry"] = true
		value_meta["map_key"] = str(field_state.get("map_key", key_text))
		var map_parent_path = field_state.get("map_parent_path", [])
		if map_parent_path is Array:
			value_meta["map_parent_path"] = (map_parent_path as Array).duplicate()

	if bool(field_state.get("is_array_entry", false)):
		value_meta["is_array_entry"] = true

	if SchemaUtils.is_enum_schema(schema_node):
		# 동적 enum 계산은 렌더 시 한 번만 수행하고 Inspector는 이 목록을 그대로 사용합니다.
		value_meta["enum_options"] = SchemaUtils.get_schema_enum_options(schema_node)

	if has_default and can_omit and not has_explicit_value:
		# 파일에 실제로 없는 가상 필드는 옅은 색으로 표시해 구분합니다.
		item.set_custom_color(0, Color(0.70, 0.70, 0.70, 1.0))

	if value is Dictionary:
		var object_text = "{...}"
		if has_default and is_default_value:
			object_text += " (default)"
		item.set_text(2, object_text)
		item.set_metadata(2, value_meta)

		# 자식도 같은 virtual default 상태를 이어받아 explicit 여부 판단이 일관되게 유지됩니다.
		var child_virtual_default = parent_virtual_default or not has_explicit_value
		_render_dictionary(tree, item, value, schema_node, value_path, child_virtual_default, show_implicit_default_fields)
		return

	if value is Array:
		var array_text = "[%d]" % value.size()
		if has_default and is_default_value:
			array_text += " (default)"
		item.set_text(2, array_text)

		var item_schema = SchemaUtils.get_array_item_schema(schema_node)
		if item_schema is Dictionary:
			value_meta["array_item_schema"] = item_schema
		item.set_metadata(2, value_meta)

		# 배열 자식 역시 부모의 virtual default 상태를 그대로 상속받습니다.
		var child_virtual_default = parent_virtual_default or not has_explicit_value
		_render_array(tree, item, value, item_schema, value_path, child_virtual_default, show_implicit_default_fields)
		return

	item.set_cell_mode(2, TreeItem.CELL_MODE_STRING)
	item.set_editable(2, false)
	item.set_selectable(2, true)
	var value_text = _value_to_text(value)
	if has_default and is_default_value:
		value_text += " (default)"
	item.set_text(2, value_text)

	if has_default and can_omit and not has_explicit_value:
		# VALUE 컬럼도 같은 톤으로 약하게 표시해 저장 전/후 차이를 바로 읽을 수 있게 합니다.
		item.set_custom_color(2, Color(0.74, 0.74, 0.74, 1.0))

	item.set_metadata(2, value_meta)


static func _duplicate_variant(value: Variant) -> Variant:
	# metadata로 전달되는 값이 Array/Dictionary면 deep copy해 Inspector 편집 중 원본 참조가 섞이지 않게 합니다.
	if value is Dictionary or value is Array:
		return value.duplicate(true)
	return value


static func _build_tooltip_text(comment_text: String, has_default: bool, can_omit: bool, default_value: Variant, has_explicit_value: bool) -> String:
	# tooltip은 "설명 + 기본값 + 현재 상태"를 합쳐 트리만 보고도 문맥이 보이게 하는 용도입니다.
	var parts := PackedStringArray()

	if not comment_text.is_empty():
		parts.append(comment_text)

	if has_default:
		var default_line = "기본값: %s" % _value_to_text(default_value)
		if can_omit:
			default_line += " (생략 가능)"
		parts.append(default_line)

		if can_omit and not has_explicit_value:
			parts.append("현재 파일에는 키가 없고 기본값이 적용됩니다.")
		elif not can_omit and not has_explicit_value:
			parts.append("필수 항목이며 현재 값은 기본 제안값으로 표시됩니다.")

	var tooltip_text = "\n".join(parts)
	if tooltip_text.is_empty():
		return " "

	return tooltip_text


static func _apply_type_color(item: TreeItem, type_text: String) -> void:
	# TYPE 컬럼은 선명하게, VALUE 컬럼은 옅게 칠해 정보 우선순위를 구분합니다.
	var type_color = _get_type_color(type_text)
	item.set_custom_color(1, type_color)

	# VALUE 컬럼은 타입 색을 약하게 적용해 가독성을 유지합니다.
	var value_color = type_color.lerp(Color(1, 1, 1, 1), 0.35)
	item.set_custom_color(2, value_color)


static func _get_type_color(type_text: String) -> Color:
	# enum:string 같은 파생 표기가 들어와도 실제 색상 분류는 대표 타입 기준으로 맞춥니다.
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
	# 트리 표기와 Inspector 표기를 맞춰 사용자가 값 변환 결과를 예측하기 쉽게 합니다.
	match typeof(value):
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "true" if value else "false"
		_:
			return str(value)


static func _infer_precise_type(value: Variant) -> String:
	# Inspector 편집 타입은 int/float 구분이 중요하므로 더 세밀한 타입명을 씁니다.
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
	# Tree TYPE 컬럼은 읽기 쉬운 범주가 중요하므로 int/float를 number로 묶습니다.
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
