extends Node3D
class_name BattleCharacter

signal character_died(char : BattleCharacter)

var hp_text_string := "HP : %d / %d"
@onready var hp_label := $Label3D as Label3D

@export var speed: float
@export var mana: int
@export var max_hp: int
var attack: int
var hp:
	get:
		return hp
	set(value):
		hp = value
		hp_label.text = hp_text_string % [hp, max_hp]
		
		if hp <= 0:
			_died()
		
# 행동력 
@export var point: int
var current_point: int

# 플레이어인지 확인용 
@export var is_player := false

func _ready():
	hp = max_hp

func _died():
	character_died.emit(self)
	
func set_character(data: Dictionary):
	#name = data.name
	#attack = data.attack
	if (data.has("max_hp")):
		max_hp = data.max_hp
	else:
		max_hp = data.hp
	speed = data.speed
	mana = data.mana
	hp = data.hp	
	print(data)
