extends Node

const WORLD_PATH = "res://Worlds/"
const PANEL_PATH = "res://Interacts/"

var current_scene: Node = null
var world_instance: Node3D = null
var current_panel: CanvasLayer = null

var now_map_name: String

var old_map: String
var old_panel: String

func _ready():
	get_window().size_changed.connect(_on_size_changed)
	_on_size_changed()

func get_view():	
	current_scene = get_tree().current_scene
	if current_scene != null:
		world_instance = current_scene.get_node("World")
		current_panel = current_scene.get_node("Interact")
	pass


func load_world(world_name: String, panel_name: String = "3Button", map_name: String = "", side_mode : int = 0) -> void :
	# get current scene
	get_view()
	
	# 이전 맵 정보 저장
	old_map = world_instance.get_child(0).name
	old_panel = current_panel.get_child(0).name
	
	# remove current world instance
	world_instance.get_child(0).queue_free()
		
	# load new world
	var new_world = load(WORLD_PATH + world_name + ".tscn")
	print(WORLD_PATH + world_name)
	world_instance.add_child(new_world.instantiate())
	now_map_name = map_name
	# remove current Panels
	for child in current_panel.get_children():
		current_panel.remove_child(child)
		child.queue_free()
	# load new Panel
	var new_panel = load(PANEL_PATH + panel_name + ".tscn")
	print(PANEL_PATH + panel_name)
	current_panel.add_child(new_panel.instantiate())
	
	# 사라진 오브젝트의 태그 값 제거
	TagManager.clean_dict()
	get_node("/root/SidePanel").mode = side_mode


#region UI_Panel
# 패널 가로 세로 정렬
func _on_size_changed():
	get_view()
	var size = get_window().size
	print(size)
	if size.x < size.y:
		print("세로")
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	elif size.x > size.y:
		print("가로")
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)
	var panel = current_panel.get_child(0)
	if panel == null: 
		return
	var current_orientation = DisplayServer.screen_get_orientation()
	if current_orientation == DisplayServer.SCREEN_LANDSCAPE:
		panel.anchor_left = 0.5
		panel.anchor_top = 0
	elif current_orientation == DisplayServer.SCREEN_PORTRAIT:
		panel.anchor_left = 0
		panel.anchor_top = 0.5

var panel_stack : Array
# 패널 추가
func push_panel(panel_name : String):
	get_view()
	# 패널 생성, 전시 후 해당 패널 반환
	var panel = load(PANEL_PATH + panel_name + ".tscn").instantiate()
	panel_stack.append(panel)
	current_panel.add_child(panel as Node)
	return panel



# 패널 제거
func erase_panel(panel):
	if panel_stack.has(panel):
		panel_stack.erase(panel)
		current_panel.remove_child(panel)
		panel.queue_free()
	#print("UI count : ",panel_stack.size())

#endregion
