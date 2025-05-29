extends Node2D
class_name Minigame

var player_number = 1

var difficulty_ramping = false

@export var minigame_size = Vector2(250, 300)

signal game_over(p_num)

func pause_difficulty_ramping():
	difficulty_ramping = false

func resume_difficulty_ramping():
	difficulty_ramping = true

func start_game(pn):
	player_number = pn

func get_game_size():
	return minigame_size
	
func fail():
	emit_signal("game_over", player_number)
