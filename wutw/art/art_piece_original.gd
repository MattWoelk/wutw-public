class_name ArtPiece_Original
extends ArtPiece

@export var name: String
@export var based_on: ArtPiece
@export var artist: Artist

func get_title() -> String:
	return tr(name)

func get_attribution() -> String:
	var text := tr(name) + '\n' + tr('Worlds Upon The Wind Original')
	if based_on:
		text += '\n' + tr('Based on:') + '\n' + based_on.get_attribution().indent('  ')
	return text

func get_original_image() -> Texture2D:
	return await final_image_tex.get_texture_async()

func get_start_year() -> int:
	return 2026

func get_end_year() -> int:
	return 2026

func get_sort_index() -> int:
	return 3
