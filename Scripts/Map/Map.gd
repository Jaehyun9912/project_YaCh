class_name Map
extends Node2D

@export var location_resource: Resource
@onready var _cursor = $Cursor as Node2D

## 현재 선택중인 지역
var current_location: MapLocation
## 현재 맵에 들어있는 지역 리스트
var locations: Array[MapLocation]

func _ready():
	# 맵 데이터 불러오기
	var map_name = PlayerData.cur_location
	print(PlayerData.cur_location, map_name)

	var map_data_json = DataManager.get_data("Map/" + map_name)
	if map_data_json == null:
		printerr("[Map] Failed to load map data for " + map_name)
		return	

	var map_data = MapData.from_dict(map_data_json)

	# 지역 인스턴스화 및 배치
	for id in map_data.points:
		var point = map_data.points[id]
		var obj = location_resource.instantiate() as MapLocation
		add_child(obj)
		obj.set_location(point)
		locations.append(obj)

	if locations.is_empty():
		printerr("[Map] No locations found in map data for " + map_name)
		return

	# 첫 번째 지역에 배치 (임시)
	current_location = locations[0]
	_calculate_location()
	_cursor.position = current_location.position

## 데이터에 적힌 인접한 상하좌우 지역으로 이동
func move_cursor(direction: int) -> void:
	var next_location = null

	match direction:
		1:
			next_location = current_location.up
		2:
			next_location = current_location.right
		3:
			next_location = current_location.down
		4:
			next_location = current_location.left

	if next_location == null:
		print("[Map] No adjacent location in that direction.")
		return

	current_location = next_location
	_cursor.position = current_location.position
	print("[Map] Location : ", current_location.location)

## 지역 간의 위치를 계산해 상하좌우 연결
func _calculate_location():
	for current in locations:
		var min_dist_up = INF
		var min_dist_down = INF
		var min_dist_left = INF
		var min_dist_right = INF

		for target in locations:
			if current == target:
				continue

			var diff = target.position - current.position
			var dist = diff.length()

			# 수직 영역 (Up / Down)
			if abs(diff.x) < abs(diff.y):
				if diff.y < 0: # 위쪽
					if dist < min_dist_up:
						min_dist_up = dist
						current.up = target
				else: # 아래쪽
					if dist < min_dist_down:
						min_dist_down = dist
						current.down = target
			# 수평 영역 (Left / Right)
			else:
				if diff.x < 0: # 왼쪽
					if dist < min_dist_left:
						min_dist_left = dist
						current.left = target
				else: # 오른쪽
					if dist < min_dist_right:
						min_dist_right = dist
						current.right = target