extends CharacterBody2D

@export var gravity := 1000.0  # Pixels per second squared
@export var flap_strength := 300.0  # Initial upward velocity on flap
@export var player_number := 1

func _physics_process(delta):
	# Apply gravity
	velocity.y += gravity * delta

	# Flap on button press
	if Input.is_action_just_pressed("game_main_p%d" % player_number):
		velocity.y = -flap_strength

	# Move the bird
	move_and_slide()
