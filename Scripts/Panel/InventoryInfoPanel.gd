extends Control

signal on_exit

func _ready():
	$"InventoryPanel".on_exit.connect(exit)
	$"InventoryPanel".on_select_changed.connect(set_item_description)

func set_item_description(slot : InventorySlot):
	if slot == null:
		$"ColorRect/ColorRect".hide()
		return
	$"ColorRect/ColorRect".show()
	print(slot.data.data)
	
	$"ColorRect/ColorRect/Label".text = slot.data.get_title()
	$"ColorRect/ColorRect/RichTextLabel".text = slot.data.get_description()

func exit():
	on_exit.emit()


