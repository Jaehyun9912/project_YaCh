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
var category = ["battle","consume","artifact","quest"]
var category_name =["배틀 아이템","소모 아이템","아티펙트","퀘스트"]

var cur_category : int
var read_panel : Control
# Called when the node enters the scene tree for the first time.
func _ready():
	slotContainer = $"Inventory/ScrollContainer/VBoxContainer" as VBoxContainer
	actionContainer = $"ColorRect2/ScrollContainer/VBoxContainer" as VBoxContainer
	
	
	cur_category = 0
	$"Inventory/Category/Left".pressed.connect(change_category.bind(-1))
	$"Inventory/Category/Right".pressed.connect(change_category.bind(1))
	
	change_category(0)
	
	

#region 인벤토리 세팅
func clear_slot():
	for i in slotContainer.get_child_count():
		slotContainer.get_child(i).queue_free()

# 인벤토리 아이템 데이터 세팅
func set_item_slot(num : int):
	$"Inventory/Category/Label".text = category_name[num]
	clear_slot()
	data = PlayerData.inventory
	for i in data:
		var slot = slot_prefab.instantiate()
		slot.set_script(ItemSlot)
		slot.set_slot(i)
		slot.tree_exited.connect(set_slot_info.bind(null))
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)

# 퀘스트 데이터 세팅
func set_quest_slot():
	$"Inventory/Category/Label".text = "퀘스트"
	clear_slot()
	data = PlayerData.quest_list
	for i in data:
		var slot = slot_prefab.instantiate()
		slot.set_script(QuestSlot)
		slot.set_slot(i)
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)

func set_artifact_slot():
	$"Inventory/Category/Label".text = "아티펙트"
	clear_slot()
	data = PlayerData.artifact
	for i in data:
		var slot = slot_prefab.instantiate()
		slot.set_script(ArtifactSlot)
		slot.set_slot(i)
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)
#endregion

# 슬롯 클릭 시 그 아이템에 맞는 UI 세팅
func set_slot_info(slot : InventorySlot):
	for i in actionContainer.get_child_count():
		actionContainer.get_child(i).queue_free()
	if selected_slot != null:
		selected_slot.set_highlight(false)
	if selected_slot != slot && slot != null:
		selected_slot = slot
		on_select_changed.emit(selected_slot)
	else:
		selected_slot = null
		on_select_changed.emit(null)
		return
	selected_slot.set_highlight(true)
	for i in action_list:
		if slot.has_method(i):
			var action = option_prefab.instantiate() as ActionBox
			actionContainer.add_child(action)
			if i == "read":
				action.set_action(read_slot.bind(slot),i)
				pass
			else:
				action.set_action(slot.call.bind(i),i)
				action.on_clicked.connect(slot.update_slot)

func discard_slot():
	if selected_slot == null:
		return
	var isEmpty = selected_slot.data.discard()
	if isEmpty:
		selected_slot.queue_free()
	else:
		selected_slot.update_slot()


func read_slot(slot):
	if read_panel.visible:
		read_panel.hide()
	else:
		read_panel.show()
		read_panel.set_panel(slot.data)
	

func exit():
	on_exit.emit()

func change_category(direction : int):
	cur_category+=direction
	if cur_category >= category.size() || cur_category<0:
		cur_category%=category.size()
	set_slot_info(null)
	# 현재 카테고리에 맞는 인벤토리 슬롯 표시
	if category[cur_category] == "quest":
		set_quest_slot()
	elif category[cur_category] == "artifact":
		set_artifact_slot()
	else:
		set_item_slot(cur_category)
	
