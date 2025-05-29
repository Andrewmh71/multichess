extends Node2D

const GRID_SIZE = 8
const CELL_SIZE = 32
const COLOR_LIGHT = Color(0.8, 0.8, 0.8)
const COLOR_DARK = Color(0.2, 0.2, 0.2)

const PLAYER_1 = 1
const PLAYER_2 = 2

const SELECTOR_SIZE = 64

const PIECE_TEXTURES = {
	"P": preload("res://Chess Sprites/white_p.png"),
	"N": preload("res://Chess Sprites/white_n.png"),
	"B": preload("res://Chess Sprites/white_b.png"),
	"R": preload("res://Chess Sprites/white_r.png"),
	"Q": preload("res://Chess Sprites/white_q.png"),
	"K": preload("res://Chess Sprites/white_k.png"),
	"p": preload("res://Chess Sprites/black_p.png"),
	"n": preload("res://Chess Sprites/black_n.png"),
	"b": preload("res://Chess Sprites/black_b.png"),
	"r": preload("res://Chess Sprites/black_r.png"),
	"q": preload("res://Chess Sprites/black_q.png"),
	"k": preload("res://Chess Sprites/black_k.png"),
}

const cap_sound = preload("res://Audio/SFX/capture.mp3")
const move_sound = preload("res://Audio/SFX/move-self.mp3")

var turn_label : Label
var white_sprite : Sprite2D
var black_sprite : Sprite2D

const white_spr_on = preload("res://white_on.png")
const white_spr_off = preload("res://white_off.png")
const black_spr_on = preload("res://black_on.png")
const black_spr_off = preload("res://black_off.png")

const p1_selector_tex = preload("res://UI Sprites/selector_red1.png")
const p2_selector_tex = preload("res://UI Sprites/selector_blue1.png")

var p1_selector = Sprite2D.new()
var p2_selector = Sprite2D.new()

var p1_color = "w"
var p2_color = "b"

var p1_sel_pos = [7, 4]
var p2_sel_pos = [0, 4]

var p1_options = []
var p2_options = []

var p1_selected = null
var p2_selected = null

var move_cooldown_p1 = 0.0
var move_cooldown_p2 = 0.0

var initial_pressed = [false, false]
var select_released_p1 = true
var select_released_p2 = true

const STICK_DEADZONE = 0.4
const REPEAT_DELAY = 0.1
const INITIAL_REPEAT_DELAY = 0.2

var game = null

var current_player = PLAYER_1

var grid_squares = []
var piece_grid = []

signal player_switch

# --- Helper functions ---

func mtoi(row, col):
	return GRID_SIZE * row + col

func itom(i):
	return [i / 8, i % 8]

func square_to_row_col(square: String) -> Vector2i:
	var col = square.unicode_at(0) - 'a'.unicode_at(0)
	var row = 8 - int(square.substr(1, 1))
	return Vector2i(row, col)

func _reset_colors():
	for row in range(GRID_SIZE):
		for col in range(GRID_SIZE):
			var square = grid_squares[row][col]
			square.color = COLOR_LIGHT if ((row + col) % 2 == 0) else COLOR_DARK

# --- Input handling ---

func _input(event):
	if event.is_action_pressed("select_p1") and select_released_p1:
		if current_player == PLAYER_1:
			handle_selection(PLAYER_1)
		select_released_p1 = false
	elif event.is_action_released("select_p1"):
		select_released_p1 = true

	if event.is_action_pressed("select_p2") and select_released_p2:
		if current_player == PLAYER_2:
			handle_selection(PLAYER_2)
		select_released_p2 = false
	elif event.is_action_released("select_p2"):
		select_released_p2 = true
		
	if event.is_action_pressed("cancel_p1"):
		p1_selected = []
		p1_options = []
		_reset_colors()
	if event.is_action_pressed("cancel_p2"):
		p2_selected = []
		p2_options = []
		_reset_colors()

func handle_selection(player: int):
	var selector_pos = p1_sel_pos if player == PLAYER_1 else p2_sel_pos
	var selected_square = mtoi(selector_pos[0], selector_pos[1])
	var options = p1_options if player == PLAYER_1 else p2_options
	var selected = p1_selected if player == PLAYER_1 else p2_selected
	var p_color = p1_color if player == PLAYER_1 else p2_color
	var sel_color = Color.FIREBRICK if player == PLAYER_1 else Color.DODGER_BLUE
	
	# Do the move
	if selected_square in options:
		# Play appropriate sound
		var owner = game.board.get_piece_owner(selected_square)
		var sound = cap_sound if (owner == "b" and player == 1) or (owner == "w" and player == 2) else move_sound
		$AudioStreamPlayer2D.stream = sound
		$AudioStreamPlayer2D.play()
		
		game.apply_move(selected, selected_square, "")
		draw_board()
		switch_player()
		
		# If checkmate
		if game.get_moves().size() == 0:
			print("Player %d wins by checkmate" % player)
			get_tree().quit()

	selected = selected_square
	options.clear()
	_reset_colors()

	var moves = game.get_moves("", [selected])
	
	grid_squares[selector_pos[0]][selector_pos[1]].color = sel_color

	for m in moves:
		var end = m[1]
		if game.board.get_piece_owner(selected) == p_color:
			options.append(end)
			var col = end % 8
			var row = end / 8
			grid_squares[row][col].color = Color.YELLOW
	
	if player == PLAYER_1:
		p1_selected = selected
		p1_options = options
	else:
		p2_selected = selected
		p2_options = options

func switch_player():
	emit_signal("player_switch")
	current_player = PLAYER_2 if current_player == PLAYER_1 else PLAYER_1
	turn_label.text = "White to Move" if current_player == 1 else "Black to Move"
	var color = Color.WHITE if current_player == 1 else Color.BLACK
	turn_label.label_settings.font_color = color
	white_sprite.texture = white_spr_on if current_player == 1 else white_spr_off
	black_sprite.texture = black_spr_off if current_player == 1 else black_spr_on
	
# --- Movement and selector handling ---

func _process(delta):
	move_cooldown_p1 -= delta
	move_cooldown_p2 -= delta

	handle_player_input(1, move_cooldown_p1, p1_sel_pos, p1_selector)
	handle_player_input(2, move_cooldown_p2, p2_sel_pos, p2_selector)

func handle_player_input(player_number: int, move_cooldown: float, selector_pos: Array, selector_sprite: Sprite2D) -> void:
	var input_dir = Vector2(
		Input.get_action_strength("selector_right_p%d" % player_number) - Input.get_action_strength("selector_left_p%d" % player_number),
		Input.get_action_strength("selector_down_p%d" % player_number) - Input.get_action_strength("selector_up_p%d" % player_number)
	)

	if input_dir.length() < STICK_DEADZONE:
		input_dir = Vector2.ZERO

	if input_dir != Vector2.ZERO:
		if move_cooldown <= 0:
			handle_movement(input_dir, selector_pos, selector_sprite)
			if initial_pressed[player_number - 1]:
				move_cooldown = REPEAT_DELAY
			else:
				move_cooldown = INITIAL_REPEAT_DELAY
				initial_pressed[player_number - 1] = true
	else:
		initial_pressed[player_number - 1] = false
		move_cooldown = 0.0

	if player_number == 1:
		move_cooldown_p1 = move_cooldown
	else:
		move_cooldown_p2 = move_cooldown

func handle_movement(dir: Vector2, selector_pos: Array, selector_sprite: Sprite2D):
	if dir.x > 0 and selector_pos[1] < 7:
		selector_pos[1] += 1
		move_selector(selector_pos, selector_sprite)
	elif dir.x < 0 and selector_pos[1] > 0:
		selector_pos[1] -= 1
		move_selector(selector_pos, selector_sprite)

	if dir.y > 0 and selector_pos[0] < 7:
		selector_pos[0] += 1
		move_selector(selector_pos, selector_sprite)
	elif dir.y < 0 and selector_pos[0] > 0:
		selector_pos[0] -= 1
		move_selector(selector_pos, selector_sprite)

func move_selector(selector_pos: Array, selector_sprite: Sprite2D):
	selector_sprite.position = Vector2(selector_pos[1] * CELL_SIZE + CELL_SIZE / 2, selector_pos[0] * CELL_SIZE + CELL_SIZE / 2)

# --- Board drawing ---

func draw_board():
	var fen = game.get_fen()
	var fields = fen.split(" ")
	var board_fen = fields[0]

	for row in piece_grid:
		for piece in row:
			if piece != null:
				piece.queue_free()
	piece_grid.clear()

	var row = 0
	var col = 0
	var spr_row = []
	for char in board_fen:
		if char == "/":
			piece_grid.append(spr_row)
			spr_row = []
			row += 1
			col = 0
		elif char.is_valid_int():
			for i in range(int(char)):
				spr_row.append(null)
				col += 1
		else:
			var sprite = Sprite2D.new()
			sprite.texture = PIECE_TEXTURES.get(char, null)

			if sprite.texture != null:
				var tex_size = sprite.texture.get_size()
				sprite.scale = Vector2(CELL_SIZE / tex_size.x, CELL_SIZE / tex_size.y)
				sprite.position = Vector2(col * CELL_SIZE + CELL_SIZE / 2, row * CELL_SIZE + CELL_SIZE / 2)
				add_child(sprite)
				spr_row.append(sprite)

			col += 1

	piece_grid.append(spr_row)

func _ready():
	turn_label = get_parent().get_node("TurnLabel")
	white_sprite = get_parent().get_node("WhiteTurnSprite")
	black_sprite = get_parent().get_node("BlackTurnSprite")
	
	grid_squares.resize(GRID_SIZE)
	for row in range(GRID_SIZE):
		grid_squares[row] = []
		for col in range(GRID_SIZE):
			var square = ColorRect.new()
			square.color = COLOR_LIGHT if ((row + col) % 2 == 0) else COLOR_DARK
			square.position = Vector2(col * CELL_SIZE, row * CELL_SIZE)
			square.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			add_child(square)
			grid_squares[row].append(square)

	add_child(p1_selector)
	p1_selector.texture = p1_selector_tex
	move_selector([7, 4], p1_selector)

	add_child(p2_selector)
	p2_selector.texture = p2_selector_tex
	move_selector([0, 4], p2_selector)
	
	var board_size = Vector2(GRID_SIZE * CELL_SIZE, GRID_SIZE * CELL_SIZE)
	self.position = get_viewport_rect().size / 2 - board_size / 2

	game = Game.new()
	draw_board()
