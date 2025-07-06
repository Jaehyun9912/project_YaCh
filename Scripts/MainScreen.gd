extends Control




func show_side_panel():
	#var side = ViewManager.current_scene.get_node("SidePanelLayer")
	#side.show()
	pass
# main 씬 로드 및 현재 씬 삭제
func load_main_scene():
	#show_side_panel()
	var tree = get_tree()
	tree.change_scene_to_file("res://MainView.tscn")

	
	
