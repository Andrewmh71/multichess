extends Resource  # Or just 'extends Resource' if you want it pure-data

class_name Board

"""
This class manages the position of all pieces in a chess game.
The position is stored as an Array of single-character Strings.
"""

var _position: Array = []

func _init(position: String = "                                                                "):  # 64 spaces
	set_piece_pos(position)

func to_fen() -> String:
	"""
	Convert the piece placement array to a FEN string.
	"""
	var pos = []
	for idx in range(_position.size()):
		var piece = _position[idx]
		
		if idx > 0 and idx % 8 == 0:
			pos.append("/")
		
		if piece.strip_edges() != "":
			pos.append(piece)
		elif pos.size() > 0 and pos[-1].is_valid_int():
			pos[-1] = str(int(pos[-1]) + 1)
		else:
			pos.append("1")
	return "".join(pos)

func set_piece_pos(position: String) -> void:
	"""
	Convert a FEN position string into a piece placement array.
	"""
	_position.clear()
	for char in position:
		if char == "/":
			continue
		elif char.is_valid_int():
			for i in range(int(char)):
				_position.append(" ")
		else:
			_position.append(char)

func get_piece(index: int) -> String:
	"""
	Get the piece at the given index in the position array.
	"""
	return _position[index]

func get_piece_owner(index: int) -> String:
	"""
	Get the owner of the piece at the given index in the position array.
	"""
	var piece = get_piece(index)
	if piece.strip_edges() != "":
		return "w" if piece == piece.to_upper() else "b"
	return ""

func move_piece(start: int, end: int, piece: String) -> void:
	"""
	Move a piece by removing it from the starting position and adding it
	to the end position. If a different piece is provided, that piece will
	be placed at the end index instead.
	"""
	_position[end] = piece
	_position[start] = " "

func find_piece(symbol: String) -> int:
	"""
	Find the index of the specified piece on the board,
	returns -1 if not found.
	"""
	for i in range(_position.size()):
		if _position[i] == symbol:
			return i
	return -1
