extends ColorRect

signal OnSlotClicked

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
		

func set_slot(name : String, count : int):
	nameText.text = name
	countText.text = "x" + str(count)
	
