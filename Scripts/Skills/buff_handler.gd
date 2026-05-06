class_name BuffHandler extends RefCounted

signal buff_changed(buff: SkillBuff, is_added: bool)

class BuffEvent:
	enum Type { TURN, TIME_PASS, ACTION_POINT, LOCATION_CHANGE, ATTRIBUTE_CHANGE }
	var type: Type
	var value: float = 1.0
	var attribute: String = ""

	func _init(p_type: Type = Type.TURN, p_value: float = 1.0, p_attribute: String = ""):
		type = p_type
		value = p_value
		attribute = p_attribute

var active_buffs: Array[SkillBuff] = [] # 현재 적용된 버프들
var _target_ref: WeakRef # CharacterStat 참조

# 실제 사용 시 get_ref()를 통해 접근하는 프로퍼티
var target: CharacterStat:
	get:
		return _target_ref.get_ref() if _target_ref else null

func setup(set_target: CharacterStat):
	_target_ref = weakref(set_target)

# 버프 ID를 바탕으로 버프 생성 후 추가
func add_buff(buff_id: String, duration_add: int = 0):
	var buff = SkillManager.get_buff(buff_id)
	if not buff:
		return
		
	if duration_add != 0:
		buff.current_duration += duration_add
	add_buff_instance(buff)

# 버프 인스턴스 추가
func add_buff_instance(buff: SkillBuff):
	if not buff:
		return
		
	active_buffs.append(buff)
	buff_changed.emit(buff, true)
	
	# 즉시 발동 타입(ONCE)이거나 매번 발동(EVERY)인 경우 최초 1회 적용
	# 단, EVERY는 틱 이벤트에서도 적용됨
	if target and (buff.data.apply_type == "once" or buff.data.apply_type == "every"):
		target.apply_value_change(buff.data.target, buff.data.value)

func get_buffs(target_stat: String) -> Array[SkillBuff]:
	var result: Array[SkillBuff] = []
	for buff in active_buffs:
		if buff.data.target == target_stat:
			result.append(buff)
	return result

# 버프 업데이트 처리 (틱 발생 시 호출)
func buff_update(event: BuffEvent):
	if not target:
		return

	var expired_buffs: Array[SkillBuff] = []
	
	# 복사본을 순회하여 업데이트 중 리스트 변경 방지
	var current_buffs = active_buffs.duplicate()
	
	for buff in current_buffs:
		# 1. 틱 효과 적용 (EVERY 타입)
		if buff.data.apply_type == "every" and buff.is_tick_event(event):
			# 첫 번째 틱 건너뛰기 설정 확인
			if buff.data.duration.skip_first_tick and buff.current_duration == buff.data.duration.value:
				pass # 첫 틱은 건너뜀
			else:
				target.apply_value_change(buff.data.target, buff.data.value)
		
		# 2. 지속 시간 업데이트 및 만료 체크
		if buff.check_update_logic(event):
			expired_buffs.append(buff)

	# 3. 만료된 버프 제거
	for buff in expired_buffs:
		remove_buff(buff)

# 버프 제거
func remove_buff(buff: SkillBuff):
	if buff in active_buffs:
		# 만료 시 발동 효과(END 타입) 적용
		if target and buff.data.apply_type == "end":
			target.apply_value_change(buff.data.target, buff.data.value)
			
		active_buffs.erase(buff)
		buff_changed.emit(buff, false)

		# 다음 연계 버프 발동
		if buff.data.next_buff != "":
			add_buff(buff.data.next_buff)

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
		if buff.data.id == buff_id:
			to_remove.append(buff)
	
	for buff in to_remove:
		remove_buff(buff)
