@tool
class_name WispCloud
extends Sprite2D

static var MATERIAL := AsyncLoadedResource.new('res://visuals/clouds/wisp_cloud_material.tres')

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
	# Move and wrap around the sides of the screen.
	if not Utils.is_in_editor():
		var parent_width: float = 1920
		var parent := get_parent() as CloudArea
		if parent:
			parent_width = parent.size.x

		position.x += delta * speed
		var half_width := texture.get_width() * scale.x / 2
		if position.x < -half_width:
			position.x = parent_width + half_width
