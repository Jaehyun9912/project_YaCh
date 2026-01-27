extends Node
class_name  ItemDetailPanel

signal on_exit

@export var title : Label
@export var description : RichTextLabel

func SetSlotInfo(slot : InventorySlot):
	title.text = slot.get_title()
	description.text = slot.get_description()
