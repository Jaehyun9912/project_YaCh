extends Node

const DEFAULT_PATH = "res://Data/"
const USER_PATH = "user://"

@onready var items = get_data("Item/item")
@onready var artifacts = get_data("Item/artifact")

# 프로젝트의 Data 폴더에서 json 파일을 가져오는 함수 (실패시 빈 딕셔너리 반환)
func get_data(data_path: String) -> Dictionary:
	var path = DEFAULT_PATH + data_path
	if not data_path.ends_with(".json"):
		path += ".json"
	
	# 경로에 파일이 없을 경우 빈 딕셔너리 반환 
	if not FileAccess.file_exists(path):
		printerr("NoFileInPath " + path)
		return Dictionary()
	var file = FileAccess.open(path, FileAccess.READ)
	
	# 불러온 파일을 JSON 파일로 변환시켜 반환.
	# 만약 반환에 실패할 경우 빈 딕셔너리를 반환함.
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	print(json.data)
	if error == OK:
		return json.data
	else:
		printerr(json.get_error_message())
		return Dictionary()
	
# 프로젝트의 Data 폴더에서 특정 폴더의 모든 json 파일을 읽어서 합쳐오는 함수
func get_data_folder(data_path: String) -> Dictionary:
	var path = DEFAULT_PATH + data_path
	var combined_data = {}

	# 파일 경로가 오면 파일 내용을 읽어 반환
	if FileAccess.file_exists(path):
		return get_data(data_path)

	# 폴더 경로가 오면 폴더를 열고 내용을 탐색
	var dir_access = DirAccess.open(path)
	if dir_access:
		dir_access.list_dir_begin()
		var file_or_dir_name = dir_access.get_next()
		
		while file_or_dir_name != "":
			# "."과 ".."은 건너뛰기 
			if file_or_dir_name == "." or file_or_dir_name == "..":
				file_or_dir_name = dir_access.get_next()
				continue
			
			# 현재 항목의 전체 경로
			var full_path = data_path.path_join(file_or_dir_name)
			#print(full_path)
			
			if dir_access.current_is_dir():
				# 폴더인지 확인해서 폴더라면 재귀
				var sub_folder_data = get_data_folder(full_path)
				combined_data.merge(sub_folder_data, true)
			else:
				# json 파일이면 읽기
				if full_path.ends_with(".json"):
					var file_data = get_data(full_path)
					combined_data.merge(file_data, true)
			
			file_or_dir_name = dir_access.get_next()
			
		dir_access.list_dir_end()
	else:
		print("Error: Could not open directory at path: ", data_path)
	
	return combined_data
		
	
# 프로젝의 user 경로에서 json 파일을 가져오는 함수 (실패시 빈 딕셔너리 반환)
func load_data(data_path: String) -> Dictionary:
	var path = USER_PATH + data_path + ".json"
	
	# 만약 불러오기에 실패할 경우 빈 딕셔너리를 반환함
	if not FileAccess.file_exists(path):
		printerr("NoFileInPath " + data_path)
		return Dictionary()
		
	var file = FileAccess.open(path, FileAccess.READ)
	
	# 불러온 파일을 JSON 파일로 변환시켜 반환.
	# 만약 반환에 실패할 경우 빈 딕셔너리를 반환함.
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		return json.data
	else:
		printerr(json.get_error_message())
		return Dictionary()
	
	
# 프로젝트의 user 경로에 json 파일을 저장하는 함수
func save_data(save: Dictionary, data_path: String) -> void:
	var path = USER_PATH + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
		
# 네임스페이스 관계 없이 아이템 정보 가져오기 
func get_item_artifact_data(id: String):
	var sp = id.split(":")
	if sp.size() == 1 or sp[0] == "item":
		return get_item_data(id)
	else:
		return get_artifact_data(id)
		
# 들어온 ID에 해당하는 아이템의 정보가 담긴 딕셔너리 반환 
func get_item_data(id : String) -> Dictionary:
	var sp = id.split(":")
	if sp.size() > 1 and sp[0] == "item":
		id = sp[1]
		
	if items.has(id):
		return items[id]
	else:
		printerr("잘못된 아이템 ID! : " + id)
		return Dictionary()
		
# 들어온 ID에 해당하는 아티팩트의 정보가 담긴 딕셔너리 반환 
func get_artifact_data(id : String) -> Dictionary:
	var sp = id.split(":")
	if sp.size() > 1 and sp[0] == "artifact":
		id = sp[1]
	
	if artifacts.has(id):
		return artifacts[id]
	else:
		printerr("잘못된 아티팩트 ID! : " + id)
		return Dictionary()
