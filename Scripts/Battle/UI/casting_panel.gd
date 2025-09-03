class_name CastingPanel extends Control

var callback_func: Callable
var battle_panel: BattlePanel
var button_manager: SkillButtonManager

enum CastingButtonType {
	Counter,
	Parrying
}

var twn = null
var button_skill = []

func _ready():
	visible = false
	button_manager = $SkillButtonManager as SkillButtonManager
	button_manager.get_skill_by_index = _button_manager_get_skill

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
	
func _on_end_tween():
	#print("tween End")
	twn = null
	callback_func.call(true)
		
	visible = false

func _set_button_by_type(button_type: CastingButtonType):
	var useable_skills
	match button_type:
		CastingButtonType.Counter:
			useable_skills = SkillManager.get_useable_special_skills(SkillManager.SpecialSkillType.COUNTER, battle_panel.current_charcter.point, battle_panel.manager.attribute_bar)
		CastingButtonType.Parrying:
			useable_skills = SkillManager.get_useable_special_skills(SkillManager.SpecialSkillType.PARRYING, battle_panel.current_charcter.point, battle_panel.manager.attribute_bar)

	for i in button_manager.buttons:
		i.visible = false

	button_skill.clear()
	var index = 0
	for i in useable_skills:
		button_skill.append(i)
		button_manager.buttons[index].visible = true
		index += 1
		if button_skill.size() >= 4:
			break

func _button_manager_get_skill(index):
	if index < 0 or index >= PlayerData.special_skills.size():
		return null
	return SkillManager.special_skills[PlayerData.special_skills[index]]


func _on_skill_button_manager_skill_activated(button_index, _target):
	if twn is Tween:
		twn.kill()
		twn = null
	battle_panel.manager.remove_cost(button_skill[button_index])
	battle_panel.manager.set_effect(button_skill[button_index])
	callback_func.call(false)
	visible = false
