class_name ArtPiece_Placeholder
extends ArtPiece

func get_title() -> String:
	return tr('Placeholder')

func get_attribution() -> String:
	return tr('Placeholder Art')

func get_original_image() -> Texture2D:
	return await final_image_tex.get_texture_async()

func get_start_year() -> int:
	return 2026

func get_end_year() -> int:
	return 2026

func get_sort_index() -> int:
	return 4
