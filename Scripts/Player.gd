extends Node

class_name Player
	
var data

var skill : Array[Skill] = [null, null, null, null]

func _ready():
	var load_data = DataManager.load_data("player") as Dictionary
	if (load_data.is_empty()):
		load_data = DataManager.get_data("player")
		
	data = load_data
		
