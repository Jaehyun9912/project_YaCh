class_name Map
extends Node2D

@export var location_resource: Resource

var _cursor:
	get:
		return $"Cursor" as Node2D

# 현재 선택중인 지역
var current_location: MapLocation
# 현재 맵에 들어있는 지역 리스트
var locations: Array[MapLocation]


func _ready():
	var map_name = PlayerData.cur_location
	print(PlayerData.cur_location, map_name)
	var data = DataManager.get_data("Map/" + map_name)["Points"]
	for i in data:
		var obj = location_resource.instantiate()
		var temp = obj as MapLocation
		add_child(obj)
		obj.set_location(i)
		locations.append(temp)
	current_location = locations[0]
	_cursor.position = current_location.position
	
# 지역 이름을 통해 리스트에 있는 지역을 반환
func find_location(location: String) -> MapLocation:
	for i in locations:
		if i.location == location:
			return i
	return null

# 데이터에 적힌 인접한 상하좌우 지역으로 이동
func move_cursor(direction: int) -> void:
	var next_location = null
	if direction == 1:
		next_location = find_location(current_location.up)
	elif direction == 2:
		next_location = find_location(current_location.right)
	elif direction == 3:
		next_location = find_location(current_location.down)
	elif direction == 4:
		next_location = find_location(current_location.left)
	if next_location != null:
		current_location = next_location
	print("Location : ", current_location.location)
	_cursor.position = current_location.position
