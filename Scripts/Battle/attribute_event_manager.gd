class_name AttributeEventManager extends Node

var _attribute_bar : AttributeBar
var _battle_manager : BattleManager

# 임계점을 넘은 속성 (보통 높은 수치라 1개만 저장)
# KEEP 타입의 경우에만 사용
var exceeded_attribute : String = ""
var exceeded_effects : Array[EffectData] = []

func init(attribute: AttributeBar, battle_manager: BattleManager):
	_attribute_bar = attribute
	_attribute_bar.attribute_threshold_exceeded.connect(_on_threshold_exceeded)
	_attribute_bar.attribute_threshold_recovered.connect(_on_threshold_recovered)
	_battle_manager = battle_manager

# 속성 임계점 도달 시 처리
func _on_threshold_exceeded(attribute_name: String, active_type: AttributeData.Overdrive.OverdriveType):
	print("Threshold Exceeded for attribute: %s, Type: %s" % [attribute_name, str(active_type)])
	var attribute_info = AttributeInformation.get_attribute(attribute_name)
	if attribute_info == null:
		printerr("Invalid attribute name: " + attribute_name)
		return
	var overdrive = attribute_info.overdrive
	
	match active_type:
		AttributeData.Overdrive.OverdriveType.EXPLODE:
			# 즉발형 효과 처리
			_apply_effect(overdrive.effects)
		AttributeData.Overdrive.OverdriveType.KEEP:
			# 지속형 효과 처리 (기존 효과가 있다면 제거 후 갱신 - 이론상 1개만 발생)
			if exceeded_attribute != "":
				_on_threshold_recovered(exceeded_attribute)
				
			exceeded_attribute = attribute_name
			exceeded_effects = overdrive.effects
			_apply_effect(exceeded_effects)

func _apply_effect(effects: Array[EffectData]):
	var ally_character = _battle_manager.ally_character
	var enemy_character = _battle_manager.enemy_character

	for effect_data in effects:
		# 버프 대상이 속성(field_stat)일 경우
		if effect_data.target in AttributeInformation.attribute.keys():
			_battle_manager.field_stat[effect_data.target] += effect_data.value
		else:
			# 버프 대상이 일반 능력치일 경우 캐릭터들에게 부여
			var skill_buff = SkillBuff.new(effect_data)
			skill_buff.is_battle_buff = true

			for character in ally_character:
				character.add_buff_object(skill_buff)
			for character in enemy_character:
				character.add_buff_object(skill_buff)

# 속성 임계점 회복 시 처리 (KEEP Only)
func _on_threshold_recovered(attribute_name: String):
	print("Threshold Recovered for attribute: %s" % attribute_name)
	
	if exceeded_attribute == attribute_name:
		# 1. 필드 효과(field_stat) 복구
		for effect_data in exceeded_effects:
			if effect_data.target in AttributeInformation.attribute.keys():
				_battle_manager.field_stat[effect_data.target] -= effect_data.value
		
		exceeded_attribute = ""
		exceeded_effects = []

	# 2. 캐릭터들에게 걸린 해당 속성 기반 버프들 제거 (ID 기반)
	var buff_id = "attribute_" + attribute_name
	for character in _battle_manager.ally_character:
		character.stat_manager.remove_buffs_by_id(buff_id)
	for character in _battle_manager.enemy_character:
		character.stat_manager.remove_buffs_by_id(buff_id)

# 턴 사이클 시작 시 처리
func _on_battle_scene_turn_cycle_start():
	pass 
