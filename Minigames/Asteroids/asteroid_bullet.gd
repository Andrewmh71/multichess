extends Node2D

var velocity = Vector2.ZERO
var center = Vector2.ZERO
@export var max_dist = 150

func _process(delta):
	position += velocity * delta
	if global_position.distance_to(center) > max_dist:
		queue_free()
