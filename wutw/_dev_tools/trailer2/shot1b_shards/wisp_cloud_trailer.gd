@tool
class_name WispCloud_Trailer
extends Sprite2D

static var MATERIAL := AsyncLoadedResource.new('res://_dev_tools/trailer2/shot1b_shards/wisp_cloud_trailer_material.tres')

@export var speed: float = -13.0
@export var speed_randomization: float = 0.8

func _init() -> void:
	if not material:
		material = MATERIAL.get_loaded() as Material
	if not texture:
		texture = load('res://visuals/clouds/cloud_wisp_%s.png' % randi_range(1, 5))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func _ready() -> void:
	self_modulate.a = randf_range(0.7, 1.3)
	speed *= randf_range(1.0 - speed_randomization, 1.0 + speed_randomization)

func _process(delta: float) -> void:
	if not Utils.is_in_editor():
		const DIR := Vector2(2.0, 0.5)
		position += delta * speed * DIR * position.direction_to(Vector2(960, 1080))
