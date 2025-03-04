extends Node3D
class_name BattleCharacter

signal character_died(char : BattleCharacter)

const  hp_text_string := "HP : %d / %d"
@onready var _hp_label := $HpLabel
@onready var _notify_label := $NotifyLabel
@onready var _notify_timer := $NotifyLabel/Timer

@export var speed: float
@export var mana: int
@export var max_hp: int
var attack: int

var _hp
var hp:
	get:
		return _hp
	set(value):
		var diff = value - _hp
		_hp = value
		_hp_label.text = hp_text_string % [hp, max_hp]
		
		if hp <= 0:
			_died()
		elif diff > 0:
			notify_msg(diff, Color.GREEN)
		else:
			notify_msg(diff, Color.RED)
			
# 행동력 
@export var point: int
var current_point: int

# 플레이어인지 확인용 
@export var is_player := false

# 죽었을 때 
func _died():
	character_died.emit(self)
	
# 캐릭터 위에 메세지 띄우기 
func notify_msg(msg, color):
	_notify_label.text = str(msg)
	_notify_label.modulate = color
	_notify_label.visible = true
	_notify_timer.start()
	
	await _notify_timer.timeout
	
	_notify_label.visible = false
	
func set_character(data: Dictionary, tag_id: String):
	#name = data.name
	#attack = data.attack
	#if (data.has("max_hp")):
		#max_hp = data.max_hp
	#else:
		#max_hp = data.hp
	max_hp = data.get("max_hp", data.hp)
	speed = data.speed
	mana = data.mana
	_hp = data.hp	
	_hp_label.text = hp_text_string % [hp, max_hp]
	
	# 태그 추가하기 
	TagManager.add_tag_tree(self, "Battle." + tag_id)
	#print(data)
