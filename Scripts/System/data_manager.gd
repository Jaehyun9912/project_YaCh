extends Node

const DEFAULT_PATH = "res://Data/"

func get_data(data_path: String) -> Dictionary:
	var path = DEFAULT_PATH + data_path + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		return json.data
	else:
		print(json.get_error_message())
		return Dictionary()
	
func load_data(data_path: String) -> Dictionary:
	return Dictionary()
	
func save_data(save, data_path: String) -> void:
	pass
