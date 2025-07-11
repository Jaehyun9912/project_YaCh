extends Node

var map : Map


func _ready():
	ViewManager.get_view()
	map = ViewManager.world_instance.get_node("Map") as Map
	

# 커서 이동
func _move_cursor(direction : int):
	map.move_cursor(direction)

func enter_world():
	map.current_location.enter_world()

