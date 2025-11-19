class_name CastingPanel extends Control

var callback_func: Callable
var battle_panel: BattlePanel
var button_manager: SkillButtonManager

var useable_skills

enum CastingButtonType {
	Counter,
	Parrying,
	CounterPlayer,
	ParryingPlayer
}

var twn = null

func _ready():
	visible = false
	button_manager = $SkillButtonManager as SkillButtonManager
	button_manager.get_skill_by_index = _button_manager_get_skill

# 캐스팅 버튼 설정하기
func set_casting_panel(text, time, button_type: CastingButtonType, callback: Callable):
	visible = true
	$Label.text = text

	_set_button_by_type(button_type)

	callback_func = callback
	
	var progress = $ProgressBar as ProgressBar
	progress.value = 0
	
	twn = create_tween() as Tween
	twn.tween_property(progress, "value", 100, time)
	twn.finished.connect(_on_end_tween)
	
# 캐스팅이 성공적으로 종료되었을 때 
func _on_end_tween():
	#print("tween End")
	twn = null
	callback_func.call(true)
	button_manager.cancel_choice()
		
	visible = false

# 버튼 타입에 따라 사용 가능한 스킬 설정
func _set_button_by_type(button_type: CastingButtonType):
	match button_type:
		CastingButtonType.Counter:
			useable_skills = SkillManager.get_useable_special_skills(SkillManager.SpecialSkillType.COUNTER, battle_panel.current_charcter.point, battle_panel.manager.attribute_bar)
		CastingButtonType.Parrying:
			useable_skills = SkillManager.get_useable_special_skills(SkillManager.SpecialSkillType.PARRYING, battle_panel.current_charcter.point, battle_panel.manager.attribute_bar)
		_:
			useable_skills = []

	# print("useable_skills: ", useable_skills)
	var index = 0
	for i in useable_skills:
		button_manager.buttons[index].visible = true
		button_manager.buttons[index].set_text(SkillManager.special_skills[i].get("name", ""))
		index += 1
		if index >= 4:
			break
	for j in range(index, 4):
		button_manager.buttons[j].visible = false
		
# 스킬 버튼 매니저가 스킬 정보를 얻어올 때 호출하는 함수
func _button_manager_get_skill(index):
	if index < 0 or index >= useable_skills.size():
		return null
	return SkillManager.special_skills[useable_skills[index]]

# 스킬 버튼 매니저에서 스킬이 선택되었을 때 호출되는 함수
func _on_skill_button_manager_skill_activated(button_index, _target):
	if twn is Tween:
		twn.kill()
		twn = null
	callback_func.call(false)

	# 카운터/패링 스킬 코스트, 이펙트 적용
	var skill = SkillManager.special_skills[useable_skills[button_index]]
	battle_panel.manager.remove_cost(skill)
	battle_panel.manager.set_effect(skill)
	
	visible = false
