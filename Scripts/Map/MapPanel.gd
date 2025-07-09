extends Node

var map : Map


# Called when the node enters the scene tree for the first time.
func _ready():
	map = ViewManager.world_instance.get_node("Map") as Map
	
	pass # Replace with function body.

# 커서 이동
func _move_cursor(direction : int):
	map.move_cursor(direction)

func enter_world():
	map.current_location.enter_world()

