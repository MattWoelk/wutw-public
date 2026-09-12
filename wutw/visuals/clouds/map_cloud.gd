@tool
class_name MapCloud
extends Sprite2D

static var MATERIAL := AsyncLoadedResource.new('res://visuals/clouds/map_cloud_material.tres')
static var TEXTURE := AsyncLoadedResource.new('res://visuals/clouds/white_200x200.png', false, AsyncLoadedResource.LoadPhase.STARTUP)

@export var map_rect: Rect2
@export var speed: float = -13.0
@export var speed_randomization: float = 0.4
@export var landmass_sdf: Texture2D:
	set(value):
		landmass_sdf = value
		(material as ShaderMaterial).set_shader_parameter('landmass_sdf', landmass_sdf)

func _init() -> void:
	if not material:
		material = MATERIAL.get_loaded()
	if not texture:
		texture = TEXTURE.get_loaded()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func _ready() -> void:
	set_instance_shader_parameter('variation_random', randf())
	set_instance_shader_parameter('landmass_sdf', landmass_sdf)
	speed *= randf_range(1.0 - speed_randomization, 1.0 + speed_randomization)

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
