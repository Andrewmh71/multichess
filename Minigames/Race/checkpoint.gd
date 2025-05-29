extends Area2D

@export var cp_number = 0

signal passed(num)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("car"):
		print("Player entered area!")
		emit_signal("passed", cp_number)
