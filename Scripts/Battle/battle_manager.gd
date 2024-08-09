extends Node3D
class_name BattleManager

# 싱글톤 형태 사용
static var instance: BattleManager

# 턴 변경을 알리는 신호
signal turn_character_changed(new_character : BattleCharacter)

# 턴 행동을 완료했음을 알리는 신호
signal turn_end

# 캐릭터들의 정보를 담은 리스트
@onready var turn_char := get_tree().get_nodes_in_group("battle_characters").duplicate()

# 현재 턴인 캐릭터의 정보
var now_character: BattleCharacter

# Called when the node enters the scene tree for the first time.
func _ready():
	BattleManager.instance = self
	
	_battle()
	
# 행동력 계산하는 함수
func _battle_set():
	var total := 0
	
	for i in turn_char:
		total += i.speed
		
	for i in turn_char:
		i.point = 50 + i.speed / total * 50
		#print(i.speed, " ", total)
		#print(i.speed / total * 50)
	
	turn_char.sort_custom(func(a, b): return a.speed > b.speed)

# 전투를 관리하는 함수 (await 이용) 
func _battle():
	_battle_set()
	
	while true:
		for i in turn_char:
			now_character = i
			turn_character_changed.emit(i)
			
			if i.is_player == true:
				print("player turn")
				
				# turn_end 신호가 emit 할때까지 대기
				await turn_end
				
			else:
				print("enemy turn")	
				# 적 AI
		#break # for test

func _on_battle_panel_skill_actived(index: ):
	match index:
		BattlePanel.Buttons.CENTER:
			print("center")
		BattlePanel.Buttons.SKILL1:
			print("skill1")
			now_character.current_point -= 10
