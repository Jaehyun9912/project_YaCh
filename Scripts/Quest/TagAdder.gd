extends Node

@export var adder_name : String
var CompareTags : Array
var value : int
var checkValue : int
var AddTags : Array

func TagProcess():
	print(TagManager.get_tags(PlayerData))
	for i in CompareTags:
		if !TagManager.has_tag(i,PlayerData):
			print("Player don't Have ",i)
			return false
	#조건 충족
	value +=1
	print(value," / ",checkValue)
	if value >=checkValue:
		for i in AddTags:
			TagManager.add_tag(i,PlayerData)
	print(TagManager.get_tags(PlayerData))
	return true
	
	
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		TagProcess()

func _ready():
	var data = DataManager.get_data("Quest/Tagger/"+adder_name)
	CompareTags = data["CompareTags"]
	AddTags = data["AddTags"]
	checkValue = data["Value"]
	print(CompareTags,"//" , AddTags)
	pass
	

func _get_tag_data() -> Dictionary:
	var dict = {
		"CompareTags" : CompareTags,
		"Value" : checkValue,
		"AddTags" : AddTags
	}
	return dict

var Ex : Dictionary

	
#디버그용 태그애더 데이터 저장
func save_data(save: Dictionary, data_path: String) -> void:
	var path = "res://Data/Quest/Tagger/" + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	
