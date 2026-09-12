class_name ArtSeries
extends Resource

@export var name: String
@export_multiline var blurb: String
@export var start_year: int
@export var end_year: int
@export var artist: Artist
@export var link: String

func get_pieces() -> Array[ArtPiece]:
	var pieces: Array[ArtPiece]
	for piece in ArtViewer.get_all_pieces():
		if piece is ArtPiece_Single and (piece as ArtPiece_Single).series == self:
			pieces.append(piece)
	return pieces
