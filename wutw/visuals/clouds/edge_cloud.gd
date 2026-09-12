@tool
class_name EdgeCloud
extends Sprite2D

static var MATERIAL := AsyncLoadedResource.new('res://visuals/clouds/edge_cloud_material.tres')
static var TEXTURE := AsyncLoadedResource.new('res://visuals/clouds/white_200x200.png', false, AsyncLoadedResource.LoadPhase.STARTUP)

@export var map_rect: Rect2
@export var land_sdf: Texture2D
@export var land_depth: Texture2D

func _init() -> void:
	if not material:
		material = MATERIAL.get_loaded()
	if not texture:
		texture = TEXTURE.get_loaded()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func _ready() -> void:
	set_instance_shader_parameter('variation_random', randf())
	(material as ShaderMaterial).set_shader_parameter('landmass_sdf', land_sdf)
	(material as ShaderMaterial).set_shader_parameter('land_depth_texture', land_depth)

	await get_tree().process_frame  # Let sizing update.

	# Let the shader know where we are.
	var relative_position := global_position - map_rect.position
	var half_size := texture.get_size() * global_scale / 2
	var start_coord := (relative_position - half_size) / map_rect.size
	var end_coord := (relative_position + half_size) / map_rect.size
	set_instance_shader_parameter('global_rect', Vector4(
			start_coord.x, start_coord.y, end_coord.x, end_coord.y))
