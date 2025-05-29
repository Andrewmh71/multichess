extends Minigame

var asteroid = preload("res://Minigames/Asteroids/asteroid.tscn")

@export var spawn_delay = 2.5
@export var spawn_offset = 60
@export var asteroid_speed = 30.0
@export var ramping_mult = 0.025     # Change in delay between asteroids per second
@export var spawn_delay_min = 0.3

var center = Vector2.ZERO

var spawn_timer = 0

func _ready():
	$Player.connect("hit", Callable(self, "fail"))

func _process(delta):
	if difficulty_ramping:
		spawn_delay = clampf(spawn_delay - delta * ramping_mult, spawn_delay_min, 99999)
	
	spawn_timer += delta
	if spawn_timer > spawn_delay:
		spawn_timer = 0

		# Calculate the center of the minigame node
		var center = global_position + minigame_size * 0.5

		var new_asteroid = asteroid.instantiate()
		add_child(new_asteroid)
		new_asteroid.center = center

		# Choose a random direction from the center
		var spawn_angle = randf_range(0, 2 * PI)
		var offset_dir = Vector2.RIGHT.rotated(spawn_angle)

		# Spawn asteroid away from center
		new_asteroid.global_position = center + offset_dir * spawn_offset

		# Send asteroid toward center
		new_asteroid.velocity = (center - new_asteroid.global_position).normalized() * asteroid_speed
		new_asteroid.rotation = new_asteroid.velocity.angle()

func start_game(pn):
	super(pn)
	$Player.player_number = player_number
