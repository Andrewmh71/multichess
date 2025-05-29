extends Minigame

@onready var ball = $Ball
@onready var paddle = $Paddle
@onready var wall_left = $WallLeft
@onready var wall_right = $WallRight
@onready var wall_top = $WallTop

# Configurable dimensions
@export var play_width := 180
@export var play_height := 230
var wall_thickness := 10
var ball_size := Vector2(12, 12)
var paddle_size := Vector2(60, 10)
var paddle_max_size := Vector2(60, 10)
var ball_velocity_start := Vector2(120, -120)
var ball_velocity := Vector2.ZERO

# Paddle scaling parameters
var paddle_min_width := 20.0
var paddle_shrink_rate := 0.3  # pixels per second
var speed_increase := 2 # Speed increase per second

var started = false

func _ready():
	minigame_size = Vector2(play_width, play_height)
	
	# Set sprite scales
	_update_sprite_scale(ball, ball_size)
	_update_sprite_scale(paddle, paddle_size)
	_update_sprite_scale(wall_left, Vector2(wall_thickness, play_height))
	_update_sprite_scale(wall_right, Vector2(wall_thickness, play_height))
	_update_sprite_scale(wall_top, Vector2(play_width, wall_thickness))

	# Centered positions (since Sprite2D.position is the center)
	ball.position = Vector2(play_width / 2, play_height / 2)
	paddle.position = Vector2(play_width / 2, play_height - paddle_size.y / 2)
	wall_left.position = Vector2(wall_thickness / 2, play_height / 2)
	wall_right.position = Vector2(play_width - wall_thickness / 2, play_height / 2)
	wall_top.position = Vector2(play_width / 2, wall_thickness / 2)

	set_process(true)

func start_game(pn):
	super(pn)
	started = true
	ball_velocity = ball_velocity_start

func _process(delta):
	# Shrink paddle if difficulty is ramping
	if difficulty_ramping and paddle_size.x > paddle_min_width:
		paddle_size.x = max(paddle_min_width, paddle_size.x - paddle_shrink_rate * delta)
		var increase = delta * speed_increase
		if ball_velocity.y < 0: increase *= -1
		if started: ball_velocity.y += increase
		_update_sprite_scale(paddle, paddle_size)

	# Move ball
	ball.position += ball_velocity * delta

	# Get ball bounds (centered)
	var ball_left = ball.position.x - ball_size.x / 2
	var ball_right = ball.position.x + ball_size.x / 2
	var ball_top = ball.position.y - ball_size.y / 2
	var ball_bottom = ball.position.y + ball_size.y / 2

	# Wall collisions
	if ball_left <= wall_thickness:
		ball.position.x = wall_thickness + ball_size.x / 2
		ball_velocity.x *= -1
	elif ball_right >= play_width - wall_thickness:
		ball.position.x = play_width - wall_thickness - ball_size.x / 2
		ball_velocity.x *= -1

	if ball_top <= wall_thickness:
		ball.position.y = wall_thickness + ball_size.y / 2
		ball_velocity.y *= -1

	# Paddle bounds (centered)
	var paddle_left = paddle.position.x - paddle_size.x / 2
	var paddle_right = paddle.position.x + paddle_size.x / 2
	var paddle_top = paddle.position.y - paddle_size.y / 2
	var paddle_bottom = paddle.position.y + paddle_size.y / 2

	# Ball-paddle collision
	if ball_bottom >= paddle_top and \
	   ball_top <= paddle_bottom - ball_size.y / 2 and \
	   ball_right >= paddle_left and \
	   ball_left <= paddle_right and \
	   ball_velocity.y > 0:

		#ball.position.y = paddle_top - ball_size.y / 2

		# 1. Offset from paddle center, normalized to [-1, 1]
		var offset = (ball.position.x - paddle.position.x) / (paddle_size.x / 2)

		# 2. Add a bit of randomness (optional)
		offset += randf_range(-0.1, 0.1)
		offset = clamp(offset, -1.0, 1.0)

		# 3. Construct new velocity direction
		var new_dir = Vector2(offset, -1).normalized()

		# 4. Maintain constant speed
		var speed = ball_velocity.length()
		ball_velocity = new_dir * speed

	# Ball out of bounds
	if ball_top > play_height:
		ball.position = Vector2(play_width / 2, play_height / 2)
		ball_velocity = Vector2(150, -150)
		paddle_size = paddle_max_size
		fail()

	# Paddle movement
	var move := 0.0
	if started:
		if Input.is_action_pressed("game_left_p1") and player_number == 1:
			move -= 1
		if Input.is_action_pressed("game_right_p1") and player_number == 1:
			move += 1
		
		if Input.is_action_pressed("game_left_p2") and player_number == 2:
			move -= 1
		if Input.is_action_pressed("game_right_p2") and player_number == 2:
			move += 1

	var paddle_speed := 300
	paddle.position.x += move * paddle_speed * delta

	# Clamp paddle inside play area
	var half_width := paddle_size.x / 2
	var min_x := wall_thickness + half_width
	var max_x := play_width - wall_thickness - half_width
	paddle.position.x = clamp(paddle.position.x, min_x, max_x)

# --- Utility Functions ---

func _update_sprite_scale(sprite: Sprite2D, target_size: Vector2) -> void:
	if sprite.texture:
		sprite.scale = target_size / sprite.texture.get_size()
