class_name ArtSchool
extends Resource

@export var name: String
@export_multiline var blurb: String
@export var start_year: int  # -1: unknown
@export var end_year: int  # -1: unknown
@export var link: String

func get_pieces() -> Array[ArtPiece]:
	var pieces: Array[ArtPiece]
	for piece in ArtViewer.get_all_pieces():
		if (piece is ArtPiece_Single and (piece as ArtPiece_Single).artist
				and self in (piece as ArtPiece_Single).artist.schools):
			pieces.append(piece)
	return pieces
