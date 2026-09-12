@tool
class_name MuseumTile
extends Button

const TRANSITION_SPEED := 12
const STANDARD_SIZE := Vector2(165, 165)
const TALL_SIZE := Vector2(165, 227)
const WIDE_SIZE := Vector2(247, 138)

@export var exhibit: Resource
@export var image: Texture2D:
	set(value):
		image = value
		if is_node_ready():
			_update()
@export var image_lazy: LazyTextureResource:
	set(value):
		image_lazy = value
		if is_node_ready():
			_update()
@export var discovered: bool = false:
	set(value):
		discovered = value
		if is_node_ready():
			_update()
@export var is_tall: bool = false:
	set(value):
		is_tall = value
		if is_node_ready():
			_update()
@export var is_wide: bool = false:
	set(value):
		is_wide = value
		if is_node_ready():
			_update()

var _hovered_t: float = 0.0
var _selected_t: float = 0.0

func _ready() -> void:
	if not Utils.is_in_editor():
		if Utils.is_compatibility_renderer():
			(%Image as TextureRect).material = (%Image as TextureRect).material.duplicate()
		else:
			(%Image as TextureRect).material = load('res://hub/museum/museum_tile.tres')
	_update()

func _process(delta: float) -> void:
	_hovered_t = lerpf(_hovered_t, float(is_hovered()), TRANSITION_SPEED * delta)
	_selected_t = lerpf(_selected_t, float(button_pressed), TRANSITION_SPEED * delta)
	if Utils.is_compatibility_renderer():
		((%Image as TextureRect).material as ShaderMaterial).set_shader_parameter('hovered', _hovered_t)
		((%Image as TextureRect).material as ShaderMaterial).set_shader_parameter('selected', _selected_t)
	else:
		(%Image as TextureRect).set_instance_shader_parameter('hovered', _hovered_t)
		(%Image as TextureRect).set_instance_shader_parameter('selected', _selected_t)
	size = custom_minimum_size
	(%Container as Control).custom_minimum_size = custom_minimum_size
	(%Container as Control).custom_maximum_size = custom_minimum_size
	(%MissingLabel as Label).add_theme_font_size_override(
		'font_size', 132 if size.y > 150 else 90)

func _update() -> void:
	if is_tall:
		custom_minimum_size = TALL_SIZE
	elif is_wide:
		custom_minimum_size = WIDE_SIZE
	else:
		custom_minimum_size = STANDARD_SIZE
	if Utils.is_compatibility_renderer():
		pass
	else:
		(%Image as TextureRect).set_instance_shader_parameter('is_tall', is_tall)
		(%Image as TextureRect).set_instance_shader_parameter('is_wide', is_wide)
		(%Image as TextureRect).set_instance_shader_parameter('discovered', discovered)

	if discovered:
		if image_lazy:
			(%Image as TextureRect).texture = await image_lazy.get_texture_async()
		elif image:
			(%Image as TextureRect).texture = image
		else:
			(%Image as TextureRect).texture = load('res://visuals/transparent.png')
		(%MissingLabel as Control).visible = false
		(%EmptyLabel as Control).visible = image == null
	else:
		if exhibit is Relic or exhibit is Companion:
			(%Image as TextureRect).texture = image
			(%MissingLabel as Control).visible = false
		else:
			(%Image as TextureRect).texture = load('res://visuals/transparent.png')
			(%MissingLabel as Control).visible = true
		(%EmptyLabel as Control).visible = false

	# Exceptions
	if exhibit is Dialogue:
		var dialogue_title := (exhibit as Dialogue).record_title
		(%TitleLabel as Label).text = dialogue_title
		if dialogue_title.begins_with('Debate Speech: '):
			(%TitleLabel as Label).text = tr(dialogue_title).replace(tr('Debate Speech: '), tr('Speech:\n'))
		elif tr(dialogue_title).begins_with('Era '):
			# HACK: This doesn't work on translated text.
			(%TitleLabel as Label).text = tr(dialogue_title).left(5) + '\n' + tr(dialogue_title).substr(7)
		(%TitleLabel as Label).visible = true
		(%EmptyLabel as Control).visible = false
	elif exhibit is Quest_Settler:
		(%TitleLabel as Label).text = tr((exhibit as Quest_Settler).name)
		(%TitleLabel as Label).visible = discovered
		(%EmptyLabel as Control).visible = false
	else:
		(%TitleLabel as Label).visible = false

func _on_mouse_entered() -> void:
	GlobalAudioSystem.play(AK.EVENTS.UI_MENU_HUB_MUSEUM_SITES_HOVER)
