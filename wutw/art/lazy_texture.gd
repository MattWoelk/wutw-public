@tool
class_name LazyTextureResource
extends Resource

var _texture_path := ''
var _is_horizontal := false

var _cached_texture: Texture2D

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			'name': 'lazy_texture',
			'type': TYPE_OBJECT,
			'hint': PROPERTY_HINT_RESOURCE_TYPE,
			'hint_string': 'Texture2D',
			'usage': PROPERTY_USAGE_EDITOR
		},
		{
			'name': '_texture_path',
			'type': TYPE_STRING,
			'usage': PROPERTY_USAGE_STORAGE
		},
		{
			'name': '_is_horizontal',
			'type': TYPE_BOOL,
			'usage': PROPERTY_USAGE_STORAGE
		},
		{
			'name': '_cached_texture',
			'type': TYPE_OBJECT,
			'hint': PROPERTY_HINT_RESOURCE_TYPE,
			'hint_string': 'Texture2D',
			'usage': PROPERTY_USAGE_NONE
		},
	]

func _set(property: StringName, value: Variant) -> bool:
	if property == &'lazy_texture':
		assert(value is Texture2D)
		var texture := value as Texture2D
		var uid := ResourceLoader.get_resource_uid(texture.resource_path)
		assert(uid != ResourceUID.INVALID_ID)
		_texture_path = ResourceUID.id_to_text(uid)
		_is_horizontal = texture.get_size().x > texture.get_size().y
		return true
	elif property == &'_texture_path':
		_texture_path = value
		return true
	elif property == &'_is_horizontal':
		_is_horizontal = value
		return true
	elif property == &'_cached_texture':
		_cached_texture = value
		return true
	else:
		return false

func _get(property: StringName) -> Variant:
	if property == &'lazy_texture':
		if Utils.is_in_editor() and not _texture_path.is_empty() and ResourceLoader.exists(_texture_path):
			return load(_texture_path)
		return null
	elif property == &'_texture_path':
		return _texture_path
	elif property == &'_is_horizontal':
		return _is_horizontal
	elif property == &'_cached_texture':
		return _cached_texture
	else:
		return null

func is_horizontal() -> bool:
	return _is_horizontal

func is_loaded() -> bool:
	return _cached_texture != null

func get_texture_sync() -> Texture2D:
	if _cached_texture:
		return _cached_texture
	if _texture_path.is_empty():
		return null
	_cached_texture = load(_texture_path) as Texture2D
	return _cached_texture

func get_texture_async() -> Texture2D:
	if _cached_texture:
		return _cached_texture
	if _texture_path.is_empty():
		return null
	ResourceLoader.load_threaded_request(_texture_path)
	while ResourceLoader.load_threaded_get_status(_texture_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await (Engine.get_main_loop() as SceneTree).process_frame
	_cached_texture = ResourceLoader.load_threaded_get(_texture_path) as Texture2D
	return _cached_texture
