extends Node

@export var adder_name : String
var CompareTags : Array
var AddTags : Array
#비교할 스탯
var CompareValue : Dictionary
#조건 충족으로 태그를 붙일 때 비교했던 스탯을 삭제할지 말지
var isDisposable : bool

func TagProcess():
	print(TagManager.get_tags(PlayerData))
	for i in CompareTags:
		if !TagManager.has_tag(i,PlayerData):
			print("Player don't Have ",i)
			return false
	#데이터 값 비교(플레이어 스탯에서 비교)
	for i in CompareValue.keys():
		#없으면 새로 생성
		if !PlayerData.data.has(i):
			PlayerData.data[i] = 0
		#카운트 1추가(새로 생긴 스탯은 항상 업카운트로 확인, 아니면 카운트 증가X,이건 따로 생각)
		if isDisposable:
			PlayerData.data[i] +=1
		print(PlayerData.data[i]," / ",CompareValue[i])
	#해당 스탯이 조건을 충족했는지 확인
	for i in CompareValue.keys():
		if PlayerData.data[i] <CompareValue[i]:
			return false
	#충족 시 태그 추가 및 일회용 스탯은 삭제
	for i in AddTags:
		TagManager.add_tag(i,PlayerData)
	if isDisposable:
		for i in CompareValue.keys():
			PlayerData.data.erase(i)
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
	isDisposable = data["Disposable"]
	CompareValue = data["CompareValue"]
	print(CompareTags,"//" , AddTags)
	pass
	

func _get_tag_data() -> Dictionary:
	var dict = {
		"CompareTags" : CompareTags,
		"CompareValue" : CompareValue,
		"Disposable" : isDisposable,
		"AddTags" : AddTags
	}
	return dict

	
#디버그용 태그애더 데이터 저장
func save_data(save: Dictionary, data_path: String) -> void:
	var path = "res://Data/Quest/Tagger/" + data_path + ".json"
	var save_file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save)
	
	save_file.store_line(json_string)
	
