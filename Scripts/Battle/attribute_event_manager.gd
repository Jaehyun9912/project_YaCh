class_name AttributeEventManager extends Node

var _attribute_bar : AttributeBar
var _battle_manager : BattleManager

func init(attribute: AttributeBar, battle_manager: BattleManager):
	_attribute_bar = attribute
	_attribute_bar.attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	_attribute_bar.attribute_threshold_recovered.connect(_on_threshold_recovered)
	_battle_manager = battle_manager

func _on_threshold_exceeded(attribute_name: String, active_type: AttributeBar.ThresholdActiveType):
	print("Threshold Exceeded for attribute: %s, Type: %s" % [attribute_name, str(active_type)])
	var attribute = AttributeInformation.get_attribute(attribute_name)
	if attribute == null:
		printerr("Invalid attribute name: " + attribute_name)
		return
		
	var effects = attribute["overdrive"].get("effects", [])
	if effects.is_empty():
		return
		
	# 효과 적용
	for i in range(effects.size()):
		var data = effects[i]
		# 임시 ID 생성 overwrite 방지: 속성과 인덱스 조합
		var buff_id = "%s_overdrive_%d" % [attribute_name, i]
		var buff = SkillBuff.create_from_dict(buff_id, data)
		
		_apply_overdrive_buff(buff)

func _apply_overdrive_buff(buff: SkillBuff):
	# 필드 효과는 아직 미구현
	# if buff.target.begins_with("field_"):
		# print("Field effect not implemented yet: ", buff.id)
		# return
		
	# 모든 캐릭터에게 적용
	var targets = []
	if _battle_manager.player_character:
		targets.append(_battle_manager.player_character)
	targets.append_array(_battle_manager.enemy_character)
	
	for character in targets:
		if character and character.stat_manager:
			character.stat_manager.add_buff_object(buff)
			print("Overdrive buff applied to %s: %s" % [character.name, buff.id])


func _on_threshold_recovered(attribute_name: String):
	print("Threshold Recovered for attribute: %s" % attribute_name)
	# _battle_manager.effect_manager.remove_effects(attribute_name)
	# TODO: 오버드라이브 해제 로직 구현 필요 (BuffHandler에서 제거)

