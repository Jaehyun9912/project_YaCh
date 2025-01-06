extends Node

class_name Player
	
var data

var skill : Array[Skill] = [null, null, null, null]

func _ready():
	load_player()
		
func save_player():
	DataManager.save_data(data, "player")
	
func load_player():
	var load_data = DataManager.load_data("player") as Dictionary
	
	if (load_data.is_empty()):
		reset_player()
	else:
		data = load_data

func reset_player():
	var new_player = DataManager.get_data("player")
	
	data = new_player
	
	DataManager.save_data(data, "player")


#수주 중인 퀘스트 리스트
var quest_list : Array[Quest]
#값 비교용

func ReceiveQuest(quest : Quest):
	#퀘스트 리스트에 추가
	quest_list.append(quest)
	#퀘스트에 필요한 스탯을 찾고 없으면 추가(이러면 태그 시스템이 없어도 되지 않나...?)
	#if !data.has(quest.value):
	#	data[quest.value] = 0
	#quest.is_clearable()
	#print("data",data[quest.value])
	print( quest.id," Receive, Current QuestCount :",quest_list.size())

func PrintQuestList():
	var list = "Quest : "
	for i in quest_list:
		list += i.id+", "
	print(list)
			
