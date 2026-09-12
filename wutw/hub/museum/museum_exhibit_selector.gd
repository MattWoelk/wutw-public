class_name MuseumExhibitSelector
extends Control

signal closed

static var TILE_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_tile.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var exhibit_index: int
@export var exhibit: MuseumExhibit

var _closing := false

func _ready() -> void:
	Utils.clear_node(%List)
	_add_tile(null)
	for image in MuseumExhibit.get_available_images():
		_add_tile(image)

	(%ScrollPanel as ScrollPanel).animate_unroll()

func _handle_esc() -> bool:
	close()
	return true

func close() -> void:
	if not _closing:
		_closing = true
		Utils.set_input_enabled(self, false)
		(%BG as FadedBackground).fade_out()
		await (%ScrollPanel as ScrollPanel).animate_roll()
		queue_free()
		closed.emit()

func _on_cancel_button_pressed() -> void:
	close()

func _add_tile(image: LazyTextureResource) -> void:
	var tile := TILE_SCENE.instantiate_loaded_scene() as MuseumTile
	tile.image = await image.get_texture_async() if image else null
	tile.discovered = true
	tile.toggle_mode = false
	if image:
		tile.is_wide = tile.image.get_width() > tile.image.get_height()
		tile.is_tall = not tile.is_wide
	tile.pressed.connect(_on_exhibit_clicked.bind(image))
	%List.add_child(tile)

func _on_exhibit_clicked(image: LazyTextureResource) -> void:
	exhibit.image = image
	GlobalSaveGame.set_displayed_museum_exhibit(exhibit_index, image)
	GlobalSaveGame.save_game()
	close()
