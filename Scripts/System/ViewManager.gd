extends Node

const WORLD_PATH = "res://Worlds/"
const PANEL_PATH = "res://Interacts/"

var current_scene: Node = null
var world_instance: Node3D = null
var current_panel: CanvasLayer = null

var now_map_name: String

var old_map: String
var old_panel: String

func get_view():	
	current_scene = get_tree().current_scene
	if current_scene != null:
		world_instance = current_scene.get_node("World")
		current_panel = current_scene.get_node("Interact")
	pass


func load_world(world_name: String, panel_name: String = "3Button", map_name: String = "") -> void :
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
	#패널 스택 만들어서 한 맵에서 UI 추가 시 stack에 추가 후 order 정렬
	panel_stack.clear()

var panel_stack : Array
#패널만 추가 하기
func push_panel(panel : Control):
	get_view()
	panel_stack.append(panel)
	#print(panel_stack.size())
	current_panel.add_child(panel as Node)

func pop_panel():
	var last_panel = panel_stack.pop_back()
	print(last_panel)
	current_panel.remove_child(last_panel)
	last_panel.queue_free()

func erase_panel(panel):
	if panel_stack.has(panel):
		panel_stack.erase(panel)
		current_panel.remove_child(panel)
		panel.queue_free()
	print("UI count : ",panel_stack.size())
