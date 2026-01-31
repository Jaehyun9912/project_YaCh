extends Node

@export var map: Map

# 의존성 주입
func initialize_world(node: Node):
	if node is Map:
		map = node as Map
	print(node)


# 커서 이동
func _move_cursor(direction: int):
	map.move_cursor(direction)

func enter_world():
	map.current_location.enter_world()
