extends Node
class_name ItemDetailPanel

signal on_exit

@export var title: Label
@export var description: RichTextLabel

# 선택한 슬롯에 대한 상세정보 표시
func set_slot_info(slot: InventorySlot):
	title.text = slot.get_title()
	description.text = slot.get_description()
