extends Control

signal on_exit
signal on_select_changed(slot : InventorySlot)

@export var slot_prefab : Resource
@export var option_prefab : Resource

var slotContainer: VBoxContainer
var actionContainer : VBoxContainer

var selected_slot : InventorySlot

var data

# 각 아이템에서 사용 가능한 기능(해당 배열에 있는 기능만 사용 가능)
var action_list = ["use", "discard", "read"]

# 인벤토리 카테고리
var category = ["inventory","quest","artifact"]
var cur_category : int
# Called when the node enters the scene tree for the first time.
func _ready():
	slotContainer = $"Inventory/ScrollContainer/VBoxContainer" as VBoxContainer
	actionContainer = $"ColorRect2/ScrollContainer/VBoxContainer" as VBoxContainer
	
	cur_category = 0
	$"Inventory/Category/Left".pressed.connect(change_category.bind(-1))
	$"Inventory/Category/Right".pressed.connect(change_category.bind(1))
	
	
	data = PlayerData.inventory
	set_slot()

# 각 슬롯에 맞는 아이템 데이터 세팅
func set_slot():
	for i in slotContainer.get_child_count():
		slotContainer.get_child(i).queue_free()
	for i in data:
		var itemData = CountableItem.new(i)
		var slot = slot_prefab.instantiate() as InventorySlot
		slot.set_slot(itemData)
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)

# 슬롯 클릭 시 그 아이템에 맞는 UI 세팅
func set_slot_info(slot : InventorySlot):
	for i in actionContainer.get_child_count():
		actionContainer.get_child(i).queue_free()
	if selected_slot != null:
		selected_slot.set_highlight(false)
	selected_slot = slot
	selected_slot.set_highlight(true)
	for i in action_list:
		if slot.data.has_method(i):
			var action = option_prefab.instantiate() as ActionBox
			actionContainer.add_child(action)
			action.set_action(slot.data.call.bind(i),i)
			action.Onclicked.connect(slot.update_slot)
				
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

func change_category(direction : int):
	cur_category+=direction
	if cur_category >= category.size() || cur_category<0:
		cur_category%=category.size()
	$"Inventory/Category/Label".text = category[cur_category]
	# 현재 카테고리에 맞는 인벤토리 슬롯 표시
