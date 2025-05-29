extends Node2D

var velocity = Vector2.ZERO
var center = Vector2.ZERO
@export var max_dist = 150

func _ready():
	connect("area_entered", Callable(self, "on_area_entered"))

func on_area_entered(area):
	if area.is_in_group("player_bullet"):
		area.queue_free()
		queue_free()

func _process(delta):
	position += velocity * delta
	if global_position.distance_to(center) > max_dist:
		queue_free()
