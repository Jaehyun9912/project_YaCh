## [BattleData] 전투(Battle) 시나리오 정보를 담는 데이터 클래스입니다.
class_name BattleData
extends RefCounted

## UI 및 표시 정보 클래스
class Display:
	var name: String = ""              # 전투 이름
	var description: String = ""       # 전투 설명

	static func from_dict(dict: Dictionary) -> Display:
		var d = Display.new()
		d.name = dict.get("name", "")
		d.description = dict.get("description", "")
		return d

## 전투 환경 관련 설정 클래스
class BEnvironment:
	var attribute_limit: float = 100   # 속성치 최대 제한
	var initial_points: float = 100    # 초기 행동 포인트

	static func from_dict(dict: Dictionary) -> BEnvironment:
		var e = BEnvironment.new()
		e.attribute_limit = dict.get("attribute_limit", 100)
		e.initial_points = dict.get("initial_points", 100)
		return e

## 개별 전투 웨이브 클래스
class Wave:
	## 웨이브에 등장하는 개별 적 엔트리 클래스
	class EnemyEntry:
		var enemy_id: String = ""      # Enemy 데이터 ID 참조
		var override_stats: Dictionary = {} # 능력치 덮어쓰기 설정
		var inline_enemy: Dictionary = {} # 직접 정의된 적 데이터

		static func from_dict(dict: Dictionary) -> EnemyEntry:
			var e = EnemyEntry.new()
			e.enemy_id = dict.get("enemy_id", "")
			e.override_stats = dict.get("override_stats", {})
			e.inline_enemy = dict.get("inline_enemy", {})
			return e

	var wave_name: String = ""         # 웨이브 이름
	var bg_image: String = ""          # 웨이브 전용 배경 이미지
	var enemies: Array[EnemyEntry] = [] # 등장 적 리스트

	static func from_dict(dict: Dictionary) -> Wave:
		var w = Wave.new()
		w.wave_name = dict.get("wave_name", "")
		w.bg_image = dict.get("bg_image", "")
		for e_dict in dict.get("enemies", []):
			w.enemies.append(EnemyEntry.from_dict(e_dict))
		return w

## 전투 승리 시 보상 클래스
class Rewards:
	## 획득 아이템 정보 클래스
	class ItemReward:
		var id: String = ""            # 아이템 ID
		var count: int = 1             # 개수
		var chance: float = 1.0        # 획득 확률 (0~1)

		static func from_dict(dict: Dictionary) -> ItemReward:
			var i = ItemReward.new()
			i.id = dict.get("id", "")
			i.count = dict.get("count", 1)
			i.chance = dict.get("chance", 1.0)
			return i

	var gold: Variant = 0              # 골드 보상 (고정값 또는 랜덤 범위)
	var items: Array[ItemReward] = []  # 획득 아이템 리스트

	static func from_dict(dict: Dictionary) -> Rewards:
		var r = Rewards.new()
		r.gold = dict.get("gold", 0)
		for i_dict in dict.get("items", []):
			r.items.append(ItemReward.from_dict(i_dict))
		return r

## 전투 종료 후의 상태 전이(이동) 설정 클래스
class Transitions:
	## 각 결과(승리/패배) 시의 설정 클래스
	class StateConfig:
		var to_location: String = ""   # 이동할 장소 ID
		var message: String = ""       # 출력할 메시지

		static func from_dict(dict: Dictionary) -> StateConfig:
			var s = StateConfig.new()
			s.to_location = dict.get("to_location", "")
			s.message = dict.get("message", "")
			return s

	var entry_location: String = ""    # 진입 시 위치 ID
	var on_win: StateConfig            # 승리 시 처리
	var on_lose: StateConfig           # 패배 시 처리

	static func from_dict(dict: Dictionary) -> Transitions:
		var t = Transitions.new()
		t.entry_location = dict.get("entry_location", "")
		t.on_win = StateConfig.from_dict(dict.get("on_win", {}))
		t.on_lose = StateConfig.from_dict(dict.get("on_lose", {}))
		return t

var id: String = ""                    # 전투 고유 ID
var display: Display                   # 표시 정보
var environment: BEnvironment           # 환경 설정 정보
var waves: Array[Wave] = []            # 웨이브 구성 정보
var rewards: Rewards                   # 보상 정보
var transitions: Transitions           # 전이 정보

static func from_dict(battle_id: String, dict: Dictionary) -> BattleData:
	var battle = BattleData.new()
	battle.id = battle_id
	battle.display = Display.from_dict(dict.get("display", {}))
	battle.environment = BEnvironment.from_dict(dict.get("environment", {}))
	for w_dict in dict.get("waves", []):
		battle.waves.append(Wave.from_dict(w_dict))
	battle.rewards = Rewards.from_dict(dict.get("rewards", {}))
	battle.transitions = Transitions.from_dict(dict.get("transitions", {}))
	return battle
