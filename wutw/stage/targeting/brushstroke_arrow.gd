@tool
class_name BrushstrokeArrow
extends TextureRect

@export var color: Color = Color.BLACK:
	set(value):
		color = value
		_update_style()
@export var arrowhead_size: int = 100:
	set(value):
		arrowhead_size = value
		_update_style()
@export var arrowhead_texture_range: float = 0.2:
	set(value):
		arrowhead_texture_range = value
		_update_style()
@export var card: Card:
	set(value):
		card = value
		visible = card != null
@export var target_override: Vector2 = Vector2(-1, -1)

func _ready() -> void:
	_update_style()
	visible = false

func _process(_delta: float) -> void:
	if card:
		var card_corner := card.get_global_transform().origin
		var card_size := card.get_rect().size
		var origin := card_corner + card_size / 2
		var target := get_viewport().get_mouse_position() if target_override.x < 0 else target_override
		orient(origin, target)

func orient(origin: Vector2, target: Vector2) -> void:
	position = target - pivot_offset
	custom_minimum_size = Vector2(origin.distance_to(target), get_combined_minimum_size().y)
	size = custom_minimum_size
	rotation = (origin - target).angle()

func _update_style() -> void:
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter('color', color)
	shader_material.set_shader_parameter('arrowhead_pixels', arrowhead_size)
	shader_material.set_shader_parameter('arrowhead_u', arrowhead_texture_range)
