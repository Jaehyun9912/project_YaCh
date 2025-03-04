extends Node
class_name EnemyManager

@onready var battle = $".." as BattleManager
@onready var timer = $EnemyTimer as Timer

var player: 
	get: return battle.player_character

func _on_battle_scene_turn_character_changed(char: BattleCharacter):
	if char.is_player == true: return
	
	timer.start(1)
	await timer.timeout
	
	player.hp -= 5
	
	battle.turn_end.emit()
