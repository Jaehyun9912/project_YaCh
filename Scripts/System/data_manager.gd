extends Node

const DEFAULT_PATH = "res://Data/"
const USER_PATH = "user://"

# Item 리팩토링 이전 임시 리소스
# @onready var items = get_data_folder("Item")
# @onready var artifacts = get_data_folder("Item")

# 임시 리소스
@onready var enemy_data = load_datas_dict("Enemy", EnemyData)
@onready var battle_data = load_datas_dict("Battle", BattleData)
@onready var item_data = load_datas_dict("Item", ItemData)
@onready var quest_data = load_quest_data()

## 프로젝트의 Data 폴더에서 json 파일을 가져오는 함수 (실패시 null 반환)
func get_data(data_path: String):
	var path = DEFAULT_PATH + data_path
	if not data_path.ends_with(".json"):
		path += ".json"
	
	# 경로에 파일이 없을 경우 null 반환
	if not FileAccess.file_exists(path):
		printerr("NoFileInPath " + path)
		return null
	var file = FileAccess.open(path, FileAccess.READ)
	
	# 불러온 파일을 JSON 파일로 변환시켜 반환.
	# 만약 반환에 실패할 경우 null 반환
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		return json.data
	else:
		printerr(json.get_error_message())
		return null
	
## 프로젝트의 Data 폴더에서 특정 폴더의 모든 json 파일을 읽어서 합쳐오는 함수
func get_data_folder(data_path: String):
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
		
	
## 프로젝의 user 경로에서 json 파일을 가져오는 함수 (실패시 빈 딕셔너리 반환)
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

## 데이터 로드 함수
func create_data_dict(json: Dictionary, data_class: GDScript) -> Dictionary:
	if json == null:
		printerr("create_data_dict received null json!")
		return {}
	if not data_class.has_method("from_dict"):
		printerr("create_data_dict received invalid data_class: " + str(data_class))
		return {}

	var dict = {}
	for key in json:
		dict[key] = data_class.from_dict(key, json[key])
	return dict

## 데이터 로드 함수 (특정 폴더의 모든 json 파일을 읽어서 합쳐오는 함수)
func load_datas_dict(data_path: String, data_class: GDScript) -> Dictionary:
	var json_data = get_data_folder(data_path)
	if json_data != null:
		return create_data_dict(json_data, data_class)
	else:
		printerr("load_datas_dict failed to load data from: " + data_path)
		return {}

## 퀘스트 데이터를 로드하여 QuestData 객체로 캐싱하는 함수
func load_quest_data() -> Dictionary:
	var result = {}
	var path = DEFAULT_PATH + "Quest"
	
	if not DirAccess.dir_exists_absolute(path):
		printerr("Quest folder not found at: ", path)
		return {}

	var dir_access = DirAccess.open(path)
	if dir_access:
		dir_access.list_dir_begin()
		var file_name = dir_access.get_next()
		
		while file_name != "":
			if file_name == "." or file_name == "..":
				file_name = dir_access.get_next()
				continue
				
			if not dir_access.current_is_dir() and file_name.ends_with(".json"):
				var npc_name = file_name.replace(".json", "")
				var raw_data = get_data("Quest/" + npc_name)
				
				if raw_data:
					var parsed_npc_data = {}
					for key in raw_data:
						if typeof(raw_data[key]) == TYPE_ARRAY:
							var quest_list = []
							for q_dict in raw_data[key]:
								quest_list.append(QuestData.from_dict(q_dict))
							parsed_npc_data[key] = quest_list
						else:
							# guild ID 등 메타데이터 보존
							parsed_npc_data[key] = raw_data[key]
					result[npc_name] = parsed_npc_data
			
			file_name = dir_access.get_next()
		dir_access.list_dir_end()
	else:
		printerr("Failed to open Quest directory: ", path)
		
	return result
