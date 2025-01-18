extends Node
@export var conditions : Array[String]
@export var add_tags : Array[String]


func condition_process():
	if Quest.condition_check(conditions):
		#모든 조건 충족
		for i in add_tags:
			TagManager.add_tag_tree(PlayerData,i)
		print(TagManager.get_tags(PlayerData))
		return true
	return false


	
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		condition_process()


#디버그용 태그애더 데이터 저장
func save_data(save: Dictionary, data_path: String) -> void:
	var path = "res://Data/Quest/Tagger/" + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	

