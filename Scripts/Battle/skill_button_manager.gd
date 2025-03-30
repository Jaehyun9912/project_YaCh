class_name SkillButtonManager extends Control

@onready var buttons = get_tree().get_nodes_in_group("skill_buttons")
@onready var button_img = $ButtonImage

@onready var cancel_area = $ButtonCancelArea

@onready var choice_btn_man = $ChoiceButtonManager as ChoiceButtonManager
@onready var line = $Line2D as Line2D

var battle_panel: BattlePanel

var current_button := -1
var target_index := -1
var is_on_cancel_area := false

var is_ally

@export var cancel_button_size = Vector2(4, 4)

signal skill_activated(button_index, target)
signal target_changed(target, isally)

func _ready():
	# 버튼에 시그널 연결 
	for i in len(buttons):
		var btn = buttons[i] as RoundButton
		var index = i
		
		btn.button_down.connect(on_skillbutton_down.bind(btn, index))
		btn.button_up.connect(on_skillbutton_up)
	
# 마우스 이벤트 
func _input(event):
	# 누르고 있으면 마우스 위치에 버튼 이미지 놓기 (터치도 같은 방식인지 확인 필요함)
	if current_button == -1 or not event is InputEventMouseMotion : return
	
	var local_event = make_input_local(event)
	var mouse = local_event.position
	button_img.position = mouse - button_img.pivot_offset
	
	# 취소 범위 밖에 있으면 버튼 선택하게 만들기 
	if not is_on_cancel_area:
		line.set_point_position(0, mouse)
		var target = choice_btn_man.get_nearest_button(mouse)
		
		if target != target_index:
			target_index = target
			choice_btn_man.make_button_special(target_index)
			line.set_point_position(1, choice_btn_man.get_button_center(target_index))
			
			target_changed.emit(target_index, is_ally)
	
# 스킬 버튼 OnOff 설정 
func set_all_buttons(OnOff):
	for i in buttons:
		i.disabled = !OnOff
	
# 스킬 버튼 눌렀을 때 
func on_skillbutton_down(btn, index):
	# 일단 센터 버튼이면 스킵 
	if index == battle_panel.Buttons.CENTER:
		return
	var skill = SkillManager.get_player_skill(index)
	
	# 가림 패널 활성화 후 마우스에 버튼 이미지 부착 
	$Cover.visible = true
	button_img.visible = true
	current_button = index
	button_img.global_position = get_viewport().get_mouse_position() - button_img.pivot_offset
	
	# 버튼 누른 위치에 취소 크기를 설정하는 원 생성 
	cancel_area.visible = true
	cancel_area.position = btn.position
	cancel_area.modulate = AttributeInfomation.get_attribute_color_by_skill(skill)
	var tween = create_tween()
	tween.tween_property(cancel_area, "scale", cancel_button_size, 0.1)
	
	# 사이드 패널에 정보 띄우기 
	SidePanel.set_info_panel(skill.get("name", ""), skill.get("description", ""))
	
	# 스킬 정보에 따라 선택 버튼 생성
	var skill_target = SkillManager.get_target(index)
	# 자기 자신에게 적용하기
	if skill_target is String and skill_target == "self":
		pass
	else:
		var target_count = skill_target.get("count", 0)
		is_ally = skill_target.get("team", false)
		
		# 타겟 유형에 따라 적/아군 개수 가져오기 
		var cnt := 0
		if is_ally:
			cnt = len(battle_panel.get_all_ally())
		else:
			cnt = len(battle_panel.get_all_enemy())
		
		# 선택 시작
		# 0 -> 오른쪽에 적 버튼 생성
		# 3 -> 왼쪽에 적 버튼 생성
		# 1, 2 -> 위쪽에 적 버튼 생성 
		match index:
			0:
				choice_btn_man.set_choice_button(cnt, btn.global_position, -30, 90)
			1:
				choice_btn_man.set_choice_button(cnt, btn.global_position, -90, 90)
			2:
				choice_btn_man.set_choice_button(cnt, btn.global_position, -90, -90)
			3:
				choice_btn_man.set_choice_button(cnt, btn.global_position, 160, 90)
	
# 스킬 버튼 뗐을 때 
func on_skillbutton_up():
	target_changed.emit(-1, is_ally)
	# 스킬 발동 
	if is_on_cancel_area == false:
		# TODO target 한명 -> 스킬 정보 따라 범위 공격이면 좌우 대상 넣어야 함
		skill_activated.emit(current_button, [target_index])
		
	# 초기화 
	$Cover.visible = false
	button_img.visible = false
	cancel_area.visible = false
	line.visible = false
	
	cancel_area.scale = Vector2(1, 1)
	choice_btn_man.remove_all_button()
	
	SidePanel.mode = SidePanel.Mode.HP	
		
	current_button = -1
	is_on_cancel_area = false;


func _on_button_cancel_area_mouse_entered():
	is_on_cancel_area = true
	line.visible = false
	target_index = -1
	
	choice_btn_man.make_button_special(-1)
	target_changed.emit(target_index, is_ally)

func _on_button_cancel_area_mouse_exited():
	is_on_cancel_area = false
	line.visible = true
