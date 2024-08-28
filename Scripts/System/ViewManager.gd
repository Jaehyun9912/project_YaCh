extends Node

const WORLD_PATH = "res://Worlds/"
const PANEL_PATH = "res://Interacts/"

var current_scene: Node = null
var world_instance: Node3D = null
var current_panel: CanvasLayer = null


func get_view():	
	current_scene = get_tree().current_scene
	if current_scene != null:
		world_instance = current_scene.get_node("World")
		current_panel = current_scene.get_node("Interact")
	pass


func load_world(world_name: String, panel_name: String = "3Button") -> void :
	# get current scene
	get_view()
	
	# remove current world instance
	world_instance.get_child(0).queue_free()
		
	# load new world
	var new_world = load(WORLD_PATH + world_name + ".tscn")
	print(WORLD_PATH + world_name)
	world_instance.add_child(new_world.instantiate())
	
	# remove current Panels
	for child in current_panel.get_children():
		current_panel.remove_child(child)
		child.queue_free()
	
	# load new Panel
	var new_panel = load(PANEL_PATH + panel_name + ".tscn")
	print(PANEL_PATH + panel_name)
	current_panel.add_child(new_panel.instantiate())
