extends Node3D
class_name BattleManager

# 싱글톤 형태 사용
static var instance: BattleManager

# 턴 변경을 알리는 신호
signal turn_character_changed(new_character : BattleCharacter)

# 턴 행동을 완료했음을 알리는 신호
signal turn_end

# 캐릭터들의 정보를 담은 리스트
@export var characters: Array[BattleCharacter]

@onready var turn_char := characters.duplicate()

# Called when the node enters the scene tree for the first time.
func _ready():
	BattleManager.instance = self
	
	_battle_set()
	_battle()
	
# 행동력 계산하는 함수
func _battle_set():
	var total := 0
	
	for i in turn_char:
		total += i.speed
		
	for i in turn_char:
		i.point = 50 + i.speed / total * 50
		print(i.speed, " ", total)
		print(i.speed / total * 50)
	
	turn_char.sort_custom(func(a, b): return a.point > b.point)
	for i in turn_char:
		print(i.point, " ", i.speed)

# 전투를 관리하는 함수 (await 이용) 
func _battle():
	while true:
		for i in turn_char:
			turn_character_changed.emit(i)
			
			if i.is_player == true:
				print("player turn")
				await turn_end
			else:
				print("enemy turn")
				pass
				# 적 AI
	
	
