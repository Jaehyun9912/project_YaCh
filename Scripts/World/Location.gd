extends Node#Area3D

@export var address : String
@export var type : String


func _on_location_clicked(_camera, _event, _pos, _n, _shape_idx):
	if _event is InputEventMouseButton and _event.pressed:
		print("Location Clicked : " + address)
		var meta_data = Dictionary()
		for i in get_meta_list():
			meta_data[i] = get_meta(i)
		
		print(name + " : " + str(meta_data))
		ViewManager.load_world(address, type, meta_data)
		

func _on_button_clicked():
	var meta_data = Dictionary()
	for i in get_meta_list():
		meta_data[i] = get_meta(i)
	ViewManager.load_world(address,type,meta_data)
