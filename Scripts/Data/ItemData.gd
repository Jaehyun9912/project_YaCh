## [ItemData] 아이템의 모든 정보를 담는 데이터 클래스입니다.
class_name ItemData
extends RefCounted

## UI 및 게임 내 표시용 데이터 클래스
class Display:
	var name: String = ""              # 아이템 이름
	var description: String = ""       # 아이템 설명
	var category: String = "none"      # 카테고리 (none, useable, quest, equipment, artifact)
	var rarity: String = "common"      # 희귀도 (common, rare, epic, legendary)
	var icon: String = "res://icon.svg" # 아이콘 경로
	var sound: String = ""             # 효과음 경로

	## Dictionary 데이터를 Display 인스턴스로 변환
	static func from_dict(dict: Dictionary) -> Display:
		var d = Display.new()
		d.name = dict.get("name", "")
		d.description = dict.get("description", "")
		d.category = dict.get("category", "none")
		d.rarity = dict.get("rarity", "common")
		d.icon = dict.get("icon", "res://icon.svg")
		d.sound = dict.get("sound", "")
		return d

## 아이템 효과 및 로직 관련 데이터 클래스
class Effect:
	## 효과 지속 시간 설정
	class Duration:
		var type: String = "turn"      # 지속 타입 (turn, time, permanent)
		var value: float = 0           # 지속 수치
		
		static func from_dict(dict: Dictionary) -> Duration:
			var d = Duration.new()
			d.type = dict.get("type", "turn")
			d.value = dict.get("value", 0)
			return d

	var target: String = "hp"          # 효과 대상 (hp, max_hp 등)
	var value_type: String = "add"     # 연산 방식 (add: 합산, multiplier: 곱셈)
	var value: float = 0.0             # 효과 수치
	var priority: int = 0              # 적용 우선순위
	var apply_type: String = "once"    # 적용 타이밍 (once: 즉시, every: 매 틱, end: 종료 시)
	var restore: bool = false          # 효과 종료 시 복구 여부
	var duration: Duration             # 지속 시간 설정
	var next_buff: String = ""         # 연계 버프 ID

	static func from_dict(dict: Dictionary) -> Effect:
		var e = Effect.new()
		e.target = dict.get("target", "hp")
		e.value_type = dict.get("value_type", "add")
		e.value = dict.get("value", 0.0)
		e.priority = dict.get("priority", 0)
		e.apply_type = dict.get("apply_type", "once")
		e.restore = dict.get("restore", false)
		e.duration = Duration.from_dict(dict.get("duration", {}))
		e.next_buff = dict.get("next_buff", "")
		return e

## 게임 로직 처리를 위한 클래스
class Logic:
	var max_stack: int = 1             # 최대 중첩 개수
	var buy: float = 0                 # 구매 가격
	var sell: float = 0                # 판매 가격
	var consume_on_use: bool = true    # 사용 시 소모 여부
	var location_limit: String = ""    # 장소 제한
	var effects: Array[Effect] = []    # 적용될 효과 리스트

	static func from_dict(dict: Dictionary) -> Logic:
		var l = Logic.new()
		l.max_stack = dict.get("max_stack", 1)
		l.buy = dict.get("buy", 0)
		l.sell = dict.get("sell", 0)
		l.consume_on_use = dict.get("consume_on_use", true)
		l.location_limit = dict.get("location_limit", "")
		for e_dict in dict.get("effects", []):
			l.effects.append(Effect.from_dict(e_dict))
		return l

var id: String = ""                    # 아이템 고유 ID
var display: Display                   # 표시용 정보
var logic: Logic                       # 로직용 정보
var tags: String = ""                  # 시스템 태그

## 전체 아이템 Dictionary를 ItemData 인스턴스로 변환
static func from_dict(item_id: String, dict: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.id = item_id
	item.display = Display.from_dict(dict.get("display", {}))
	item.logic = Logic.from_dict(dict.get("logic", {}))
	item.tags = dict.get("tags", "")
	return item
