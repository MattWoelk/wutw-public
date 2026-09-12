@tool
class_name FowCloud
extends Sprite2D

@export var map_rect: Rect2
@export var speed: float = -13.0
@export var speed_randomization: float = 0.4
@export var fow_texture: Texture2D

func _init() -> void:
	if not material:
		material = load('res://visuals/clouds/fow_cloud_material.tres')
	if not texture:
		texture = load('res://visuals/clouds/white_200x200.png')
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func _ready() -> void:
	(material as ShaderMaterial).set_shader_parameter('fow_texture', fow_texture)
	set_instance_shader_parameter('variation_random', randf())

func _process(delta: float) -> void:
	if not texture:
		return
	# Let the shader know where we are.
	var relative_position := global_position - map_rect.position
	var half_size := texture.get_size() * scale / 2
	var start_coord := (relative_position - half_size) / map_rect.size
	var end_coord := (relative_position + half_size) / map_rect.size
	set_instance_shader_parameter('global_rect', Vector4(
			start_coord.x, start_coord.y, end_coord.x, end_coord.y))

	# Move and wrap around the sides of the screen, with fading.
	if not Utils.is_in_editor():
		var parent_width: float = 1920
		var parent := get_parent() as CloudArea
		if parent:
			parent_width = parent.size.x

		position.x += delta * speed
		var half_width := texture.get_width() * scale.x / 2
		if position.x < -half_width:
			position.x = parent_width + half_width
