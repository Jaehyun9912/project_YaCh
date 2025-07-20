extends Node

const WORLD_PATH = "res://Worlds/"
const PANEL_PATH = "res://Interacts/"

#signal ratio_changed(value)

var current_scene: Node = null
var world_instance: Node3D = null
var current_panel: CanvasLayer = null

var side_panel : Control = null

var cur_meta_data: Dictionary

var old_map: String
var old_panel: String

var panel_ratio:
	set(value):
		panel_ratio = value
		#ratio_changed.emit(value)
		update_panels_size()
	get:
		if panel_ratio == null:
			panel_ratio = 0.5
		return panel_ratio





func get_view():	
	current_scene = get_tree().current_scene
	if current_scene != null:
		world_instance = current_scene.get_node("World")
		current_panel = current_scene.get_node("Interact")
		side_panel = current_scene.get_node("SidePanelLayer/SidePanel")
		print(side_panel.name)
	pass


func load_world(world_name: String, panel_name: String = "", meta_data: Dictionary = Dictionary()) -> void :
	# get current scene
	get_view()
	
	# 이전 맵 정보 저장
	old_map = world_instance.get_child(0).name
	old_panel = current_panel.get_child(0).name
	
	# remove current world instance
	world_instance.get_child(0).queue_free()
	
	cur_meta_data = meta_data
	cur_meta_data["address"] = world_name
	cur_meta_data["type"] = panel_name
	
	# load new world
	var new_world = load(WORLD_PATH + world_name + ".tscn")
	print(WORLD_PATH + world_name)
	world_instance.add_child(new_world.instantiate())
	
	# remove current Panels
	for child in current_panel.get_children():
		erase_panel(child)
	# load new Panel
	if panel_name != "":
		push_panel(panel_name,SCREEN.BOTTOM)
	# 사라진 오브젝트의 태그 값 제거
	TagManager.clean_dict()
	_on_size_changed()





#region UI_Panel

# 현재 스크린 가로 세로 비율 확인
var screen_mode:
	get:
		var size = get_window().size
		if size.x > size.y:
			return 0
		else:
			return 1
# 패널 가로 세로 정렬
func _on_size_changed():
	get_view()
	if current_panel == null:
		return
	var panel = current_panel.get_child(0)
	if panel == null:
		return
	
	if screen_mode == 0:
		panel.anchor_left = 0.5
		panel.anchor_top = 0
	elif screen_mode == 1:
		panel.anchor_left = 0
		panel.anchor_top = 0.5



enum SCREEN{
	TOP,
	BOTTOM,
	FULL
}
# 패널 추가
func push_panel(panel_name : String,screen_location : SCREEN):
	get_view()
	# past panel hide
	#if panel_stack.size()>0:
	#	var last_panel = panel_stack.back()
	#	last_panel.hide()
	# 패널 생성, 전시 후 해당 패널 반환
	var panel = load(PANEL_PATH + panel_name + ".tscn").instantiate()
	#print(panel_name," added, current panel count : ",panel_stack.size())
	current_panel.add_child(panel as Node)
	
	_set_screen_size(panel,screen_location)
	
	return panel


# 패널 제거
func erase_panel(panel):
	if current_panel.get_children().has(panel):
		current_panel.remove_child(panel)
	#print("panel erased, current panel count : ",panel_stack.size())
	

# 스크린 위치 지정 
func _set_screen_size(panel:Control,screen_location:SCREEN) -> void:
	if screen_location == SCREEN.BOTTOM:
		panel.anchor_left = 0
		panel.anchor_top = 1-panel_ratio
		panel.anchor_right = 1
		panel.anchor_bottom = 1
	elif screen_location == SCREEN.TOP:
		panel.anchor_left = 0
		panel.anchor_top = 0
		panel.anchor_right = 1
		panel.anchor_bottom = 1-panel_ratio
	elif screen_location == SCREEN.FULL:
		panel.anchor_left = 0
		panel.anchor_top = 0
		panel.anchor_right = 1
		panel.anchor_bottom = 1


func update_panels_size():
	get_view()
	var _panel = current_panel.get_child(0)
	_set_screen_size(_panel,SCREEN.BOTTOM)
		
#endregion

# 컷신 보여주기(이미지 경로는 나중에 폴더 만들고 경로 조정할 예정)
func show_cutscene(path,screen : SCREEN):
	var panel = push_panel("CutScenePanel",screen)
	if screen == SCREEN.FULL:
		_set_screen_size(side_panel,screen)
	panel.tree_exited.connect(_set_screen_size.bind(side_panel,SCREEN.TOP))
	
	var texture = load_texture_from_file(path)
	panel.set_image(texture)
	#_set_screen_size(SidePanel,SCREEN.FULL)

# 경로에 위치한 png 이미지를 texture2D로 변환해 반환
# 함수 위치 변경 가능

func load_texture_from_file(path: String) -> Texture2D:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		print("파일 열기 실패: ", path)
		return null
	
	var image = Image.new()
	var error = image.load_png_from_buffer(file.get_buffer(file.get_length()))
	if error != OK:
		print("이미지 로드 실패")
		return null
	
	var texture = ImageTexture.create_from_image(image)
	return texture

