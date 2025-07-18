extends Node2D

@onready var simon = preload("res://Minigames/Simon/simon.tscn")
@onready var pong = preload("res://Minigames/Pong/pong.tscn")
@onready var asteroids = preload("res://Minigames/Asteroids/asteroids.tscn")
@onready var race = preload("res://Minigames/Race/race.tscn")

const game1_pos = Vector2i(5, 30)
const game2_pos = Vector2i(455, 30)

var game1: Minigame
var game2: Minigame

var cur_turn = 1

var p1_index = 0
var p2_index = 0
var p1_game
var p2_game
var p1_difficulty_active
var p2_difficulty_active
var player1_games  = []
var player2_games = []

#func _ready():
	#var screen_size = get_viewport_rect().size
	#var screen_center_x = screen_size.x / 2
	#var screen_center_y = screen_size.y / 2
	#var chess_board_half_width = 128  # 32 * 8 / 2
#
	## Instantiate minigames
	#if game == "pong":
		#game1 = pong.instantiate()
		#game2 = pong.instantiate()
	#elif game == "simon":
		#game1 = simon.instantiate()
		#game2 = simon.instantiate()
	#
	#add_child(game1)
	#add_child(game2)
#
	#await get_tree().process_frame  # Ensure get_game_size() is valid
#
	#var game1_size = game1.get_game_size()
	#var game2_size = game2.get_game_size()
#
	## Left pocket center: halfway between left edge and left edge of board
	#var left_pocket_center_x = screen_center_x - chess_board_half_width
	#left_pocket_center_x /= 2
#
	## Right pocket center: halfway between board's right edge and right screen edge
	#var right_pocket_center_x = screen_center_x + chess_board_half_width
	#right_pocket_center_x = (right_pocket_center_x + screen_size.x) / 2
#
	## Both games centered in y
	#var game1_pos = Vector2(left_pocket_center_x, screen_center_y) - game1_size / 2
	#var game2_pos = Vector2(right_pocket_center_x, screen_center_y) - game2_size / 2
#
	#game1.position = game1_pos
	#game2.position = game2_pos
#
	## Connect to chess board
	#$Board.connect("player_switch", Callable(self, "player_switch"))
#
	#await get_tree().create_timer(5).timeout
#
	#if cur_turn == 1:
		#game1.resume_difficulty_ramping()
#
	#game1.start_game(1)
	#game2.start_game(2)

func _ready():
	player1_games = [race, race, race, race, race, race, race, race, race, race, race, race, race, race]
	player2_games = [simon, pong, race, asteroids, race, race, race, race, race, race, race, race, race, race, race]
	
	# Wait for first frame so get_game_size() works
	await get_tree().process_frame
	
	# Start first games
	start_next_game(1)
	start_next_game(2)
	
	# Connect chessboard switch
	$Board.connect("player_switch", Callable(self, "player_switch"))

	# Initial delay before difficulty ramps
	await get_tree().create_timer(5).timeout

	# Activate difficulty only for current turn
	if cur_turn == 1 and p1_game:
		p1_game.resume_difficulty_ramping()
	elif cur_turn == 2 and p2_game:
		p2_game.resume_difficulty_ramping()

func start_next_game(player):
	var game_list = player1_games if player == 1 else player2_games
	var index = p1_index if player == 1 else p2_index

	if index >= game_list.size():
		print("Player %d lost by minigame fail" % player)
		get_tree().quit()
		return

	var game_scene = game_list[index]
	var game_instance = game_scene.instantiate()

	add_child(game_instance)

	game_instance.connect("game_over", Callable(self, "on_game_over"))
	game_instance.start_game(player)
	if cur_turn == player:
		game_instance.resume_difficulty_ramping()

	# Positioning with chessboard offsets
	var screen_size = get_viewport_rect().size
	var screen_center_x = screen_size.x / 2
	var screen_center_y = screen_size.y / 2
	var chess_half = 128
	var left_x = (screen_center_x - chess_half) / 2
	var right_x = (screen_center_x + chess_half + screen_size.x) / 2

	var game_size = game_instance.get_game_size()
	var pos_x = left_x if player == 1 else right_x
	print("Setting pos to: ", Vector2(pos_x, screen_center_y) - game_size / 2)
	game_instance.position = Vector2(pos_x, screen_center_y) - game_size / 2

	# Store reference and update index
	if player == 1:
		p1_game = game_instance
		p1_index += 1
	else:
		p2_game = game_instance
		p2_index += 1

func on_game_over(player):
	if player == 1:
		p1_game.queue_free()
		p1_difficulty_active = false
	else:
		p2_game.queue_free()
		p2_difficulty_active = false

	start_next_game(player)

func player_switch():
	
	if cur_turn == 1:
		cur_turn = 2
		if p1_game:
			p1_game.pause_difficulty_ramping()
		if p2_game:
			p2_game.resume_difficulty_ramping()
	else:
		cur_turn = 1
		if p2_game:
			p2_game.pause_difficulty_ramping()
		if p1_game:
			p1_game.resume_difficulty_ramping()
