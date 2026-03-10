@tool
class_name DE_EditorPathUtils
extends RefCounted


static func get_data_folder_parts(path: String) -> PackedStringArray:
	var folder_path = path.get_base_dir().replace("\\", "/")
	var parts = folder_path.split("/", false)
	var data_index = parts.find("Data")
	if data_index == -1 or data_index + 1 >= parts.size():
		return PackedStringArray()

	var result := PackedStringArray()
	for index in range(data_index + 1, parts.size()):
		result.append(parts[index])
	return result


static func get_primary_data_name(path: String) -> String:
	var folder_parts = get_data_folder_parts(path)
	if folder_parts.is_empty():
		return ""
	return folder_parts[0]
