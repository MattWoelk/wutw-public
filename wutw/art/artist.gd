class_name Artist
extends Resource

@export var name: String
@export var portrait: LazyTextureResource
@export_multiline var blurb: String
@export var birth_year: int
@export var death_year: int
@export var custom_date: String
@export var link: String
@export var schools: Array[ArtSchool]

func get_pieces() -> Array[ArtPiece]:
	var pieces: Array[ArtPiece]
	for piece in ArtViewer.get_all_pieces():
		if piece is ArtPiece_Single and (piece as ArtPiece_Single).artist == self:
			pieces.append(piece)
		elif piece is ArtPiece_Original and (piece as ArtPiece_Original).artist == self:
			pieces.append(piece)
	return pieces
