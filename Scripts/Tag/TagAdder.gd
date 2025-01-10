extends Node

#태그 이름 : 태그 카운트
@export var compare_tags : Dictionary
#비교할 스탯값(없으면 스킵)(문자열 하나에 변수이름부등호int값 붙여서 작성)
@export var CompareValue : Array[String]
#추가할 태그 이름(있으면 태그 카운트 1개 추가)
@export var add_tags : Array[String]


func tag_process():
	print(TagManager.get_tags(PlayerData))
	#
	for i in compare_tags.keys():
		if !TagManager.has_tag(PlayerData,i):
			print("Player don't Have ",i)
			return false 
		if TagManager.get_tag_count(PlayerData,i)< compare_tags[i]:
			print("Not enough count",i)
			return false
	if !StatCompare():
		return false
	for i in add_tags:
		TagManager.add_tag_tree(PlayerData,i)
	print(TagManager.get_tags(PlayerData))
	return true

func StatCompare():
	var comparer  =["<=",">=","=","<",">" ]
	if CompareValue.size()<=0:
		return true
	for str in CompareValue:
		for i in comparer:
			var arr = str.split(i,true,2)
			if arr.size()>1:
				if PlayerData.data.has(arr[0]):
					print(PlayerData.data[arr[0]],i,arr[1].to_int())
					if i == "<" && PlayerData.data[arr[0]] < arr[1].to_int():
						return true
					if i == "<=" && PlayerData.data[arr[0]] <= arr[1].to_int():
						return true
					if i == "=" && PlayerData.data[arr[0]] == arr[1].to_int():
						return true
					if i == ">" && PlayerData.data[arr[0]] > arr[1].to_int():
						return true
					if i == ">=" && PlayerData.data[arr[0]] >= arr[1].to_int():
						return true
	return false

	
func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("TagAdderClicked")
		tag_process()


#디버그용 태그애더 데이터 저장
func save_data(save: Dictionary, data_path: String) -> void:
	var path = "res://Data/Quest/Tagger/" + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	
