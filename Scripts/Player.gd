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

func ReceiveQuest(quest : Quest):
	quest_list.append(quest)
	print( quest.id," Receive, Current QuestCount :",quest_list.size())


