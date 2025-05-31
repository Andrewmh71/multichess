extends Node2D

@export var speed := 120.0
@export var gap_size := 80.0
@export var max_gap_offset := 80.0
@export var bottom_y := 360

@onready var top_pipe := $TopPipe
@onready var bottom_pipe := $BottomPipe

func _ready():
	var gap_pos = randf_range(-max_gap_offset, max_gap_offset) + bottom_y / 2

	# Calculate positions
	var top_pos = gap_pos / 2
	var bottom_pos = gap_pos + gap_size + (bottom_y - (gap_pos + gap_size)) / 2

	# Position pipe bases at correct locations
	top_pipe.position = Vector2(0, top_pos)
	bottom_pipe.position = Vector2(0, bottom_pos)

	# Scale Y to fill from pipe end to screen edge
	top_pipe.scale.y = gap_pos
	bottom_pipe.scale.y = bottom_pos - (gap_pos + gap_size)

func _process(delta):
	position.x -= speed * delta
