extends Control

signal on_exit
signal on_select_changed(slot : InventorySlot)

@export var slot_prefab : Resource
@export var option_prefab : Resource

var slotContainer: VBoxContainer

var selected_slot : InventorySlot

var data
# Called when the node enters the scene tree for the first time.
func _ready():
	slotContainer = $"Inventory/ScrollContainer/VBoxContainer" as VBoxContainer
	data = PlayerData.inventory
	set_slot()
	
	var discardBtn = $"ColorRect2/ScrollContainer/VBoxContainer/DiscardBox/Button" as Button
	discardBtn.pressed.connect(discard_slot)

# 각 슬롯에 맞는 아이템 데이터 세팅
func set_slot():
	for i in slotContainer.get_child_count():
		slotContainer.get_child(i).queue_free()
	for i in data:
		var itemData = BagContent.new(i)
		var slot = slot_prefab.instantiate() as InventorySlot
		slot.set_slot(itemData)
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)

# 슬롯 클릭 시 그 아이템에 맞는 UI 세팅
func set_slot_info(slot : InventorySlot):
	if selected_slot != null:
		selected_slot.set_highlight(false)
	selected_slot = slot
	selected_slot.set_highlight(true)
	on_select_changed.emit(selected_slot.data.data)

func discard_slot():
	if selected_slot == null:
		return
	var isEmpty = selected_slot.data.discard()
	if isEmpty:
		selected_slot.queue_free()
		
	else:
		selected_slot.update_slot()
		

func exit():
	on_exit.emit()
