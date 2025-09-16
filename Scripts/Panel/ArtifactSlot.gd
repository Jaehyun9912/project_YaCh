extends InventorySlot
class_name ArtifactSlot

var artifact_data

func set_slot(_data):
	data = _data
	artifact_data = DataManager.get_artifact_data(data["id"])
	countText.hide()
	update_slot()
		

func update_slot():
	nameText.text = artifact_data["name"]
