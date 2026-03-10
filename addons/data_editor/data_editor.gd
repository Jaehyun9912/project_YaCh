@tool
extends EditorPlugin

const MainPanel = preload("res://addons/data_editor/main_panel.tscn")
var main_panel_instance

func _enter_tree() -> void:
	# 플러그인이 활성화될 때 씬을 인스턴스화합니다.
	main_panel_instance = MainPanel.instantiate()
	
	# 에디터의 메인 스크린 영역에 우리가 만든 UI를 자식으로 추가합니다.
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	
	# 처음에는 화면에 보이지 않도록 숨깁니다.
	_make_visible(false)

func _exit_tree() -> void:
	# 플러그인이 비활성화되거나 에디터가 꺼질 때 제거
	if main_panel_instance:
		main_panel_instance.queue_free()

func _has_main_screen() -> bool:
	# 이 플러그인이 메인 스크린을 사용한다고 에디터에 알립니다.
	return true

func _make_visible(visible: bool) -> void:
	# 2D, 3D, Script 탭을 누를 때마다 호출됩니다.
	# 우리 플러그인 탭이 눌렸을 때만 화면에 보이게 처리합니다.

	# 나중에 완성되면 지우기
	if visible:
		_debug_reload_mainpanel()  # 탭이 활성화될 때마다 레이아웃 재계산을 위해 디버그 함수 호출

	if main_panel_instance:
		main_panel_instance.visible = visible

func _get_plugin_name() -> String:
	# 상단 중앙 탭에 표시될 이름을 설정합니다.
	return "Data Editor"

func _get_plugin_icon() -> Texture2D:
	# 탭 이름 옆에 표시될 아이콘입니다. 에디터 기본 내장 아이콘을 재활용합니다.
	return EditorInterface.get_editor_theme().get_icon("Data", "EditorIcons")

func _debug_reload_mainpanel():
	# 플러그인 개발 중에 main_panel.tscn과 main_panel.gd를 수정한 후, 변경 사항을 즉시 반영하기 위한 디버그 함수입니다.
	if main_panel_instance:
		main_panel_instance.queue_free()  # 기존 인스턴스 제거
	main_panel_instance = MainPanel.instantiate()  # 새 인스턴스 생성
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)  # 에디터에 추가