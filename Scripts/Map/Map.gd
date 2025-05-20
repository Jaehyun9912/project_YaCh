class_name Map
extends Node2D

@export var location_resource : Resource

var _cursor:
	get:
		return $"Cursor" as Node2D


var current_location : MapLocation
var locations : Array[MapLocation]
# Called when the node enters the scene tree for the first time.
func _ready():
	var data = DataManager.get_data("Map/TestMap")["Points"]
	for i in data:
		var obj = location_resource.instantiate()
		var temp = obj as MapLocation
		add_child(obj)
		obj.set_location(i)
		locations.append(temp)
	#print(," : ", position)
	current_location = locations[0]
	

func _process(delta):
	_cursor.position = current_location.position
	

func find_location(location : String)->MapLocation:
	for i in locations:
		if i.location == location:
			return i
	return null

func move_cursor(direction : int)->void:
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
