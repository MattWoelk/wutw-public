@tool
class_name Road
extends Line2D

@export var map: Map
@export var skip_animation := false

var _placement: MapSpritePlacement
var _fadein_tween: Tween

func _ready() -> void:
	assert(map)
	_placement = MapSpritePlacement.new()
	var sprite_type := MapSpriteType_Generic.new()
	_placement.sprite_type = sprite_type
	_placement.location = Vector2.ZERO
	var length := 0.0
	for i in points.size() - 1:
		var line := MapSpriteCollision_Line.new()
		line.p1 = points[i]
		line.p2 = points[i + 1]
		line.blocking = true
		sprite_type.collision.append(line)
		for intersecting: MapSpritePlacement in map.generated_map.sprites_quad_tree.query_line(line.p1, line.p2, true):
			if intersecting.sprite_type.removable:
				map.generated_map.sprites_quad_tree.remove(intersecting)
				map.get_sprite_renderer().animate_remove_placement(intersecting)
			elif intersecting != _placement and Utils.is_dev():
				push_warning('Found non-removal intersecting sprite when placing road (',
							  intersecting.sprite_type.resource_path, ') at ', intersecting.location)
		map.generated_map.sprites_quad_tree.add_line(_placement, line.p1, line.p2, true)
		length += line.p1.distance_to(line.p2)
	map.get_sprite_renderer().add_placement(_placement)

	material = material.duplicate()
	(material as ShaderMaterial).set_shader_parameter('path_length', length)
	if skip_animation:
		(material as ShaderMaterial).set_shader_parameter('progress', 1.0)
	else:
		_fadein_tween = create_tween()
		var draw_sfx_id := GlobalAudioSystem.start_loop(AK.EVENTS.UI_MENU_SLIDER_LOOP, self)
		_fadein_tween.tween_method(func(value: float) -> void:
			(material as ShaderMaterial).set_shader_parameter('progress', value)
		, 0.0, 1.0, 2.0)
		_fadein_tween.tween_callback(GlobalAudioSystem.stop_loop.bind(draw_sfx_id))
		_fadein_tween.play()

func _exit_tree() -> void:
	if _fadein_tween:
		_fadein_tween.kill()
		_fadein_tween = null
	map.generated_map.sprites_quad_tree.remove(_placement)
	map.get_sprite_renderer().remove_placement(_placement)
