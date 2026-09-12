@tool
class_name CloudArea
extends Control

enum Type { DEPRECATED_CLASSIC, MAP, FOW, DEPRECATED_HUB, WISP }

@export var random_seed: int = 0:
	set(value):
		random_seed = value
		if is_node_ready():
			update()
@export var y_spacing: float = 80.0:
	set(value):
		y_spacing = value
		if is_node_ready():
			update()
@export var x_spacing: float = 120.0:
	set(value):
		x_spacing = value
		if is_node_ready():
			update()
@export var offset_randomization: float = 40:
	set(value):
		offset_randomization = value
		if is_node_ready():
			update()
@export var min_scale: float = 0.18:
	set(value):
		min_scale = value
		if is_node_ready():
			update()
@export var max_scale: float = 1.2:
	set(value):
		max_scale = value
		if is_node_ready():
			update()
@export var scale_randomization: float = 0.25:
	set(value):
		scale_randomization = value
		if is_node_ready():
			update()
@export var speed_randomization: float = 0.4:
	set(value):
		speed_randomization = value
		if is_node_ready():
			update()
@export var cloud_type: Type = Type.WISP:
	set(value):
		if cloud_type != value:
			cloud_type = value
			if is_node_ready():
				update(true)
@export var speed: float = -13.0:
	set(value):
		speed = value
		if is_node_ready():
			update()
@export var map: Map:
	set(value):
		map = value
		if is_node_ready():
			update()

@export_tool_button('Regenerate')
@warning_ignore('unused_private_class_variable')
var _update_tool := update

func update(changed_type: bool = false, batch_size: int = 0) -> void:
	if Utils.is_compatibility_renderer() or not GameSettings.Display.clouds_on_map.value():
		if cloud_type in [Type.FOW, Type.MAP]:
			# Not supported in compatibility renderer dueto instance uniforms.
			Utils.clear_node(self)
			return

	if not size.x:
		await get_tree().process_frame  # Wait for parent to size me.
	var random := RandomState.new(random_seed)
	if changed_type:
		Utils.clear_node(self)
	var index := 0
	var existing_sprites := get_child_count()
	var y: float = 0.0
	while y < size.y:
		var scale_factor := (1.0 + (random.rand_float() - 0.5) * scale_randomization)
		var cloud_scale := remap(y, 0, size.y, min_scale, max_scale) * scale_factor
		for x in range(0, size.x, x_spacing * cloud_scale):
			var sprite: Sprite2D
			if index < existing_sprites and not changed_type:
				# Reuse sprite.
				sprite = get_child(index)
				if not Utils.ensure(sprite is Sprite2D):
					continue
			else:
				# Create new sprite.
				match cloud_type:
					Type.DEPRECATED_CLASSIC:
						push_error('Classic cloud types deprecated.')
						return
					Type.MAP:
						sprite = MapCloud.new()
					Type.FOW:
						sprite = FowCloud.new()
					Type.DEPRECATED_HUB:
						push_error('Hub cloud types deprecated.')
						return
					Type.WISP:
						sprite = WispCloud.new()
			index += 1
			if batch_size and index % batch_size == batch_size - 1:
				await get_tree().process_frame

			match cloud_type:
				Type.DEPRECATED_CLASSIC:
					push_error('Classic cloud types deprecated.')
					return
				Type.MAP:
					var map_cloud := sprite as MapCloud
					map_cloud.speed = speed * cloud_scale
					map_cloud.speed_randomization = speed_randomization
					map_cloud.landmass_sdf = map.generated_map.distance_to_land_texture
					map_cloud.map_rect = map.get_map_content_rect()
				Type.FOW:
					var fow_cloud := sprite as FowCloud
					fow_cloud.speed = speed * cloud_scale
					fow_cloud.speed_randomization = speed_randomization
					fow_cloud.fow_texture = map.get_fow_texture()
					fow_cloud.map_rect = map.get_map_content_rect()
				Type.DEPRECATED_HUB:
					push_error('Hub cloud types deprecated.')
					return
				Type.WISP:
					var wisp_cloud := sprite as WispCloud
					wisp_cloud.speed = speed * cloud_scale
					wisp_cloud.speed_randomization = speed_randomization

			if not sprite.get_parent():
				add_child(sprite)
				sprite.owner = owner
			var random_offset := offset_randomization * sqrt(cloud_scale)
			var cloud_pos := Vector2(x + random.rand_float(-random_offset, random_offset),
									y + random.rand_float(-random_offset, random_offset))
			sprite.position = cloud_pos
			sprite.scale = Vector2(cloud_scale, cloud_scale)
		y += y_spacing * sqrt(cloud_scale)

	if index < existing_sprites and not changed_type:
		Utils.clear_node(self, index)
