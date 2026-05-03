extends Control

func _ready():
	var start_button = get_node_or_null("Button")
	if start_button:
		if not DataManager.is_ready:
			start_button.disabled = true
			start_button.text = "데이터 로딩 중..."
			DataManager.loading_finished.connect(func(): 
				start_button.disabled = false
				start_button.text = "게임 시작"
			)
		else:
			start_button.disabled = false
			start_button.text = "게임 시작"

func show_side_panel():
	#var side = ViewManager.current_scene.get_node("SidePanelLayer")
	#side.show()
	pass
# main 씬 로드 및 현재 씬 삭제
func load_main_scene():
	#show_side_panel()
	var tree = get_tree()
	tree.change_scene_to_file("res://MainView.tscn")

	
	
