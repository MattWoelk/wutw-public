@tool
class_name EventStep
extends Resource

@export var event_step_id: String
@export_multiline var markedup_text: String
@export var background_image: LazyTextureResource
@export var background_credit: ArtPiece
@export var choices: Array[EventChoice]
@export var exit_choice: EventChoice

var background: Texture2D:
	get():
		if not Utils.is_in_editor() and not background_image.is_loaded():
			push_warning('Event background loaded synchronously.')
		return background_image.get_texture_sync()
	set(value):
		Utils.ensure(false)

func start_loading_texture() -> Texture2D:
	return await background_image.get_texture_async()
