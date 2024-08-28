extends Node3D
class_name BattleCharacter

signal character_died(char : BattleCharacter)

var hp_text_string := "HP : %d / %d"
@onready var hp_label := $Label3D as Label3D

@export var speed: float
@export var mana: int
@export var max_hp: int
@onready var hp = max_hp :
	get:
		return hp
	set(value):
		hp = value
		hp_label.text = hp_text_string % [hp, max_hp]
		
		if hp <= 0:
			_died()
		
@export var point: int
var current_point: int

# for test
@export var is_player := false

func _ready():
	hp = max_hp

func _died():
	character_died.emit(self)
