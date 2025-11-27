extends ColorRect
class_name InventorySlot

signal OnSlotClicked

# 아이템이 몇 개 있는지 들어있는 데이터
var data
var _nameText: Label
var nameText:
	get:
		if _nameText == null:
			_nameText = $"ItemName" as Label
		return _nameText
		
var countText:
	get:
		return $"ItemCount" as Label

func on_clicked(event: InputEvent):
	if event is InputEventMouseButton:
		if event.pressed:
			OnSlotClicked.emit()
		

func set_slot(_data):
	data = _data
	countText.hide()
	update_slot()
		

func update_slot():
	pass


func set_highlight(highlight: bool):
	if highlight:
		color = Color("dab53a")
	else:
		color = Color("7cc3b2")

# 해당 슬롯을 선택했을 때 사용 가능한 기능 함수 이름 리스트 반환
func get_slot_method_list(condition: Dictionary) -> Array:
	return Array()