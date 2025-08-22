extends BagContent
class_name CountableItem

var item_data
func _init(_data : Dictionary) -> void:
	data =_data
	item_data = DataManager.get_item_data(data["id"])
# 사용하기
func use() -> bool:
	if true:
		#기능 실행
		discard()
		return true
	return false

# 버리기
func discard():
	if data.has("count"):
		data["count"] -=1
		print(data)
		on_value_changed.emit(data["count"])
	
	

func get_title():
	return item_data["name"]

func get_description():
	return item_data["description"]

