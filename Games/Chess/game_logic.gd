extends Resource
class_name Game

var moves = preload("res://Game Scripts/move_logic.gd").new()

const NORMAL = 0
const CHECK = 1
const CHECKMATE = 2
const STALEMATE = 3

const EMPTY_64_ARRAY = [[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], [],
						[], [], [], [], [], [], [], []]

const default_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

var test_game: Game = null

class State:
	var player: String
	var rights: String
	var en_passant: String
	var ply: int
	var turn: int

	func _init(_player := "w", _rights := "KQkq", _en_passant := "-", _ply := 0, _turn := 1):
		player = _player
		rights = _rights
		en_passant = _en_passant
		ply = _ply
		turn = _turn

var board: Board
var state: State
var move_history: Array = []
var fen_history: Array = []
var validate: bool = true

func _init(fen: String = default_fen, validate_moves: bool = true, test_mode: bool = false):
	board = Board.new()
	state = State.new()
	validate = validate_moves
	if not test_mode:
		test_game = Game.new(fen, false, true)
	set_fen(fen)

func to_fen() -> String:
	return " ".join([board.to_fen(), state.player, state.rights, state.en_passant, str(state.ply), str(state.turn)])

static func i2xy(pos_idx: int) -> String:
	return char(97 + pos_idx % 8) + str(8 - pos_idx / 8)

static func xy2i(pos_xy: String) -> int:
	return (8 - int(pos_xy[1])) * 8 + (pos_xy[0].unicode_at(0) - "a".unicode_at(0))

func get_fen() -> String:
	return to_fen()

func set_fen(fen: String) -> void:
	fen_history.append(fen)
	var fields = fen.split(" ")
	board.set_piece_pos(fields[0])
	state = State.new(fields[1], fields[2], fields[3], int(fields[4]), int(fields[5]))

func reset(fen: String = default_fen) -> void:
	move_history.clear()
	fen_history.clear()
	set_fen(fen)

func apply_move(start: int, end: int, promotion: String = "") -> void:
	if start == null or end == null:
		push_error("Null Move: fen: %s" % [str(self)])
		return

	var piece = board.get_piece(start)
	var target = board.get_piece(end)

	if validate:
		var valid = false
		for m in get_moves("", [start]):
			if m[0] == start and m[1] == end:
				valid = true
				break
		if not valid:
			push_error("Invalid Move: %s -> %s\nfen: %s" % [start, end, get_fen()])
			return

	# Update state
	var player = "b" if state.player == "w" else "w"
	var rights = state.rights
	var en_passant = "-"
	var ply = state.ply + 1
	var turn = state.turn
	if state.player == "b":
		turn += 1

	# Remove castling rights if king/rook moves
	var rights_map = {0: "q", 4: "kq", 7: "k", 56: "Q", 60: "KQ", 63: "K"}
	var void_set = (rights_map.get(start, "") + rights_map.get(end, ""))
	for r in void_set:
		rights = rights.replace(r, "")

	if rights == "":
		rights = "-"

	# En passant setting
	if piece.to_lower() == "p" and abs(start - end) == 16:
		en_passant = i2xy((start + end) / 2)

	# Reset ply clock if pawn move or capture
	if piece.to_lower() == "p" or target.strip_edges() != "":
		ply = 0

	# Promotion
	if promotion == "" and piece.to_lower() == "p" and (end < 8 || end > 55):
		piece = "q"
		if state.player == "w":
			piece = piece.to_upper()
	elif promotion != "":
		piece = promotion
		if state.player == "w":
			piece = piece.to_upper()

	move_history.append({"start": start, "end": end, "promotion": promotion})
	board.move_piece(start, end, piece)

	# Castling rook move
	var castle_rook_moves = {62: [63, 61], 58: [56, 59], 6: [7, 5], 2: [0, 3]}
	if piece.to_lower() == "k" and end in castle_rook_moves:
		var rook_move = castle_rook_moves[end]
		var rook_from = rook_move[0]
		var rook_to = rook_move[1]

		var rook_piece = board.get_piece(rook_from)
		board.move_piece(rook_from, rook_to, rook_piece)

	# En passant capture
	if piece.to_lower() == "p" and state.en_passant != "-" and xy2i(state.en_passant) == end:
		if end < 24:
			board.move_piece(end + 8, end + 8, " ")
		elif end > 32:
			board.move_piece(end - 8, end - 8, " ")

	state = State.new(player, rights, en_passant, ply, turn)

func get_moves(player: String = "", idx_list: Array = []) -> Array:
	if idx_list.size() == 0:
		idx_list = range(64)

	if not validate:
		return _all_moves(player, idx_list)

	player = player if player != "" else state.player
	var res_moves = []
	var k_sym = {"w": "K", "b": "k"}[player]
	var opp = {"w": "b", "b": "w"}[player]
	var kdx = board.find_piece(k_sym)

	for move in _all_moves(player, idx_list):
		if test_game == null:
			test_game = Game.new()
		test_game.set_fen(get_fen())
		test_game.apply_move(move[0], move[1], move[2])

		# Castling-specific safety
		if move[0] == kdx and abs(move[0] - move[1]) == 2:
			var op_moves = []
			for m in test_game._all_moves(opp, []):
				op_moves.append(m[1])
			var castle_gap = {
				"e1g1": "f1", "e1c1": "d1",
				"e8g8": "f8", "e8c8": "d8"
			}.get(i2xy(move[0]) + i2xy(move[1]), "")
			if kdx in op_moves or (castle_gap != "" and xy2i(castle_gap) in op_moves):
				continue

		var targets = []
		for m in test_game._all_moves(opp, []):
			targets.append(m[1])

		if test_game.board.find_piece(k_sym) not in targets:
			res_moves.append(move)

	return res_moves

func _all_moves(player: String = "", idx_list: Array = []) -> Array:
	if idx_list.size() == 0:
		idx_list = range(64)

	player = player if player != "" else state.player
	var res_moves = []

	for start in idx_list:
		if board.get_piece_owner(start) != player:
			continue

		var piece = board.get_piece(start)
		var rays = moves.MOVES.get(piece, EMPTY_64_ARRAY)

		for ray in rays[start]:
			res_moves += _trace_ray(start, piece, ray, player)

	return res_moves

func _trace_ray(start: int, piece: String, ray: Array, player: String) -> Array:
	var res_moves = []

	for end in ray:
		var sym = piece.to_lower()
		var del_x = abs(end - start) % 8
		var tgt_owner = board.get_piece_owner(end)

		if tgt_owner == player:
			break

		# Castling special
		if sym == "k" and del_x == 2:
			var gap_owner = board.get_piece_owner((start + end) / 2)
			var out_owner = board.get_piece_owner(end - 1)
			var rights = {62: "K", 58: "Q", 6: "k", 2: "q"}.get(end, " ")
			if tgt_owner != "" or gap_owner != "" or rights not in state.rights or (rights.to_lower() == "q" and out_owner != ""):
				break

		# Pawn logic
		if sym == "p":
			if del_x == 0 and tgt_owner != "":
				break
			elif del_x != 0 and tgt_owner == "":
				if state.en_passant == "-" or end != xy2i(state.en_passant):
					break

		if sym == "p" and (end < 8 or end > 55):
			for promo in ["b", "n", "r", "q"]:
				res_moves.append([start, end, promo])
		else:
			res_moves.append([start, end, ""])

		if tgt_owner != "":
			break

	return res_moves

func get_status() -> int:
	var k_sym = {"w": "K", "b": "k"}[state.player]
	var opp = {"w": "b", "b": "w"}[state.player]

	var k_loc = i2xy(board.find_piece(k_sym))
	var can_move = get_moves().size()
	var is_exposed = []
	for m in _all_moves(opp, []):
		if i2xy(m[1]) == k_loc:
			is_exposed.append(m)

	if is_exposed.size() > 0:
		if can_move == 0:
			return CHECKMATE
		return CHECK
	elif can_move == 0:
		return STALEMATE
	return NORMAL
