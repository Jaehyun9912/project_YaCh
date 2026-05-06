## [SkillBuff] 캐릭터에게 적용되어 실시간으로 변하는 버프/디버프 인스턴스입니다.
extends RefCounted
class_name SkillBuff

## 원본 데이터 (정적 정보)
var data: EffectData

## 실시간 상태 정보 (동적 정보)
var current_duration: float      # 남은 지속 시간/수치
var is_active: bool = true       # 현재 활성화 여부
var is_battle_buff: bool = false # 전투 전용 버프 여부

## 초기화: EffectData를 받아 인스턴스를 생성합니다.
func _init(p_data: EffectData):
	data = p_data
	current_duration = data.duration.value
	
	# 전투 중 틱(Tick) 처리가 필요한 타입인지 판단
	var d_type = data.duration.type
	is_battle_buff = d_type in ["turn", "point", "attribute_under", "attribute_upper"]

## 합산 연산(add) 인지 확인
func is_additive() -> bool:
	return data.value_type == "add"

## 현재 이벤트가 이 버프의 지속시간을 소모시키거나 체크해야 하는 이벤트인지 확인
func is_tick_event(event: BuffHandler.BuffEvent) -> bool:
	if data.duration.type == "permanent": return false
	
	match data.duration.type:
		"time":
			return event.type == BuffHandler.BuffEvent.Type.TIME_PASS
		"turn":
			return event.type == BuffHandler.BuffEvent.Type.TURN
		"point":
			return event.type == BuffHandler.BuffEvent.Type.ACTION_POINT
		"attribute_under", "attribute_upper":
			return event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == data.duration.attribute
	return false

## 버프 로직 업데이트 (지속시간 감소 및 만료 체크)
## @return: 버프가 만료되어 제거되어야 하면 true 반환
func check_update_logic(event: BuffHandler.BuffEvent) -> bool:
	if data.duration.type == "permanent":
		return false
	
	match data.duration.type:
		"time", "turn", "point":
			# 수치 기반 소모 (시간, 턴, 행동력)
			current_duration -= event.value
		"attribute_under":
			# 속성이 기준치 미만일 때 유지 (기준치 이상이면 만료)
			if event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == data.duration.attribute:
				if event.value >= data.duration.value: return true
		"attribute_upper":
			# 속성이 기준치 초과일 때 유지 (기준치 이하이면 만료)
			if event.type == BuffHandler.BuffEvent.Type.ATTRIBUTE_CHANGE and event.attribute == data.duration.attribute:
				if event.value <= data.duration.value: return true

	return current_duration <= 0.0
