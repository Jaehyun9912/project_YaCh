@tool
extends Control

@export var package_title: Label
@export var file_system : DE_FileSystem
@export var editor : DE_Editor
@export var inspector : DE_EditorInspector
# 상단 버튼들은 씬에서 직접 연결하도록 export로 노출합니다.
@export var save_button: Button
@export var open_folder_button: Button
@export var add_file_button: Button
@export var add_folder_button: Button

var package_path = "res://Data"
var _view_mode_selector: OptionButton
var _status_label: Label
var _loaded_file_path := ""
var _status_message_serial := 0

# Called when the node enters the scene tree for the first time.
func _ready():
	# MainPanel은 파일 목록, 트리 에디터, Inspector를 연결하는 조정자 역할만 맡습니다.
	_setup_save_controls()
	_setup_view_mode_selector()
	editor.set_show_implicit_default_fields(false)

	# 패키지 경로에 있는 파일들을 트리에 표시합니다.
	load_package(package_path)
	editor.item_selected_for_edit.connect(inspector.show_field)
	inspector.value_confirmed.connect(editor.apply_external_edit)
	editor.file_loaded.connect(_on_editor_file_loaded)
	editor.dirty_state_changed.connect(_on_editor_dirty_state_changed)
	editor.file_saved.connect(_on_editor_file_saved)
	editor.save_failed.connect(_on_editor_save_failed)
	_refresh_header_text()
	_update_save_button_state()


func _setup_save_controls() -> void:
	# 버튼 노드는 scene에서 연결되고, 여기서는 신호와 상태 라벨만 붙입니다.
	if save_button != null and not save_button.pressed.is_connected(_on_save_pressed):
		save_button.pressed.connect(_on_save_pressed)
		save_button.tooltip_text = "현재 JSON 파일 저장 (Ctrl+S)"

	var top_bar = get_node_or_null("VBoxContainer/TopBar/MarginContainer/HBoxContainer") as HBoxContainer
	if top_bar == null:
		return

	# 상태 라벨은 씬에 고정 노드로 두지 않고 코드에서 만들어 상단바 끝에 붙입니다.
	_status_label = Label.new()
	_status_label.name = "SaveStatus"
	_status_label.text = ""
	_status_label.visible = false
	_status_label.modulate = Color(0.7, 0.7, 0.7)
	_status_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_bar.add_child(_status_label)


func _setup_view_mode_selector() -> void:
	# 보기 모드는 코드에서 생성해도 충분하므로 scene 구조를 단순하게 유지합니다.
	var top_bar = get_node_or_null("VBoxContainer/TopBar/MarginContainer/HBoxContainer") as HBoxContainer
	if top_bar == null:
		return

	var search = top_bar.get_node_or_null("Search") as LineEdit

	_view_mode_selector = OptionButton.new()
	_view_mode_selector.name = "ViewMode"
	_view_mode_selector.custom_minimum_size = Vector2(120, 0)
	_view_mode_selector.add_item("간단 모드", 0)
	_view_mode_selector.add_item("전체 모드", 1)
	_view_mode_selector.selected = 0
	_view_mode_selector.tooltip_text = "간단 모드: 파일에 없는 기본값 필드를 숨깁니다.\n전체 모드: 기본값 필드까지 모두 표시합니다."
	_view_mode_selector.item_selected.connect(_on_view_mode_selected)

	top_bar.add_child(_view_mode_selector)
	if search != null:
		# Search 앞에 배치해 상단바의 기존 흐름을 크게 바꾸지 않습니다.
		top_bar.move_child(_view_mode_selector, search.get_index())


func _on_view_mode_selected(index: int) -> void:
	# 0=간단 모드, 1=전체 모드 규약은 OptionButton item id와 맞춰 둡니다.
	editor.set_show_implicit_default_fields(index == 1)

func load_package(path: String):
	# 패키지 경로를 업데이트하고 트리를 새로 고칩니다.
	package_path = path
	file_system.refresh_tree(package_path)
	_refresh_header_text()
	print("Package loaded: ", package_path)


func _on_editor_file_loaded(path: String) -> void:
	# 파일을 새로 열면 header, 저장 버튼, 상태 문구를 함께 갱신합니다.
	_loaded_file_path = path
	_refresh_header_text()
	_update_save_button_state()
	_set_status_message("파일 로드됨", Color(0.72, 0.82, 1.0), 1.5)


func _on_editor_dirty_state_changed(_new_state: bool) -> void:
	# dirty 변화는 header의 * 표시와 저장 가능 상태에만 직접 연결합니다.
	_refresh_header_text()
	_update_save_button_state()


func _on_editor_file_saved(path: String) -> void:
	_loaded_file_path = path
	_refresh_header_text()
	_update_save_button_state()
	_set_status_message("저장됨", Color(0.56, 0.92, 0.62), 2.0)


func _on_editor_save_failed(message: String) -> void:
	_update_save_button_state()
	_set_status_message(message, Color(1.0, 0.55, 0.55), 3.0)


func _on_save_pressed() -> void:
	# editor.gd에서도 실패 signal을 보내지만, 반환값도 확인해 즉시 메시지를 띄웁니다.
	var result = editor.save_current_file()
	if not bool(result.get("ok", false)):
		_set_status_message(str(result.get("message", "저장 실패")), Color(1.0, 0.55, 0.55), 3.0)


func _refresh_header_text() -> void:
	# 파일 미선택 상태에서는 패키지 경로를, 선택 후에는 파일 경로와 dirty 표시를 보여 줍니다.
	if package_title == null:
		return

	if _loaded_file_path.is_empty():
		package_title.text = "Package: " + package_path
		return

	var label_text = "File: " + _loaded_file_path
	if editor.is_dirty:
		label_text += " *"
	package_title.text = label_text


func _update_save_button_state() -> void:
	# 현재는 파일이 선택된 경우에만 저장 버튼을 활성화합니다.
	if save_button == null:
		return

	save_button.disabled = _loaded_file_path.is_empty()


func _set_status_message(text: String, color: Color, clear_after: float = 0.0) -> void:
	# 로드/저장 결과를 상단 한 줄로 보여 주고 일정 시간이 지나면 자동으로 지웁니다.
	if _status_label == null:
		return

	# 이전 타이머의 지연 콜백이 최신 메시지를 지우지 못하도록 일련번호를 함께 비교합니다.
	_status_message_serial += 1
	var serial = _status_message_serial

	_status_label.text = text
	_status_label.modulate = color
	_status_label.visible = not text.is_empty()

	if clear_after <= 0.0:
		return

	await get_tree().create_timer(clear_after).timeout
	if not is_inside_tree():
		return
	if serial != _status_message_serial:
		return

	_status_label.text = ""
	_status_label.visible = false

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if is_visible_in_tree():
			# 숨김 상태였다가 다시 보일 때 Tree/Inspector 레이아웃이 깨지지 않도록 갱신합니다.
			queue_redraw()


func _unhandled_input(event):
	# 단축키는 패널이 보이는 동안에만 가로채 다른 탭과 충돌하지 않게 합니다.
	if not is_visible_in_tree():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_S:
			get_viewport().set_input_as_handled()
			_on_save_pressed()

func _on_file_system_item_selected():
	# 파일 트리에서는 JSON 파일만 editor.gd로 넘기고 폴더/다른 확장자는 무시합니다.
	var selected_item = file_system.get_selected()
	var path = selected_item.get_metadata(0) # 메타데이터에서 경로 가져오기

	if not path:
		printerr("선택된 항목의 경로가 존재하지 않습니다.")
		return

	if FileAccess.file_exists(path) and path.ends_with(".json"):
		editor.load_json_data(path)
	else:
		print("선택된 항목이 유효한 JSON 파일이 아닙니다: ", path)

