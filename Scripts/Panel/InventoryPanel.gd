extends Control

signal on_exit
signal on_select_changed(slot: InventorySlot)

@export var slot_prefab: Resource
@export var option_prefab: Resource

@export var slotContainer: VBoxContainer
@export var actionContainer: VBoxContainer
var detail_panel: ItemDetailPanel

var selected_slot: InventorySlot


var inventory_data

# 전투 아이템 사용 제한(이후에 이 변수 값을 늘려서 다른 제한 추가)
var isBattle: bool

# 각 아이템에서 사용 가능한 기능(해당 배열에 있는 기능만 사용 가능)
var action_list = ["use", "discard", "read"]

# 인벤토리 카테고리
var category = [["battle", "배틀 아이템"], ["consume", "소모 아이템"], ["artifact", "아티펙트"], ["quest", "퀘스트"]]

var cur_category: int
var read_panel: Control

# 초기 설정
func initialize(meta_data: Dictionary):
	detail_panel = ViewManager.push_panel("ItemDetailPanel", ViewManager.SCREEN.TOP) as ItemDetailPanel

	if meta_data.has("mode"):
		if meta_data["mode"] == "full":
			detail_panel.show()
			on_select_changed.connect(set_item_description)
			pass
		elif meta_data["mode"] == "half":
			detail_panel.hide()
			pass
	isBattle = false
	if meta_data.has("isBattle"):
		isBattle = meta_data["isBattle"]
	cur_category = 0
	$"Inventory/Inventory/Category/Left".pressed.connect(change_category.bind(-1))
	$"Inventory/Inventory/Category/Right".pressed.connect(change_category.bind(1))
	
	change_category(0)
	
#region 인벤토리 세팅
func clear_slot():
	for i in slotContainer.get_child_count():
		slotContainer.get_child(i).queue_free()

# 인벤토리 아이템 데이터 세팅
func set_item_slot():
	clear_slot()
	inventory_data = PlayerData.inventory
	for i in inventory_data:
		var item_data = DataManager.get_item_data(i["id"])
		if item_data["category"] != category[cur_category][0]:
			continue
		var slot = slot_prefab.instantiate()
		slot.set_script(ItemSlot)
		slot.set_slot(i)
		slot.tree_exited.connect(set_slot_info.bind(null))
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)

# 퀘스트 데이터 세팅
func set_quest_slot():
	clear_slot()
	inventory_data = PlayerData.quest_list
	for i in inventory_data:
		var slot = slot_prefab.instantiate()
		slot.set_script(QuestSlot)
		slot.set_slot(i)
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)

func set_artifact_slot():
	clear_slot()
	inventory_data = PlayerData.artifact
	for i in inventory_data:
		var slot = slot_prefab.instantiate()
		slot.set_script(ArtifactSlot)
		slot.set_slot(i)
		slotContainer.add_child(slot)
		slot.OnSlotClicked.connect(set_slot_info.bind(slot))
		slot.set_highlight(false)
#endregion

# 슬롯 클릭 시 그 아이템에 맞는 UI 세팅
func set_slot_info(slot: InventorySlot):
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

	# 나중에 다른 제한 걸리면 dictionary로 사용 예정
	var methods = slot.get_slot_method_list({"isBattle": isBattle})
	for i in methods:
		if slot.has_method(i):
			var action = option_prefab.instantiate() as ActionBox
			actionContainer.add_child(action)
			action.set_action(slot.call.bind(i), i)
			action.on_clicked.connect(slot.update_slot)
	

func exit():
	detail_panel.on_exit.emit()
	on_exit.emit()

func change_category(direction: int):
	cur_category += direction
	if cur_category >= category.size() || cur_category < 0:
		cur_category %= category.size()
	set_slot_info(null)

	$"Inventory/Inventory/Category/Label".text = category[cur_category][1]
	# 현재 카테고리에 맞는 인벤토리 슬롯 표시
	if category[cur_category][0] == "quest":
		set_quest_slot()
	elif category[cur_category][0] == "artifact":
		set_artifact_slot()
	else:
		set_item_slot()

# 현재 선택한 슬롯에 대한 디테일 표시
func set_item_description(slot: InventorySlot):
	if slot == null:
		detail_panel.hide()
		return
	detail_panel.show()
	detail_panel.set_slot_info(slot)
	print(slot.data)

