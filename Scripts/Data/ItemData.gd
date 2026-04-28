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

## 게임 로직 처리를 위한 클래스
class Logic:
	var buy: float = 0                 # 구매 가격
	var sell: float = 0                # 판매 가격
	var consume_on_use: bool = true    # 사용 시 소모 여부
	var battle_only: bool = false      # 전투 중에만 사용 가능 여부
	var location_limit: String = ""    # 장소 제한
	var effects: Array[EffectData] = []    # 적용될 효과 리스트

	static func from_dict(dict: Dictionary) -> Logic:
		var l = Logic.new()
		l.buy = dict.get("buy", 0)
		l.sell = dict.get("sell", 0)
		l.consume_on_use = dict.get("consume_on_use", true)
		l.battle_only = dict.get("battle_only", false)
		l.location_limit = dict.get("location_limit", "")
		for e_dict in dict.get("effects", []):
			l.effects.append(EffectData.from_dict(null, e_dict))
		return l

var id: String = ""                    # 아이템 고유 ID
var display: Display                   # 표시용 정보
var logic: Logic                       # 로직용 정보
var tags: String = ""                  # 시스템 태그

var category: String:
	get:
		return display.category

## 전체 아이템 Dictionary를 ItemData 인스턴스로 변환
static func from_dict(item_id: String, dict: Dictionary) -> ItemData:
	var item = ItemData.new()
	item.id = item_id
	item.display = Display.from_dict(dict.get("display", {}))
	item.logic = Logic.from_dict(dict.get("logic", {}))
	item.tags = dict.get("tags", "")
	return item

func _to_string():
	return "ItemData(id=%s, name=%s, category=%s)" % [id, display.name, display.category]
