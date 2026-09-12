extends Node2D

func _ready() -> void:
	GlobalGameSettings.read_only = true
	GlobalSaveGame.init_new_game(13)

	await get_tree().create_timer(0.1).timeout

	ArtViewer.open_art_resource(load('res://art/pieces/piece_hiroshige_sumidagawa.tres'))
	await get_tree().create_timer(4.5).timeout

	ArtViewer.open_art_resource(load('res://art/pieces/piece_shigenobu_excursions.tres'))
	await get_tree().create_timer(4).timeout

	ArtViewer.open_art_resource(load('res://art/pieces/piece_hiroshige_yoshitada.tres'))
	await get_tree().create_timer(4).timeout

	ArtViewer.open_art_resource(load('res://art/pieces/piece_hiroshige_yoemon.tres'))
	await get_tree().create_timer(4).timeout

	if OS.has_feature('movie'):
		get_tree().quit()
