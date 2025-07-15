class_name SkillButtonManager extends Control

# 스킬 버튼들
@onready var buttons = get_tree().get_nodes_in_group("skill_buttons")
# 버튼 이미지
@onready var button_img = $ButtonImage
# 버튼 취소 범위 원
@onready var cancel_area = $ButtonCancelArea

@onready var choice_btn_man = $ChoiceButtonManager as ChoiceButtonManager
# 버튼 사이 라인
@onready var line = $Line2D as Line2D
# 상위 오브젝트
var battle_panel: BattlePanel

# 현재 버튼 상태 
var current_button := -1
var target_index := -1
var is_on_cancel_area := false

# 내부 정보 
var is_ally: bool
enum ChoiceMode {NONE, ONE, ALL, SELF}
var current_choice_mode: ChoiceMode
var button_cnt := 0
var before_mouse_pos

@export var cancel_button_size = Vector2(4, 4)

# 스킬 눌렀을 떄
signal skill_activated(button_index, target)

# 대상이 변경되었을 때
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
	
	var mouse = make_input_local(event).position
	
	mouse.x = clamp(mouse.x, 0, size.x)
	mouse.y = clamp(mouse.y, 0, size.y)
	
	button_img.position = mouse - button_img.pivot_offset
	
	# 취소 범위 밖에 있으면 버튼 선택하게 만들기 
	if not is_on_cancel_area:
		match current_choice_mode:
			# 한명만 
			ChoiceMode.ONE:
				# 직선 최신화 
				line.set_point_position(0, mouse)
				
				# 가장 가까운 버튼 가져와서 기존 선택된 버튼이 아니면 교체 
				var target = choice_btn_man.get_nearest_button(mouse)
				if target != target_index:
					target_index = target
					choice_btn_man.make_button_special(target_index)
					line.set_point_position(1, choice_btn_man.get_button_center(target_index))
					
					target_changed.emit(target_index, is_ally)
			# 전체
			ChoiceMode.ALL:
				line.visible = false
				choice_btn_man.make_button_special_all()
			# 자기 자신
			ChoiceMode.SELF:
				line.set_point_position(0, mouse)
				var player_button_pos = cancel_area.position + cancel_button_size / 2
				line.set_point_position(1, player_button_pos)
	before_mouse_pos = mouse
	
# 스킬 버튼 OnOff 설정 
func set_all_buttons(OnOff: bool):
	for i in buttons:
		i.disabled = !OnOff
	
# 스킬 버튼 눌렀을 때 
func on_skillbutton_down(btn, index):
	current_button = index
	# 일단 센터 버튼이면 스킵 
	if index == battle_panel.Buttons.CENTER:
		return
	var skill = SkillManager.get_player_skill(index)
	
	# 가림 패널 활성화 후 마우스에 버튼 이미지 부착 
	$Cover.visible = true
	button_img.visible = true

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
	button_cnt = 0
	
	# 대상에게 적용하기
	# 문자열일 때 (attack, effect(self))
	if skill_target is String:
		is_ally = false
		match skill_target:
			"one":
				current_choice_mode = ChoiceMode.ONE
				button_cnt = len(battle_panel.get_all_enemy())
			"all":
				current_choice_mode = ChoiceMode.ALL
				button_cnt = len(battle_panel.get_all_enemy())
			"self":
				current_choice_mode = ChoiceMode.SELF
				button_cnt = 0
		
	# Dictionary일 때 (effect, summon, field)
	elif skill_target is Dictionary:
		is_ally = skill_target.get("team", false)
		var is_all = skill_target.get("is_all", false)
		if is_all:
			current_choice_mode = ChoiceMode.ALL
		else:
			current_choice_mode = ChoiceMode.ONE
		
		# 타겟 유형에 따라 적/아군 개수 가져오기 
		if is_ally:
			button_cnt = len(battle_panel.get_all_ally())
		else:
			button_cnt = len(battle_panel.get_all_enemy())
		
	# 선택 시작
	# 0 -> 오른쪽에 적 버튼 생성
	# 3 -> 왼쪽에 적 버튼 생성
	# 1, 2 -> 위쪽에 적 버튼 생성 
	match index:
		0:
			choice_btn_man.set_choice_button(button_cnt, btn.global_position, -30, 90)
		1:
			choice_btn_man.set_choice_button(button_cnt, btn.global_position, -90, 90)
		2:
			choice_btn_man.set_choice_button(button_cnt, btn.global_position, -90, -90)
		3:
			choice_btn_man.set_choice_button(button_cnt, btn.global_position, 160, 90)
	
# 스킬 버튼 뗐을 때 
func on_skillbutton_up():
	target_changed.emit(-1, is_ally)
	# 스킬 발동 
	# 센터 버튼도 넘기긴 해야해서 센터버튼부터는 다 넘겨버림 
	if is_on_cancel_area == false or current_button > 3:
		var target
		match current_choice_mode:
			ChoiceMode.ONE:
				target = [target_index]
			ChoiceMode.ALL:
				target = range(button_cnt)
			ChoiceMode.SELF:
				target = "self"
		skill_activated.emit(current_button, target)
		
	# 초기화 
	$Cover.visible = false
	button_img.visible = false
	cancel_area.visible = false
	line.visible = false
	button_cnt = 0
	current_choice_mode = ChoiceMode.NONE
	
	cancel_area.scale = Vector2(1, 1)
	choice_btn_man.remove_all_button()
	
	SidePanel.set_hp_panel()
		
	current_button = -1
	is_on_cancel_area = false;

# 마우스가 취소 지역에 들어갔을 때 
func _on_button_cancel_area_mouse_entered():
	is_on_cancel_area = true
	line.visible = false
	target_index = -1
	
	choice_btn_man.make_button_special(-1)
	target_changed.emit(target_index, is_ally)

# 마우스가 취소 지역에서 나갔을 때 
func _on_button_cancel_area_mouse_exited():
	is_on_cancel_area = false
	line.visible = true
