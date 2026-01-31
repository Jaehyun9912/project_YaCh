extends InventorySlot
class_name ArtifactSlot

var artifact_data

func set_slot(_data):
	data = _data
	artifact_data = DataManager.get_artifact_data(data)
	countText.hide()
	update_slot()
		

func update_slot():
	nameText.text = artifact_data["name"]

func get_title():
	return artifact_data["name"]

func get_description():
	return artifact_data["type"]