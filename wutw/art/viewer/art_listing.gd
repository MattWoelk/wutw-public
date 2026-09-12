@tool
class_name ArtListing
extends Control

static var ENTRY_SCENE := AsyncLoadedResource.new('res://art/viewer/art_listing_entry.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var art_pieces: Array[ArtPiece]:
	set(value):
		art_pieces = value
		_update()

func _ready() -> void:
	_update()

func _update() -> void:
	if not is_node_ready():
		return

	Utils.clear_node(%List)
	for piece in art_pieces:
		var entry := ENTRY_SCENE.instantiate_loaded_scene() as ArtListingEntry
		entry.art_piece = piece
		%List.add_child(entry)
		entry.clicked.connect(ArtViewer.open_art_resource.bind(piece))
	(%Label as Label).visible = %List.get_child_count() > 0
