extends Area3D

var address : String
var type : String
var map_name

# Called when the node enters the scene tree for the first time.
func _ready():
	address = get_meta("address")
	type = get_meta("type")
	map_name = get_meta("name")
	if (not map_name):
		map_name = name


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):


func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("Location Clicked : " + address)
		ViewManager.load_world(address, type, map_name)
		
