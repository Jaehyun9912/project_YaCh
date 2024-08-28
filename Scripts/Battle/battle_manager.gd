extends Node3D
class_name BattleManager

# 턴 변경을 알리는 신호
signal turn_character_changed(new_character : BattleCharacter)

# 턴 행동을 완료했음을 알리는 신호
signal turn_end

# 행동력 포인트 (나중에 변수로 변경해도 무방)
const BASE_POINT = 50
const ADDITIONAL_POINT = 50

# 가장 적은 포인트를 사용하는 행동 (자동 턴 넘기기 용)
var min_point_use = 10

# 캐릭터들의 정보를 담은 리스트
@onready var turn_char := get_tree().get_nodes_in_group("battle_characters").duplicate()
var player_character : BattleCharacter
var enemy_character : Array[BattleCharacter]

# 현재 턴인 캐릭터의 정보
var now_character: BattleCharacter

# 죽은 캐릭터 행동 이후 처리용 
var dead_player: Array[BattleCharacter]

# Called when the node enters the scene tree for the first time.
func _ready():
	_battle()
	
# 행동력 계산하는 함수
func _battle_set():
	var total := 0
	
	for i in turn_char:
		if i.is_player == true:
			player_character = i
		else:
			enemy_character.append(i)
		
		i.character_died.connect(_on_character_died)
		total += i.speed
		
	for i in turn_char:
		i.point = BASE_POINT + i.speed / total * ADDITIONAL_POINT
		#print(i.speed, " ", total)
		print(i.name, " ", i.speed / total * ADDITIONAL_POINT)
	
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
				await get_tree().create_timer(0.5).timeout
				player_character.hp -= 10
				# 적 AI
			
			_check_dead_char()
						
			print("turn end")
		#break # for test

# 버튼 눌렀을때
func _on_battle_panel_skill_actived(index):
	match index:
		BattlePanel.Buttons.CENTER:
			print("center")
			turn_end.emit()
		BattlePanel.Buttons.SKILL1:
			print("skill1")
			now_character.current_point -= 10
			for i in enemy_character:
				i.hp -= 10
		BattlePanel.Buttons.RUN:
			_battle_end(0)		
				
	if now_character.current_point < min_point_use:
			turn_end.emit()
			
	_check_dead_char()
	
# 죽은 캐릭터 처리하는 함수
func _check_dead_char():
# 턴 종료 후 사망한 캐릭터 처리
	while dead_player.size() > 0:
		var dead = dead_player.pop_back()
		
		if dead == player_character:
			print("player dead")
			_battle_end(2)
		else:
			dead.queue_free()
			enemy_character.erase(dead)
		
			if enemy_character.size() == 0:
				_battle_end(1)
	
# 일단 임시로 정수형태로 해놓았으나 나중에 컨디션이나 태그를 받도록 수정할 예정
func _battle_end(type):
	# 도망, 적 전부 처치 전투 종료 구현하기 
	
	$InteractPanel/BattlePanel.set_all_button(false)
	var msg = $InteractPanel/EndMsg as Label
	
	match type:
		0:
			msg.text = "전투에서 도망쳤다!"
		1:
			msg.text = "전투에서 승리했다!"
		2:
			msg.text = "전투에서 패배했다!"
	
	await get_tree().create_timer(2).timeout
	
	queue_free()

# 캐릭터가 사망할시 일단 배열에 넣어놓고 나중에 처리
func _on_character_died(dead : BattleCharacter):
	print(dead.name, "is dead")
	dead_player.append(dead)
