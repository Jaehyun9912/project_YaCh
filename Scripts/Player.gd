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

func receive_quest(quest : Quest):
	quest_list.append(quest)
	print( quest.id," Receive, Current QuestCount :",quest_list.size())

func print_quest_list():
	var list = "Quest : "
	for i in quest_list:
		list += i.id+", "
	print(list)


#스탯값 앞에 !확인 후 반환 값 부정
func stat_check(value : String)-> bool:
	var negative = false
	if value.begins_with("!"):
		negative = true
		value = value.split("!",true,2)[1]
	return negative != stat_compare(value)
	
#스탯값 부등호 비교
func stat_compare(value : String) -> bool:
	#퀘스트에 필요한 태그 확인(부등호로 태그 카운트 세기)
	var comparer = [">" , "<", "="]#필요하면 이상 이하도 추가
	for i in comparer:
		var str = value.split(i,true,2)
		if str.size()==2:
			print(data[str[0]]," ",i," ",str[1])
			#태그가 있는지 없는지부터 확인
			if !data.has(str[0]):
				return false
			if i == ">" && data[str[0]] > str[1].to_int():
				return true
			if i == "<" && data[str[0]] < str[1].to_int():
				return true
			if i == "=" && data[str[0]] == str[1].to_int():
				return true
	return false
