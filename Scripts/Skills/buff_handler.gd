class_name BuffHandler extends RefCounted

signal buff_changed(buff: SkillBuff, is_added: bool)

class BuffEvent:
	enum Type { TURN, TIME_PASS, ACTION_POINT, LOCATION_CHANGE, ATTRIBUTE_CHANGE }
	var type: Type
	var value
	var attribute: String = ""

var active_buffs: Array[SkillBuff] = [] # 현재 적용된 버프들 (List)
var _target_ref: WeakRef # RefCounted간 순환 참조 방지용


# 실제 사용 시 get_ref()를 통해 접근하는 프로퍼티
var target: CharacterStat:
	get:
		return _target_ref.get_ref() if _target_ref else null

func setup(set_target: CharacterStat):
	_target_ref = weakref(set_target)

# 버프 ID를 바탕으로 버프 생성 후 추가
func add_buff(buff_id: String):
	var buff = SkillManager.get_buff(buff_id)
	if not buff:
		push_error("BuffHandler: Failed to add buff. Buff ID not found: " + buff_id)
		return
	add_buff_instance(buff)

# 버프 오브젝트를 바탕으로 인스턴스 생성 후 추가
func add_buff_instance(buff: SkillBuff):
	if not buff:
		return
		
	active_buffs.append(buff)
	print("Buff added: ", buff.id)
	buff_changed.emit(buff, true)
	
	if target and buff.apply_type == SkillBuff.ApplyType.ONCE:
		target.apply_value_change(buff.target, buff.value)

func get_buffs(target_stat: String) -> Array[SkillBuff]:
	# 특정 스탯에 적용되는 버프들 필터링하여 반환
	var result: Array[SkillBuff] = []
	for buff in active_buffs:
		if buff.target == target_stat:
			result.append(buff)
	return result

# 버프 업데이트 처리
func buff_update(event: BuffEvent):
	if not target: # CharacterStat이 이미 지워졌다면 중단
		return
		
	for buff in active_buffs:
		# 매번 발동하는 타입이고, 이번 이벤트가 틱이라면 적용
		if buff.apply_type == SkillBuff.ApplyType.EVERY and buff.is_tick_event(event):
			target.apply_value_change(buff.target, buff.value)
		
	var expired_buffs: Array[SkillBuff] = []
	for buff in active_buffs:
		if buff.check_update_logic(event):
			expired_buffs.append(buff)

	for buff in expired_buffs:
		remove_buff(buff)
		print("BuffHandler: Buff expired: ", buff.id)

# 버프 제거
func remove_buff(buff: SkillBuff):
	if buff in active_buffs:
		if target and buff.apply_type == SkillBuff.ApplyType.END:
			target.apply_value_change(buff.target, buff.value)
			
		active_buffs.erase(buff)
		buff_changed.emit(buff, false)

		if buff.next_buff != "":
			add_buff(buff.next_buff)

# 전투 관련 버프 모두 제거
func clear_battle_buffs():
	var to_remove: Array[SkillBuff] = []
	for buff in active_buffs:
		if buff.is_battle_buff:
			to_remove.append(buff)
	
	for buff in to_remove:
		remove_buff(buff)

# 특정 ID를 가진 버프 모두 제거
func remove_buffs_by_id(buff_id: String):
	var to_remove: Array[SkillBuff] = []
	for buff in active_buffs:
		if buff.id == buff_id:
			to_remove.append(buff)
	
	for buff in to_remove:
		remove_buff(buff)