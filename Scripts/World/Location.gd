extends Area3D

@export var address : String
@export var type : String

# Called when the node enters the scene tree for the first time.
func _ready():
	if address == "":
		address = get_meta("Address")
	if type == "":
		type = get_meta("type")
		
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):


func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("Location Clicked : " + address)
		var meta_data = Dictionary()
		for i in get_meta_list():
			meta_data[i] = get_meta(i)
		
		print(name + " : " + str(meta_data))
		ViewManager.load_world(address, type, meta_data)
		
