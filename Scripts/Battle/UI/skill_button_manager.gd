class_name SkillButtonManager extends Control

# 스킬 버튼들
var buttons: Array[RoundButton] = []
# 가운데 버튼 (반격용) 
@onready var center_button = $SkillButtons/CenterButton as RoundButton

# 버튼 이미지
@onready var button_img = $ButtonImage
# 버튼 취소 범위 원
@onready var cancel_area = $ButtonCancelArea

@onready var choice_btn_man = $ChoiceButtonManager as ChoiceButtonManager
# 버튼 사이 라인
# @onready var line = $Line2D as Line2D
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

var button_init_color: Color
var button_enable_color := Color(1, 1, 1, 1)

@export var cancel_button_size = Vector2(4, 4)

# 스킬 눌렀을 떄
signal skill_activated(button_index, target)

# 대상이 변경되었을 때
signal target_changed(target, isally)

var get_skill_by_index = null

func _ready():
	for btn in $SkillButtons.get_children():
		buttons.append(btn as RoundButton)
	# 버튼에 시그널 연결 
	for i in len(buttons):
		var btn = buttons[i] as RoundButton
		var index = i
		
		btn.button_down.connect(on_skillbutton_down.bind(btn, index))
		btn.button_up.connect(on_skillbutton_up)
	if get_skill_by_index == null or get_skill_by_index.is_null():
		get_skill_by_index = Callable(SkillManager, "get_player_skill")

	button_init_color = button_img.modulate

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
				# line.set_point_position(0, mouse)
				
				# 가장 가까운 버튼 가져와서 기존 선택된 버튼이 아니면 교체 
				var target = choice_btn_man.get_nearest_button(mouse)
				if target != target_index:
					target_index = target
					choice_btn_man.make_button_special(target_index)
					# line.set_point_position(1, choice_btn_man.get_button_center(target_index))
					
					target_changed.emit(target_index, is_ally)
			# 전체
			ChoiceMode.ALL:
				# line.visible = false
				choice_btn_man.make_button_special_all()
			# 자기 자신
			ChoiceMode.SELF:
				# line.set_point_position(0, mouse)
				# var player_button_pos = cancel_area.position + cancel_button_size / 2
				# line.set_point_position(1, player_button_pos)
				pass
	before_mouse_pos = mouse
	
# 스킬 버튼 OnOff 설정 
func set_all_buttons(OnOff: bool):
	for i in buttons:
		i.disabled = !OnOff
	
# 스킬 버튼 눌렀을 때 
func on_skillbutton_down(btn, index):
	current_button = index
	# 일단 센터 버튼이면 스킵 
	if index == battle_panel.ButtonType.CENTER:
		return
		
	# 순서 조정해서 전부 덮어씌우게 하기
	var parent = get_parent()
	parent.move_child(self, parent.get_child_count() - 1)
		
	var skill = get_skill_by_index.call(index)
	if skill == null:
		print("skill is null!")
		return
	# 가림 패널 활성화 후 마우스에 버튼 이미지 부착 
	$Cover.visible = true
	button_img.visible = true

	button_img.global_position = get_viewport().get_mouse_position() - button_img.pivot_offset
	
	# 버튼 누른 위치에 취소 크기를 설정하는 원 생성 
	cancel_area.visible = true
	cancel_area.position = btn.position
	var element = AttributeInformation.get_attribute_by_skill(skill)
	var color = AttributeInformation.get_attribute_color(element)
	cancel_area.modulate = color
	button_enable_color = color
	var tween = create_tween()
	tween.tween_property(cancel_area, "scale", cancel_button_size, 0.1)
	
	# 사이드 패널에 정보 띄우기 
	ViewManager.side_panel.set_info_panel(skill.display.name, skill.display.description)
	
	# 스킬 정보에 따라 선택 버튼 생성
	var skill_target = SkillManager.get_target(skill)
	button_cnt = 0
	
	# 대상에게 적용하기
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
		"team":
			is_ally = true
			current_choice_mode = ChoiceMode.ONE
			button_cnt = len(battle_panel.get_all_ally())
		"field":
			current_choice_mode = ChoiceMode.ALL # 필드는 모든 캐릭터 대상 혹은 별도 처리
			button_cnt = len(battle_panel.get_all_enemy()) + len(battle_panel.get_all_ally())
		"team_all": # 필요한 경우 추가
			is_ally = true
			current_choice_mode = ChoiceMode.ALL
			button_cnt = len(battle_panel.get_all_ally())
		_:
			current_choice_mode = ChoiceMode.NONE
			button_cnt = 0
		
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
	# line.visible = false
	button_cnt = 0
	current_choice_mode = ChoiceMode.NONE
	
	cancel_area.scale = Vector2(1, 1)
	choice_btn_man.remove_all_button()
	
	ViewManager.side_panel.set_hp_panel()
		
	current_button = -1
	is_on_cancel_area = false;
	
	# 순서 원래 위치로 조정
	var parent = get_parent()
	parent.move_child(self, 0)

# 마우스가 취소 지역에 들어갔을 때 
func _on_button_cancel_area_mouse_entered():
	is_on_cancel_area = true
	# line.visible = false
	target_index = -1
	button_img.modulate = button_init_color
	
	choice_btn_man.make_button_special(-1)
	target_changed.emit(target_index, is_ally)

# 마우스가 취소 지역에서 나갔을 때 
func _on_button_cancel_area_mouse_exited():
	is_on_cancel_area = false
	button_img.modulate = button_enable_color
	# line.visible = true

# 마우스가 눌러져 있음에도 스크립트로 강제로 취소시키기
func cancel_choice():
	# 안눌린 상태면 무시
	if current_button == -1:
		return
	current_button = -1
	is_on_cancel_area = true
	on_skillbutton_up()