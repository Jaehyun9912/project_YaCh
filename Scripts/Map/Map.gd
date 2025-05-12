class_name Map
extends Node2D

@export var Locations : Resource
# Called when the node enters the scene tree for the first time.
func _ready():
	var data = DataManager.get_data("Map/TestMap")["Points"]
	for i in data:
		var obj = Locations.instantiate()
		add_child(obj)
		obj.set_location(i)
	#print(," : ", position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
