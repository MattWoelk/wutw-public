class_name MapPreview
extends PanelContainer

const ZOOM_SPEED := 0.3
const DEFAULT_FOCUS_DURATION := 1.0
const DEFAULT_FOCUS_ZOOM := 5.0
const REVEAL_DURATION := 0.3
const FOW_TWEEN_DURATION := 1.8
const MIN_ZOOM_DELTA_FOR_SFX := 3.0

@export var generation_config: MapGenerationConfig
@export var generated_map: GeneratedMap

@export_group('Camera Settings')
@export var pan_speed: float = 600.0
@export var zoom_step: float = 0.2
@export var zoom_step_keyboard: float = 4.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 10.0

var _target_zoom: float = 2.0
var _target_position: Vector2
var _dragging: bool = false
var _drag_start_cursor: Vector2
var _drag_start_camera: Vector2
var _camera: Camera2D
var _generation_in_progress: bool = false

func _ready() -> void:
	if Utils.is_in_editor():
		return
	_camera = %Camera as Camera2D
	_target_zoom = _camera.zoom.x
	_target_position = _camera.position
	if generated_map:
		set_generated_map(generated_map)

func _process(delta: float) -> void:
	if Utils.is_in_editor():
		return

	if not is_equal_approx(_camera.zoom.x, _target_zoom):
		_camera.zoom = Vector2.ONE * lerp(_camera.zoom.x, _target_zoom, ZOOM_SPEED)
	_camera.position = _clamp_camera_position(lerp(_camera.position, _target_position, ZOOM_SPEED) as Vector2)

	if GlobalUI.is_higher_level_active(self):
		return

	# Zoom keyboard controls.
	if Input.is_action_pressed('map_zoom_in'):
		_tween_zoom_at(1 + zoom_step_keyboard * delta, get_subviewport_half_size())
	elif Input.is_action_pressed('map_zoom_out'):
		_tween_zoom_at(1 - zoom_step_keyboard * delta, get_subviewport_half_size())

	# Pan controls.
	var dir := Vector2(Input.get_action_strength('map_pan_right')
					   - Input.get_action_strength('map_pan_left'),
					   Input.get_action_strength('map_pan_down')
					   - Input.get_action_strength('map_pan_up')).normalized()
	if dir != Vector2.ZERO:
		_target_position = _clamp_camera_position(_target_position + dir * pan_speed * delta)

	# Drag controls.
	if Input.is_action_just_pressed('mouse_pan'):
		_dragging = true
		_drag_start_cursor = get_local_mouse_position()
		_drag_start_camera = _camera.position
	elif Input.is_action_just_released('mouse_pan'):
		_dragging = false
	elif Input.is_action_pressed('mouse_pan') and _dragging:
		var offset := (get_local_mouse_position() as Vector2 - _drag_start_cursor) / (_camera.zoom.x as float)
		_target_position = _clamp_camera_position(_drag_start_camera - offset)

func _on_gui_input(event: InputEvent) -> void:
	if GlobalUI.is_higher_level_active(self):
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_tween_zoom_at(1 + zoom_step, mouse_event.position)
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_tween_zoom_at(1 - zoom_step, mouse_event.position)
	elif event is InputEventMagnifyGesture:
		var gesture_event := event as InputEventMagnifyGesture
		_tween_zoom_at(gesture_event.factor, gesture_event.position)
	elif event is InputEventPanGesture:
		var pan_event := event as InputEventPanGesture
		if pan_event.delta.y < 0:
			_tween_zoom_at(1 + zoom_step, pan_event.position)
		elif pan_event.delta.y > 0:
			_tween_zoom_at(1 - zoom_step, pan_event.position)

func regenerate(rng: RandomState) -> void:
	_generation_in_progress = true

	var tween: Tween
	if generated_map:
		tween = create_tween()
		tween.tween_property(self, 'modulate:a', 0.0, REVEAL_DURATION)
		tween.play()
		await tween.finished
	else:
		modulate.a = 0

	generated_map = null
	var thread := Thread.new()
	thread.start(_generate_threaded.bind(%MapGenerator, rng))
	while _generation_in_progress:
		await get_tree().process_frame
	thread.wait_to_finish()

	tween = create_tween()
	tween.tween_property(self, 'modulate:a', 1.0, REVEAL_DURATION)
	tween.play()

func _generate_threaded(generator: MapGenerator, rng: RandomState) -> void:
	var new_generated_map: GeneratedMap = generator.generate(generation_config, rng.rand_int(0, 10000))
	set_generated_map.call_deferred(new_generated_map)

func set_generated_map(new_generated_map: GeneratedMap) -> void:
	generated_map = new_generated_map

	(%TextureRect_Sea as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.SEA]
	(%TextureRect_Seashore as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.SEASHORE]
	(%TextureRect_Swamp as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.SWAMP]
	(%TextureRect_Plains as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.PLAINS]
	(%TextureRect_Wasteland as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.WASTELAND]
	(%TextureRect_Steppe as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.STEPPE]
	(%TextureRect_Desert as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.DESERT]
	(%TextureRect_Brushland as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.BRUSHLAND]
	(%TextureRect_Forest as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.FOREST]
	(%TextureRect_Mountain as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.MOUNTAIN]

	(%TextureRect_ShardBase as TextureRect).texture = generated_map.shard_base_texture
	((%TextureRect_ShardBase as TextureRect).material as ShaderMaterial).set_shader_parameter('texture_nearest', generated_map.shard_base_texture)

	(%TextureRect_Border as TextureRect).texture = generated_map.blurred_biome_sdfs[MapBiomes.CLOUDS]
	(%TextureRect_Clip as TextureRect).texture = generated_map.clip_mask

	(%MapSpriteRenderer as MapSpriteRenderer).placements = generated_map.sprites
	((%MapSpriteRenderer as MapSpriteRenderer).material as ShaderMaterial).set_shader_parameter(
		'river_sink_sdf', generated_map.nonland_sdf)

	((%CloudSea as ColorRect).material as ShaderMaterial).set_shader_parameter(
		'landmass_sdf', generated_map.distance_to_land_texture)
	((%CloudSea as ColorRect).material as ShaderMaterial).set_shader_parameter(
		'shard_tex', generated_map.shard_base_texture)

	_generation_in_progress = false  # The rest should happen async

func get_sprite_renderer() -> MapSpriteRenderer:
	return %MapSpriteRenderer as MapSpriteRenderer

func get_camera_location() -> Vector2:
	return get_location_at_map_viewport_position(_camera.position)

func get_location_at_screen_position(screen_position: Vector2, zoom: float = -1) -> Vector2:
	zoom = zoom if zoom > 0 else _camera.zoom.x
	var zoomed_position: Vector2 = _screen_offset_from_center(screen_position) / zoom - (%TextureRect_Clip as TextureRect).position + _camera.position
	return zoomed_position * Vector2(get_map_size()) / (%TextureRect_Clip as TextureRect).size

func get_screen_position_at_location(map_location: Vector2, zoom: float = -1) -> Vector2:
	zoom = zoom if zoom > 0 else _camera.zoom.x
	var clip := %TextureRect_Clip as TextureRect
	return (size * 0.5) + zoom * ((map_location / Vector2(get_map_size()) * clip.size) + clip.position - _camera.position)

func get_location_at_map_viewport_position(viewport_position: Vector2) -> Vector2:
	var clip := %TextureRect_Clip as TextureRect
	return (viewport_position - clip.position) * Vector2(get_map_size()) / clip.size

func get_map_viewport_position_at_location(map_location: Vector2) -> Vector2:
	var clip := %TextureRect_Clip as TextureRect
	return map_location * clip.size / Vector2(get_map_size()) + clip.position

func get_map_size() -> Vector2i:
	return generation_config.size

func get_map_scale() -> Vector2:
	return Vector2(get_subviewport().size) / Vector2(get_map_size())

func get_subviewport() -> SubViewport:
	return %SubViewport as SubViewport

func get_subviewport_half_size() -> Vector2i:
	@warning_ignore('integer_division')
	return (%SubViewport as SubViewport).size / 2

func get_map_content_rect() -> Rect2:
	return (%TextureRect_Clip as TextureRect).get_rect()

func get_zoom() -> float:
	return _camera.zoom.x

func get_current_target_position() -> Vector2:
	return get_location_at_map_viewport_position(_target_position)

func is_camera_moving() -> bool:
	return not (is_equal_approx(_camera.zoom.x, _target_zoom)
				and _target_position.is_equal_approx(_camera.position))

func _tween_zoom_at(mult: float, pivot_screen: Vector2) -> void:
	var z_src := _camera.zoom.x as float
	var z_dst := clampf(z_src * mult, min_zoom, max_zoom)
	if is_equal_approx(z_src, z_dst):
		return

	# Pivot (cursor) location before zoom in map coords.
	var pivot_map := get_location_at_screen_position(pivot_screen)
	# Pivot (cursor) location before zoom in viewport coords.
	var pivot_viewport := get_map_viewport_position_at_location(pivot_map)
	# Offset of pivot from center at original zoom in screen coords.
	var delta_screen := _screen_offset_from_center(pivot_screen)
	# Offset of pivot from center at new zoom in viewport coords.
	var delta_viewport := delta_screen / z_dst
	# Adjusted camera position in viewport coords.
	var dst_viewport := pivot_viewport - delta_viewport

	_target_zoom = z_dst
	_target_position = dst_viewport

func _clamp_camera_position(raw_pos: Vector2) -> Vector2:
	var canvas_rect: Rect2 = (%TextureRect_Clip as TextureRect).get_rect()
	var margin: Vector2 = get_subviewport().size / _camera.zoom.x / 2.0
	return Vector2(clampf(raw_pos.x, canvas_rect.position.x + margin.x, canvas_rect.end.x - margin.x),
				   clampf(raw_pos.y, canvas_rect.position.y + margin.y, canvas_rect.end.y - margin.y))

func _screen_offset_from_center(screen_pos: Vector2) -> Vector2:
	return screen_pos - (size * 0.5)  # PanelContainer.size == visible rect
