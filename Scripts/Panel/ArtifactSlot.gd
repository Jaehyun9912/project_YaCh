extends InventorySlot
class_name ArtifactSlot

var artifact_data

# 인벤토리의 아티펙트 슬롯 설정
func set_slot(_data):
	data = _data
	artifact_data = DataManager.get_artifact_data(data)
	countText.hide()
	update_slot()
		
# 슬롯 업데이트
func update_slot():
	nameText.text = artifact_data["name"]

func get_title():
	return artifact_data["name"]

func get_description():
	return artifact_data["type"]