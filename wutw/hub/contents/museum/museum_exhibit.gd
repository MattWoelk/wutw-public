class_name MuseumExhibit
extends HubFacility

@export var image: LazyTextureResource:
	set(value):
		image = value
		if is_node_ready():
			_update()

static var _art_piece_lookup: Dictionary[String, ArtPiece]

var _material: ShaderMaterial

static func get_available_images() -> Array[LazyTextureResource]:
	var unlocked: Dictionary[String, bool]
	var result: Array[LazyTextureResource]
	for event: Event in GlobalSaveGame.get_seen_event_choices().keys():
		if event.steps and event.steps[0].background_image:
			if event.steps[0].background_credit is ArtPiece_Placeholder or event.steps[0].background_credit is ArtPiece_None:
				continue
			var path := event.steps[0].background_image._texture_path
			if path not in unlocked:
				result.append(event.steps[0].background_image)
				unlocked[path] = true
				_art_piece_lookup[path] = event.steps[0].background_credit
	for episode: SurveyEpisode in GlobalSaveGame.get_seen_surveys().keys():
		if Utils.ensure(episode.background_image != null):
			if episode.background_credit is ArtPiece_Placeholder or episode.background_credit is ArtPiece_None:
				continue
			var path := episode.background_image._texture_path
			if path not in unlocked:
				result.append(episode.background_image)
				unlocked[path] = true
				_art_piece_lookup[path] = episode.background_credit
	# Could allow art other than event BGs, but if it's all ArtPieces, then the player is flooded.

	return result

func _ready() -> void:
	super._ready()
	_material = (%ArtCanvas as Sprite2D).material.duplicate()
	(%ArtCanvas as Sprite2D).material = _material
	_update()

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not highlighted:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event or not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		if image and Utils.is_museum_unlocked():
			Utils.ensure(image._texture_path in _art_piece_lookup)
			ArtViewer.open_art_resource(_art_piece_lookup[image._texture_path])

func _update() -> void:
	if image:
		var loaded_image := await image.get_texture_async()
		_material.set_shader_parameter('image', loaded_image)
		_material.set_shader_parameter('image_size', loaded_image.get_size())
	else:
		_material.set_shader_parameter('image', load('res://visuals/transparent.png'))
		_material.set_shader_parameter('image_size', Vector2.ONE)

func _make_tooltip_text() -> String:
	var result := tr(tooltip_text)
	if image:
		result += '\n\n' + tr('%s to open in art viewer.') % InputPrompts.get_input_markup(
				InputPrompts.InputType.RIGHT_CLICK)
	return result
