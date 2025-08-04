extends Control

@export var slot_prefab : Resource

var slotContainer: VBoxContainer



var data
# Called when the node enters the scene tree for the first time.
func _ready():
	slotContainer = $"Inventory/ScrollContainer/VBoxContainer" as VBoxContainer
	data = PlayerData.inventory
	set_slot()



func set_slot():
	for i in slotContainer.get_child_count():
		slotContainer.get_child(i).queue_free()
	for i in data:
		var slot = slot_prefab.instantiate()
		slot.set_slot(i.id,i.count)
		slotContainer.add_child(slot)
