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
	if data is CountableItem:
		countText.text = "x" + str(data.data["count"])
		if data.data["count"] == 0:
			self.queue_free()
	else:
		countText.hide()


func set_highlight(highlight : bool):
	if highlight:
		color = Color("dab53a")
	else:
		color = Color("7cc3b2")
