@tool
class_name TutorialArrow
extends TextureRect

enum RelativeDirection {
	BELOW,
	RIGHT,
	ABOVE,
	LEFT,
}

@export var color: Color = Color.BLACK:
	set(value):
		color = value
		_update_style()
@export var total_size: int = 200
@export var arrowhead_size: int = 100:
	set(value):
		arrowhead_size = value
		_update_style()
@export var arrowhead_texture_range: float = 0.2:
	set(value):
		arrowhead_texture_range = value
		_update_style()
@export var direction: RelativeDirection
@export var target: Control

func _ready() -> void:
	var tween := create_tween()
	modulate.a = 0
	tween.tween_property(self, 'modulate:a', 1.0, 0.25)
	tween.play()

func _process(_delta: float) -> void:
	if target and target.is_visible_in_tree():
		var target_rect := target.get_global_rect()
		if direction == RelativeDirection.ABOVE:
			var tip := target_rect.position + Vector2(target_rect.size.x / 2, 0)
			orient(tip - Vector2(0, total_size), tip)
		elif direction == RelativeDirection.BELOW:
			var tip := target_rect.position + Vector2(target_rect.size.x / 2, target_rect.size.y)
			orient(tip + Vector2(0, total_size), tip)
		elif direction == RelativeDirection.LEFT:
			var tip := target_rect.position + Vector2(0, target_rect.size.y / 2)
			orient(tip - Vector2(total_size, 0), tip)
		elif direction == RelativeDirection.RIGHT:
			var tip := target_rect.position + Vector2(target_rect.size.x, target_rect.size.y / 2)
			orient(tip + Vector2(total_size, 0), tip)

func remove() -> void:
	var tween := create_tween()
	tween.tween_property(self, 'modulate:a', 0.0, 0.25)
	tween.play()
	await tween.finished
	queue_free()

func orient(origin: Vector2, target_pos: Vector2) -> void:
	position = target_pos - pivot_offset
	custom_minimum_size = Vector2(origin.distance_to(target_pos), get_combined_minimum_size().y)
	size = custom_minimum_size
	rotation = (origin - target_pos).angle()

func _update_style() -> void:
	var shader_material := material as ShaderMaterial
	shader_material.set_shader_parameter('color', color)
	shader_material.set_shader_parameter('arrowhead_pixels', arrowhead_size)
	shader_material.set_shader_parameter('arrowhead_u', arrowhead_texture_range)
