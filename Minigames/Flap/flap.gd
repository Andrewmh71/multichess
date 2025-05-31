extends Node2D

var pipe_pair_scene = preload("res://Minigames/Flap/pipe.tscn")
@export var spawn_interval := 1.5  # Seconds between spawns
@export var spawn_x := 640

var spawn_timer := 0.0

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_pipe_pair()

func spawn_pipe_pair():
	var pipe_pair = pipe_pair_scene.instantiate()

	# Set initial position at the spawner's X
	pipe_pair.position = Vector2(spawn_x, 0)

	add_child(pipe_pair)
