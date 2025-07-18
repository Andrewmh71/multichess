extends Node2D

@export var gap_size: float = 100.0
@export var max_gap_offset: float = 100.0
@export var screen_height: float = 360.0
@export var pipe_width: float = 64.0  # Width of pipe, if needed for spacing logic

@onready var top_pipe := $TopPipe
@onready var bottom_pipe := $BottomPipe

func _ready():
	randomize()
	var center_y = screen_height / 2
	var gap_center = center_y + randf_range(-max_gap_offset, max_gap_offset)

	# Bottom pipe starts at the bottom of the screen and scales up to the gap
	var bottom_height = gap_center - gap_size / 2
	bottom_pipe.position = Vector2(0, screen_height)
	bottom_pipe.scale.y = bottom_height / bottom_pipe.get_node("Sprite").texture.get_height()
	bottom_pipe.scale.x = 1.0  # Ensure horizontal scale is not affected

	# Top pipe starts at the top and scales down to the gap
	var top_height = screen_height - (gap_center + gap_size / 2)
	top_pipe.position = Vector2(0, 0)
	top_pipe.scale.y = top_height / top_pipe.get_node("Sprite").texture.get_height()
	top_pipe.scale.x = 1.0

	# Flip top pipe vertically if needed (e.g. so both pipe openings face down)
	top_pipe.get_node("Sprite").rotation = 180
