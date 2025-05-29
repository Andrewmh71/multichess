extends Minigame

# Game state
var sequence = []
var current_index = 0
var input_options = ["up", "down", "left", "right"]
var sequence_length = 3
var base_sequence_length = 3
var num_lives = 3

var player_active = false
var sprite_locked = false

# Flash durations
var flash_timer = 0.0
var flashing_input = false
var sequence_flash_duration = 0.6
var sequence_blank_duration = 0.25
var input_flash_duration = 0.15

# Input timer
var input_time_limit = 5.0
var input_time_remaining = 0.0
var input_timer_active = false

# Between-rounds timer
var round_timer = 0.0
var between_rounds_time = 8.0

# Audio stuff
var played_start = false

# Time-based difficulty
var elapsed_time = 0.0
var time_per_level = 30.0  # seconds between difficulty increases
var per_life_decrease = 5.0

@onready var flash_sprite = Sprite2D.new()
@onready var sprite_paths = {
	"up": preload("res://Minigames/Simon/playstation_dpad_up.png"),
	"down": preload("res://Minigames/Simon/playstation_dpad_down.png"),
	"left": preload("res://Minigames/Simon/playstation_dpad_left.png"),
	"right": preload("res://Minigames/Simon/playstation_dpad_right.png")
}
@onready var blank_dpad = preload("res://Minigames/Simon/playstation_dpad.png")

# UI Elements
@onready var difficulty_progress = $DifficultyProgressBar
@onready var sequence_label = $SequenceLabel
@onready var input_timer_bar = $InputTimerBar
@onready var lives_container = $LivesContainer
@onready var round_timer_bar = $RoundTimer
@onready var round_label = $BetweenRoundsLabel
@onready var input_label = $InputTimerLabel

@onready var p1_start = preload("res://Audio/SFX/Player1_minigame_start.ogg")
@onready var p2_start = preload("res://Audio/SFX/Player2_minigame_start.ogg")

# Sound
@onready var audio_player = $AudioStreamPlayer
@onready var audio_paths = {
	"up": preload("res://Audio/SFX/Tone_C.ogg"),
	"down": preload("res://Audio/SFX/Tone_E.ogg"),
	"left": preload("res://Audio/SFX/Tone_G.ogg"),
	"right": preload("res://Audio/SFX/Tone_High_C.ogg")
}

var input_pos = Vector2i(77, 110)

func _ready():
	add_child(flash_sprite)
	flash_sprite.texture = blank_dpad
	flash_sprite.scale = Vector2i(2, 2)
	flash_sprite.position = input_pos

	input_timer_bar.visible = false
	difficulty_progress.max_value = 100
	round_timer_bar.visible = true
	input_label.visible = false
	
func start_game(pn = 1):
	super(pn)
	flash_sprite.visible = true
	update_sequence_label()
	await await_next_round()

func generate_new_sequence():
	sequence.clear()
	for i in range(sequence_length):
		var new_input = input_options[randi() % input_options.size()]
		sequence.append(new_input)

func play_sequence():
	player_active = false
	input_timer_active = false
	input_timer_bar.visible = false

	for input in sequence:
		# Show visual, play sound
		#audio_player.stream = audio_paths[input]
		#audio_player.play()
		flash_sprite.texture = sprite_paths[input]
		await get_tree().create_timer(sequence_flash_duration).timeout
		flash_sprite.texture = blank_dpad
		await get_tree().create_timer(sequence_blank_duration).timeout

	flash_sprite.texture = blank_dpad
	player_active = true

func start_input_timer():
	input_time_remaining = input_time_limit
	input_timer_bar.max_value = input_time_limit
	input_timer_bar.value = input_time_remaining
	input_timer_bar.visible = true
	input_timer_active = true

func _process(delta):
	if round_timer > 0.0:
		round_timer -= delta
		round_timer_bar.value = round_timer
		
		if round_timer <= 1 and !played_start:
			#audio_player.stream = p1_start if player_number == 1 else p2_start
			#audio_player.play()
			var device_id = 0 if player_number == 1 else 1
			Input.start_joy_vibration(device_id, 1.0, 1.0, 1)
			played_start = true
		
		if round_timer <= 0.0:
			start_round()
		
	# Countdown input timer
	if input_timer_active:
		input_time_remaining -= delta
		input_timer_bar.value = input_time_remaining
		if input_time_remaining <= 0:
			print("Time's up!")
			await fail()

	# Flash input display
	if flashing_input:
		flash_timer -= delta
		if flash_timer <= 0.0:
			flash_sprite.texture = blank_dpad
			flashing_input = false
	
	if difficulty_ramping:
		# Increase difficulty over time
		elapsed_time += delta
		var expected_level = base_sequence_length + int(elapsed_time / time_per_level)
		if expected_level > sequence_length:
			sequence_length = expected_level
			update_sequence_label()

	update_difficulty_progress()

func update_sequence_label():
	sequence_label.text = "Sequence Length: %d" % sequence_length

func update_difficulty_progress():
	var fractional = fmod(elapsed_time, time_per_level) / time_per_level
	difficulty_progress.value = fractional * 100

func _input(event):
	if not player_active:
		return

	var input = ""

	if player_number == 1:
		if event.is_action_pressed("game_up_p1"):
			input = "up"
		elif event.is_action_pressed("game_down_p1"):
			input = "down"
		elif event.is_action_pressed("game_left_p1"):
			input = "left"
		elif event.is_action_pressed("game_right_p1"):
			input = "right"
	elif player_number == 2:
		if event.is_action_pressed("game_up_p2"):
			input = "up"
		elif event.is_action_pressed("game_down_p2"):
			input = "down"
		elif event.is_action_pressed("game_left_p2"):
			input = "left"
		elif event.is_action_pressed("game_right_p2"):
			input = "right"

	if input != "":
		handle_input(input)

func handle_input(input):
	if sprite_locked:
		return
	
	print("Player input:", input, " from player ", player_number)
	print("sequence input: " + str(sequence[current_index]))

	if input == sequence[current_index]:
		current_index += 1

		flash_sprite.texture = sprite_paths[input]
		flash_timer = input_flash_duration
		flashing_input = true

		if current_index >= sequence.size():
			print("Sequence correct!")
			input_timer_active = false
			player_active = false
			await await_next_round()
	else:
		print("Wrong input.")
		await fail()

func await_next_round():
	round_label.visible = true
	input_label.visible = false
	
	var bonus_time = max(0, input_time_remaining)
	
	round_timer = between_rounds_time + bonus_time
	round_timer_bar.max_value = round_timer
	round_timer_bar.value = round_timer
	round_timer_bar.visible = true
	input_timer_bar.visible = false

	# Schedule the round to start after the timer
	await get_tree().create_timer(round_timer).timeout
	await start_round()

func start_round():
	played_start = false
	round_label.visible = false
	round_timer_bar.visible = false
	input_label.visible = true
	
	generate_new_sequence()
	await play_sequence()
	start_input_timer()
	current_index = 0
	player_active = true
