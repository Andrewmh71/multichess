extends Node2D

var bullet = preload("res://Minigames/Asteroids/bullet.tscn")

var player_number = 1

signal hit()

@export var rotation_speed = 7.0
@export var offset = 12.0
@export var bullet_speed = 100.0
@export var shoot_cooldown = 0.4

var cur_cooldown = 0

func _ready():
	connect("area_entered", Callable(self, "on_area_entered"))
	
func _process(delta):
	cur_cooldown -= delta
	if Input.is_action_pressed("game_main_p%d" % player_number) and cur_cooldown <= 0:
		shoot()
	
	# Get player's input direction and rotate
	var input = Input.get_vector(
		"game_left_p%d" % player_number,
		"game_right_p%d" % player_number,
		"game_up_p%d" % player_number,
		"game_down_p%d" % player_number
	)
	
	if input != Vector2.ZERO:
		var to_angle = input.angle()
		var delta_angle = wrapf(to_angle - rotation, -PI, PI)
		var step = rotation_speed * delta  # max radians to rotate this frame
		rotation += clamp(delta_angle, -step, step)

func on_area_entered(area):
	if area.is_in_group("asteroid"):
		area.queue_free()
		emit_signal("hit")

func shoot():
	cur_cooldown = shoot_cooldown
	
	var new_bullet = bullet.instantiate()
	
	get_parent().add_child(new_bullet)
	
	new_bullet.center = global_position
	
	var bullet_dir = Vector2.RIGHT.rotated(rotation)
	
	new_bullet.rotation = rotation
	new_bullet.velocity = bullet_dir * bullet_speed
	new_bullet.global_position = global_position + bullet_dir * offset
