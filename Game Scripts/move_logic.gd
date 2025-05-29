extends Resource

var MOVES = {}
var DIRECTIONS = []
var RAYS = []
var PIECES = {}

func _init():
	# Define directions
	DIRECTIONS = [
		Vector2(1, 0), Vector2(1, 1), Vector2(0, 1), Vector2(-1, 1),
		Vector2(-1, 0), Vector2(-1, -1), Vector2(0, -1), Vector2(1, -1),
		Vector2(2, 1), Vector2(1, 2), Vector2(-1, 2), Vector2(-2, 1),
		Vector2(-2, -1), Vector2(-1, -2), Vector2(1, -2), Vector2(2, -1)
	]
	
	RAYS = []
	for d in DIRECTIONS:
		RAYS.append(atan2(d.y, d.x))

	# Define piece move legality checks
	PIECES = {
		'k': func(y, dx, dy): return abs(dx) <= 1 and abs(dy) <= 1,
		'q': func(y, dx, dy): return dx == 0 or dy == 0 or abs(dx) == abs(dy),
		'n': func(y, dx, dy): return abs(dx) >= 1 and abs(dy) >= 1 and abs(dx) + abs(dy) == 3,
		'b': func(y, dx, dy): return abs(dx) == abs(dy),
		'r': func(y, dx, dy): return dx == 0 or dy == 0,
		'p': func(y, dx, dy): return (y < 8 and abs(dx) <= 1 and dy == -1),
		'P': func(y, dx, dy): return (y > 1 and abs(dx) <= 1 and dy == 1),
	}

	_generate_moves()

func _generate_moves():
	for sym in PIECES.keys():
		MOVES[sym] = []

		for idx in range(64):
			var move_dirs = []
			for _i in range(8):
				move_dirs.append([])

			var y = 8 - idx / 8
			for end in range(64):
				if idx == end:
					continue

				var dx = (end % 8) - (idx % 8)
				var dy = (8 - end / 8) - y

				if not PIECES[sym].call(y, dx, dy):
					continue

				var angle = atan2(dy, dx)
				var ray_idx = RAYS.find(angle)
				if ray_idx != -1:
					ray_idx = ray_idx % 8
					move_dirs[ray_idx].append(end)

			# Remove empty direction lists
			var filtered_dirs = []
			for ray in move_dirs:
				if ray.size() > 0:
					ray.sort_custom(Callable(self, "_sort_by_distance").bind(idx))
					filtered_dirs.append(ray)

			MOVES[sym].append(filtered_dirs)

	# Copy for white pieces (except pawns)
	for sym in ['K', 'Q', 'N', 'B', 'R']:
		MOVES[sym] = []
		for m in MOVES[sym.to_lower()]:
			var clone = []
			for ray in m:
				clone.append(ray.duplicate())
			MOVES[sym].append(clone)

	# Add castling
	MOVES['k'][4][0].append(6)
	MOVES['k'][4][1].append(2)
	MOVES['K'][60][0].append(62)
	MOVES['K'][60][4].append(58)

	# Add double pawn move
	var idx = 0
	for i in range(8):
		MOVES['p'][8 + i][idx].append(24 + i)
		MOVES['P'][55 - i][idx].append(39 - i)
		idx = 1

func _sort_by_distance(a: int, b: int, idx: int) -> bool:
	return abs(a - idx) < abs(b - idx)
