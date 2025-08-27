extends BagContent
class_name Artifact

var item_data
func _init(_data) -> void:
	data =_data
	item_data = DataManager.get_artifact_data(data)

func get_title():
	return item_data["name"]

