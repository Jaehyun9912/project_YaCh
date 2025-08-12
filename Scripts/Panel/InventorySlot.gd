extends ColorRect
class_name InventorySlot

signal OnSlotClicked

var data : BagContent
var _nameText : Label
var nameText:
	get:
		if _nameText == null:
			_nameText =  $"ItemName" as Label
		return _nameText
		
var countText :
	get:
		return $"ItemCount" as Label


func on_clicked(event : InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			OnSlotClicked.emit()
		

func set_slot(_data : BagContent):
	data = _data
	update_slot()
		

func update_slot():
	nameText.text = data.get_title()
	if data.data.has("count"):
		countText.text = "x" + str(data.data["count"])
	else:
		countText.hide()

# 슬롯 선택 시 사용가능한 옵션 리스트를 가져오는 함수
func get_slot_data() -> Array:
	var options = []
	
	return options

func set_highlight(highlight : bool):
	if highlight:
		color = Color("dab53a")
	else:
		color = Color("7cc3b2")
