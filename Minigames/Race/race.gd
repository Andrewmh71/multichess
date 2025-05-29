extends Minigame

@export var start_time = 20
@export var max_time = 40

@export var max_time_add = 10.0
@export var min_time_add = 5.0
@export var to_min_time = 120.0
var cur_time_add = 0.0

var timer_label : Label
var time_left := 0.0

var cur_checkpoint = 1
var checkpoints = []

func start_game(pn):
	super(pn)
	$Car.player_number = pn

func _ready():
	cur_time_add = max_time_add
	
	timer_label = $TimerLabel
	time_left = start_time
	for i in range(4):
		checkpoints.append(get_node("Check%d" % i))
		checkpoints[i].connect("passed", Callable(self, "checkpoint"))

func _process(delta):
	if difficulty_ramping:
		print("Subtracting:", ((max_time_add - min_time_add) / to_min_time) * delta)
		cur_time_add -= ((max_time_add - min_time_add) / to_min_time) * delta
		print("CUR TIME ADD:", cur_time_add)
	
	time_left -= delta
	if time_left <= 0:
		fail()
	timer_label.text = String.num(time_left, 2)

func add_time():
	time_left += cur_time_add
	if time_left > max_time:
		time_left = max_time
	
func checkpoint(number):
	if number == cur_checkpoint:
		if number == 0:
			add_time()
		cur_checkpoint = (cur_checkpoint + 1) % checkpoints.size()
