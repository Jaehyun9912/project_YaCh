class_name BagContent

var data : Dictionary

func _init(_data : Dictionary):
	data =_data


func discard() -> bool:
	if data.has("count"):
		data["count"] -=1
		if data["count"] ==0:
			return true
	return false
	
