class_name ArtPiece_Composed
extends ArtPiece

@export var name: String
@export var main: ArtPiece
@export var additional: Array[ArtPiece]
@export var used_series: ArtSeries
@export var edits_description: String

func get_title() -> String:
	return tr(name)

func get_attribution() -> String:
	var text := tr(name)

	if main:
		Utils.ensure(not used_series)
		text += tr(', a composition based on:\n') + main.get_attribution().indent('  ')
	elif used_series:
		text += tr(', a composition based on:\n  {series_name} by {artist_name}').format({
			series_name=tr(used_series.name),
			artist_name=tr(used_series.artist.name),
		})

	for piece in additional:
		text += '\n\n' + piece.get_attribution().indent('  ')
	return text

func get_original_image() -> Texture2D:
	if final_image_tex:
		return await final_image_tex.get_texture_async()
	else:
		return await main.get_original_image()

func get_start_year() -> int:
	var start: int
	if main:
		Utils.ensure(not used_series)
		start = main.get_start_year()
	elif used_series:
		start = used_series.start_year

	for piece in additional:
		start = mini(start, piece.get_start_year())
	return start

func get_end_year() -> int:
	var end: int
	if main:
		Utils.ensure(not used_series)
		end = main.get_end_year()
	elif used_series:
		end = used_series.end_year
	for piece in additional:
		end = maxi(end, piece.get_end_year())
	return end

func get_sort_index() -> int:
	return 2
