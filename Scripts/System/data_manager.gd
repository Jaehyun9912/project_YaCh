extends Node

const DEFAULT_PATH = "res://Data/"
const USER_PATH = "user://"

@onready var skills = get_data("skill_info")
@onready var items = get_data("item")
@onready var artifacts = get_data("artifact")

# 프로젝트의 Data 폴더에서 json 파일을 가져오는 함수 (실패시 빈 딕셔너리 반환)
func get_data(data_path: String) -> Dictionary:
	var path = DEFAULT_PATH + data_path + ".json"
	
	# 경로에 파일이 없을 경우 빈 딕셔너리 반환 
	if not FileAccess.file_exists(path):
		printerr("NoFileInPath " + path)
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
	
	return Dictionary() 
	
# 프로젝트의 user 경로에 json 파일을 저장하는 함수
func save_data(save: Dictionary, data_path: String) -> void:
	var path = USER_PATH + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	
# 들어온 ID에 해당하는 스킬의 정보가 담긴 딕셔너리 반환 
func get_skill_data(id : String) -> Dictionary:
	if skills.has(id):
		return skills[id]
	else:
		printerr("잘못된 스킬 ID! : " + id)
		return Dictionary()
		
# 들어온 ID에 해당하는 아이템의 정보가 담긴 딕셔너리 반환 
func get_item_data(id : String) -> Dictionary:
	if items.has(id):
		return items[id]
	else:
		printerr("잘못된 아이템 ID! : " + id)
		return Dictionary()
		
# 들어온 ID에 해당하는 아티팩트의 정보가 담긴 딕셔너리 반환 
func get_artifact_data(id : String) -> Dictionary:
	if artifacts.has(id):
		return artifacts[id]
	else:
		printerr("잘못된 아티팩트 ID! : " + id)
		return Dictionary()
