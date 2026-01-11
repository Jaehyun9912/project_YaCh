class_name EffectManager extends Node

var effect_data: Dictionary
var battle_manager : BattleManager

var effect_list : Array = []

func init(manager: BattleManager):
	battle_manager = manager
	effect_data = DataManager.get_data_folder("Skill/Effect")

# effect_id로 효과 추가 (Skill/Effect에서 불러옴)
func add_effect_by_id(effect_id: String, target):
	var effect = effect_data.get(effect_id, null)
	if effect == null:
		printerr("Invalid effect ID: " + effect_id)
		return
	
	add_effect(effect, target, effect_id)

func add_effect(effect: Dictionary, target, source_id):
	# 효과 데이터 처리 로직 구현
	var effect_instance = {
		"data": effect,
		"target": target,
		"source_id": source_id,
		"duration": effect.get("duration", 1000000)
	}
	print("Adding effect: ", effect_instance)
	_apply_effect(effect_instance)

	var restore = effect.get("restore", false)
	var turn = effect.get("turn", "once")
	if restore or turn != "once" :
		effect_list.append(effect_instance)

# 여러 효과를 한꺼번에 추가
func add_effects(effects: Array, target, source_id):
	for effect in effects:
		add_effect(effect, target, source_id)

func remove_effects(effect_id):
	# effect_id에 일치하는 모든 효과 제거
	for i in range(effect_list.size() - 1, -1, -1):
		if effect_list[i]["source_id"] == effect_id:
			_apply_effect(effect_list[i], true)
			effect_list.remove_at(i)
		
# effect 효과를 적용함 (만약 is_remove가 true면 restore가 true일 시 제거 효과로 작동)
func _apply_effect(effect, is_remove = false):
	print("Applying effect: ", effect, ", is_remove: ", is_remove)
	# 효과 적용 로직 구현
	if is_remove:
		# 일단은 turn이 once일때만 처리
		if effect["data"].get("restore", false) and effect["data"].get("turn", "once") == "once":
			var restore_target = effect["target"]
			var restore_stat_target = effect["data"].get("target", "")
			var restore_oper = effect["data"].get("oper", "")
			var restore_value = effect["data"].get("value", 0)
			
			# 역연산 수행
			var reverse_oper = _get_reverse_oper(restore_oper)
			
			if restore_stat_target is String:
				_apply_stat_change(restore_target, restore_stat_target, reverse_oper, restore_value)
			elif restore_stat_target is Array:
				for st in restore_stat_target:
					_apply_stat_change(restore_target, st, reverse_oper, restore_value)
		return
		
	# is_remove가 false일 때 효과 적용 로직 구현
	var data = effect["data"]
	var target = effect["target"]
	var stat_targets = data.get("target", "")
	if not stat_targets is Array: stat_targets = [stat_targets]

	var oper = data.get("oper", "")
	var value = data.get("value", 0)

	# 복구가 필요한 경우 반대 연산 수행
	if is_remove:
		if not data.get("restore", false): # 단, restore가 true일 때만
			return
		oper = _get_reverse_oper(oper)

    # 모든 대상 스탯에 대해 적용
	for st in stat_targets:
		_apply_stat_change(target, st, oper, value)

func _get_reverse_oper(oper: String) -> String:
	match oper:
		"add": return "remove"
		"remove": return "add"
		"multiply": return "divide"
		"divide": return "multiply"
	return ""

func _apply_stat_change(target, stat_target: String, oper: String, value):
	# 대상이 필드 스탯인 경우
	if stat_target.begins_with("field_"):
		var actual_target = stat_target.replace("field_", "")
		var current_value = battle_manager.field_stat.get(actual_target, 1)
		
		var new_value = _calculate(current_value, oper, value)
		battle_manager.field_stat[actual_target] = new_value
		return

	# 대상이 "all"인 경우 모든 캐릭터에게 적용
	if target == "all":
		target = battle_manager.ally_character.duplicate()
		target += battle_manager.enemy_character
	
	# 대상이 단일 캐릭터인 경우
	elif not target is Array:
		target = [target]

	for character in target:
		if character is BattleCharacter:
			character.modify_stat(stat_target, oper, value)
				

# 스탯 자체 계산용 함수
func _calculate(base_value: float, oper: String, value: float) -> float:
	match oper:
		"add":
			return base_value + value
		"remove":
			return base_value - value
		"multiply":
			return base_value * value
		"divide":
			if value != 0:
				return base_value / value
			else:
				printerr("Division by zero in calculation.")
				return base_value
		_:
			printerr("Unknown operation in calculation:", oper)
			return base_value

func _process_effect(effect):
	# 효과 처리 로직 구현
	var turn_type = effect["data"].get("turn", "once")
	var duration = effect["duration"]

	duration -= 1
	var is_remove = duration <= 0
	effect["duration"] = duration

	# 턴마다 적용되는 효과 처리
	if turn_type == "every" or (turn_type == "end" and is_remove):
		_apply_effect(effect)

	return is_remove

# 턴 사이클 시작시 호출되는 함수
func _on_battle_scene_turn_cycle_start():
	for i in range(effect_list.size() - 1, -1, -1):
		var is_remove = _process_effect(effect_list[i])

		# remove_effect와 다르게 만료된 효과만 제거
		if is_remove:
			_apply_effect(effect_list[i], true)
			effect_list.remove_at(i)