extends Node

class_name Player
	
var data

var skill : Array[String] = ["none", "none","none","none"]

func _ready():
	load_player()

# data 저장 
func save_player(): 
	# skill정보 data에 저장 
	for i in range(len(skill)):
		data["skills"][i] = skill[i]
	DataManager.save_data(data, "player")

# user 경로에 저장된 데이터 불러오기 
func load_player():
	var load_data = DataManager.load_data("player") as Dictionary
	
	# 비어있으면 새로 만들기 
	if (load_data.is_empty()):
		reset_player()
		return
		
	# 불러온 데이터 입력하기 
	data = load_data
	for i in range(len(skill)):
		skill[i] = data["skills"][i]
	print(skill)

# 새로운 데이터 생성, 이때는 미리 만든 player파일을 가져옴 
func reset_player():
	var new_player = DataManager.get_data("player")
	
	data = new_player
	
	DataManager.save_data(data, "player")
