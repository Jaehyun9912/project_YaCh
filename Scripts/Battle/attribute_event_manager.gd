class_name AttributeEventManager extends Node

var _attribute_bar : AttributeBar
var _battle_manager : BattleManager

# 임계점을 넘은 속성 (보톡 높은 수치라 1개만 저장)
# KEEP 타입의 경우에만 사용
var exceeded_attribute
var exceeded_effects

func init(attribute: AttributeBar, battle_manager: BattleManager):
	_attribute_bar = attribute
	_attribute_bar.attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	_attribute_bar.attribute_threshold_recovered.connect(_on_threshold_recovered)
	_battle_manager = battle_manager

# 속성 임계점 도달 시 처리
func _on_threshold_exceeded(attribute_name: String, active_type: AttributeBar.ThresholdActiveType):
	print("Threshold Exceeded for attribute: %s, Type: %s" % [attribute_name, str(active_type)])
	var attribute = AttributeInformation.get_attribute(attribute_name)
	if attribute == null:
		printerr("Invalid attribute name: " + attribute_name)
		return
	var overdrive = attribute.get("overdrive", {})
	
	match active_type:
		AttributeBar.ThresholdActiveType.EXPLODE:
			# 광역 효과 처리
			_apply_effect(attribute_name, overdrive.get("effects", []))
		AttributeBar.ThresholdActiveType.KEEP:
			exceeded_attribute = attribute_name
			exceeded_effects = overdrive.get("effects", [])
			_apply_effect(attribute_name, exceeded_effects)

func _apply_effect(source_attr, buffs):
	var ally_character = _battle_manager.ally_character
	var enemy_character = _battle_manager.enemy_character

	for buff in buffs:
		var skill_buff = SkillBuff.create_from_dict("attribute_" + source_attr, buff)
		skill_buff.is_battle_buff = true

		# 버프 대상이 속성일 경우
		if skill_buff.target in AttributeInformation.attribute.keys():
			_battle_manager.field_stat[skill_buff.target] += skill_buff.value
		else:
			# 버프 대상이 능력치일 경우
			for character in ally_character:
				character.add_buff_object(skill_buff)
			for character in enemy_character:
				character.add_buff_object(skill_buff)

# 속성 임계점 회복 시 처리 (KEEP Only)
func _on_threshold_recovered(attribute_name: String):
	print("Threshold Recovered for attribute: %s" % attribute_name)
	
	if exceeded_attribute == attribute_name:
		exceeded_attribute = ""
		exceeded_effects = []

	for character in _battle_manager.ally_character:
		character.buff_handler.remove_buffs_by_id("attribute_" + attribute_name)
	for character in _battle_manager.enemy_character:
		character.buff_handler.remove_buffs_by_id("attribute_" + attribute_name)

# 턴 사이클 시작 시 처리
func _on_battle_scene_turn_cycle_start():
	# 원래는 KEEP일 경우 매턴 효과를 적용하려고 했으나
	# 현재는 한번 적용 -> 회복 시 제거로 변경
	pass # Replace with function body.
