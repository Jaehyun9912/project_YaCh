extends Node

const DEFAULT_PATH = "res://Data/"
const USER_PATH = "user://"

# 프로젝트의 Data 폴더에서 json 파일을 가져오는 함수
func get_data(data_path: String) -> Dictionary:
	var path = DEFAULT_PATH + data_path + ".json"
	if not FileAccess.file_exists(path):
		printerr("NoFileInPath")
		return Dictionary()
	var file = FileAccess.open(path, FileAccess.READ)
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		return json.data
	else:
		print(json.get_error_message())
		return Dictionary()
	
# 프로젝의 user 경로에서 json 파일을 가져오는 함수
func load_data(data_path: String) -> Dictionary:
	var path = USER_PATH + data_path + ".json"
	if not FileAccess.file_exists(path):
		print("NoFileInPath")
		return Dictionary()
		
	var file = FileAccess.open(path, FileAccess.READ)
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		return json.data
	else:
		print(json.get_error_message())
		return Dictionary()
	
	return Dictionary() 
	
# 프로젝트의 user 경로에 json 파일을 저장하는 함수
func save_data(save: Dictionary, data_path: String) -> void:
	var path = USER_PATH + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	
