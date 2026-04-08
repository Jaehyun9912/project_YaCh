## [EnemyData] 적(Enemy)의 기본 정보를 담는 데이터 클래스입니다.
class_name EnemyData
extends RefCounted

## UI 및 에셋 관련 표시 정보 클래스
class Display:
	var name: String = ""              # 적 이름
	var description: String = ""       # 적 설명
	var asset: String = "res://icon.svg" # 전투 시 사용할 리소스 경로

	static func from_dict(dict: Dictionary) -> Display:
		var d = Display.new()
		d.name = dict.get("name", "")
		d.description = dict.get("description", "")
		d.asset = dict.get("asset", "res://icon.svg")
		return d

## 적의 기본 능력치 클래스
class Stats:
	var hp: float = 100.0              # 최대 체력
	var attack: float = 10.0           # 공격력
	var defense: float = 0.0           # 방어력
	var speed: float = 10.0            # 속도
	var mana: float = 0.0              # 최대 마나

	static func from_dict(dict: Dictionary) -> Stats:
		var s = Stats.new()
		s.hp = dict.get("hp", 100.0)
		s.attack = dict.get("attack", 10.0)
		s.defense = dict.get("defense", 0.0)
		s.speed = dict.get("speed", 10.0)
		s.mana = dict.get("mana", 0.0)
		return s

var id: String = ""                    # 적 고유 ID
var display: Display                   # 표시 정보
var stats: Stats                       # 능력치 정보
var skills: Array[String] = []         # 보유 스킬 ID 리스트
var ai_type: String = "default"        # 행동 패턴 AI 타입

static func from_dict(enemy_id: String, dict: Dictionary) -> EnemyData:
	var enemy = EnemyData.new()
	enemy.id = enemy_id
	enemy.display = Display.from_dict(dict.get("display", {}))
	enemy.stats = Stats.from_dict(dict.get("stats", {}))
	enemy.skills = []
	for s in dict.get("skills", []):
		enemy.skills.append(str(s))
	enemy.ai_type = dict.get("ai_type", "default")
	return enemy
