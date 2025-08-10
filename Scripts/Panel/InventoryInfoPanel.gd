extends Control

signal on_exit

func _ready():
	$"InventoryPanel".on_exit.connect(exit)
	$"InventoryPanel".on_select_changed.connect(set_item_description)

func set_item_description(data : Dictionary):
	print(data)
	var item_data = DataManager.get_item_data(data["id"])
	$"ColorRect/ColorRect/Label".text = item_data["name"]
	$"ColorRect/ColorRect/RichTextLabel".text = item_data["description"]

func exit():
	on_exit.emit()


