@tool
class_name Map
extends PanelContainer

signal zoom_changed
signal controls_changed
signal clicked(map_location: Vector2)
signal map_object_added(map_object: Node)
signal cloud_generation_finished

const ZOOM_SPEED := 0.3
const DEFAULT_FOCUS_DURATION := 1.0
const DEFAULT_FOCUS_ZOOM := 5.0
const REVEAL_DURATION := 0.2
const FOW_TWEEN_DURATION := 1.8
const MIN_ZOOM_DELTA_FOR_SFX := 3.0
const RIGHT_SETTLEMENT_LIST_RECT := Rect2(1525, 340, 375, 400)  # HACK

static var _biome_to_spot_type_cache: Dictionary[MapBiomes.Biome, SpotType]

@export var generation_config: MapGenerationConfig
@export var fow_margin: int = 50
@export var initial_fow_reveal_radius: int = 30
@export var generated_map: GeneratedMap
@export var fow_image: Image

@export_group('Camera Settings')
@export var view_controls_enabled: bool = true:
	set(value):
		view_controls_enabled = value
		controls_changed.emit()
		if is_node_ready():
			(%MouseBlocker as Control).visible = not view_controls_enabled
			(%SettlementsList as Control).visible = view_controls_enabled
@export var pan_speed: float = 600.0
@export var zoom_step: float = 0.2
@export var zoom_step_keyboard: float = 4.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 10.0
@export var flip_settlement_list: bool = false:
	set(value):
		flip_settlement_list = value
		(%SettlementsListMargin as Control).size_flags_horizontal = (
				Control.SIZE_SHRINK_BEGIN if flip_settlement_list else Control.SIZE_SHRINK_END)

@export_group('Visuals')
@export var edge_cloud_position_randomization: float = 5.0
@export var edge_cloud_scale: float = 1.0
@export var edge_cloud_scale_randomization: float = 0.1

@export_group('In-Editor Generation')
@export var preview_mode: bool = false:
	set(value):
		preview_mode = value
		if is_node_ready():
			(%DEBUG_TextureRect_Grid as Control).visible = preview_mode
			(%TextureRect_FogOfWar as Control).visible = not preview_mode
			(%CloudArea_FogOfWar as Control).visible = not preview_mode
@export var randomize_seed: bool
@export var random_seed: int
@export_tool_button('Regenerate') @warning_ignore('unused_private_class_variable')
var _regenerate_tool := _manual_regenerate

var modification_mutex := AsyncMutex.new()

var _target_zoom: float = 2.0
var _target_position: Vector2
var _focus_tween: Tween
var _dragging: bool = false
var _drag_start_cursor: Vector2
var _drag_start_camera: Vector2
var _camera: Camera2D
var _generation_in_progress: bool = false

static func get_biome_name(biome: MapBiomes.Biome) -> String:
	match biome:
		MapBiomes.CLOUDS: return Utils.TRANSLATION_DUMMY.tr('Sky')
		MapBiomes.SEA: return Utils.TRANSLATION_DUMMY.tr('Sea')
		MapBiomes.DESERT: return Utils.TRANSLATION_DUMMY.tr('Desert')
		MapBiomes.WASTELAND: return Utils.TRANSLATION_DUMMY.tr('Wasteland')
		MapBiomes.SWAMP: return Utils.TRANSLATION_DUMMY.tr('Swamp')
		MapBiomes.STEPPE: return Utils.TRANSLATION_DUMMY.tr('Steppe')
		MapBiomes.PLAINS: return Utils.TRANSLATION_DUMMY.tr('Plains')
		MapBiomes.MOUNTAIN: return Utils.TRANSLATION_DUMMY.tr('Mountains')
		MapBiomes.BRUSHLAND: return Utils.TRANSLATION_DUMMY.tr('Scrubland')
		MapBiomes.FOREST: return Utils.TRANSLATION_DUMMY.tr('Forest')
		MapBiomes.SEASHORE: return Utils.TRANSLATION_DUMMY.tr('Seashore')
		_: Utils.ensure(false); return Utils.TRANSLATION_DUMMY.tr('INVALID')

func _ready() -> void:
	if Utils.is_in_editor():
		return
	_camera = %Camera as Camera2D
	_target_zoom = _camera.zoom.x
	_target_position = _camera.position
	(%SettlementsList as Control).visible = view_controls_enabled and Utils.get_active_run()
	(%MouseBlocker as Control).visible = not view_controls_enabled
	if generated_map:
		set_generated_map(generated_map)

	GlobalUI.ui_hide_toggled.connect(func() -> void:
		(%SettlementsList as Control).modulate.a = 0 if GlobalUI.is_ui_hidden() else 1
	)

func _process(delta: float) -> void:
	if Utils.is_in_editor():
		return

	if not is_equal_approx(_camera.zoom.x, _target_zoom):
		_camera.zoom = Vector2.ONE * lerp(_camera.zoom.x, _target_zoom, ZOOM_SPEED)
		zoom_changed.emit()
	_camera.position = _clamp_camera_position(lerp(_camera.position, _target_position, ZOOM_SPEED) as Vector2)

	if view_controls_enabled:
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
			if _focus_tween:
				_focus_tween.kill()
			_target_position = _clamp_camera_position(_target_position + dir * pan_speed * delta)

		if Input.is_action_just_pressed('mouse_left_click'):
			_handle_click(get_global_mouse_position())

		# Drag controls.
		if Input.is_action_just_pressed('mouse_pan'):
			if _focus_tween:
				_focus_tween.kill()
			_dragging = true
			_drag_start_cursor = get_local_mouse_position()
			_drag_start_camera = _camera.position
		elif Input.is_action_just_released('mouse_pan'):
			_dragging = false
		elif Input.is_action_pressed('mouse_pan') and _dragging:
			var offset := (get_local_mouse_position() as Vector2 - _drag_start_cursor) / (_camera.zoom.x as float)
			_target_position = _clamp_camera_position(_drag_start_camera - offset)

	if _should_dynamically_flip_settlements():
		flip_settlement_list = RIGHT_SETTLEMENT_LIST_RECT.has_point(get_global_mouse_position())
	else:
		flip_settlement_list = false

func _on_gui_input(event: InputEvent) -> void:
	if GlobalUI.is_higher_level_active(self):
		return
	if view_controls_enabled:
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
	var map_nodes: Array[Control] = [
		%TextureRect_ShardBase,
		%TextureRect_Clip,
		%TextureRect_FogOfWar,
		%CloudArea_FogOfWar,
		%CloudSea,
		%EdgeClouds,
		%TextureRect_Border,
	]
	for map_node in map_nodes:
		map_node.modulate.a = 0
	Utils.clear_node(%EdgeClouds)

	generated_map = null
	var thread := Thread.new()
	thread.start(_generate_threaded.bind(%MapGenerator, rng))
	while _generation_in_progress:
		await get_tree().process_frame
	thread.wait_to_finish()

	for map_node in map_nodes:
		create_tween().tween_property(map_node, 'modulate:a', 1.0, REVEAL_DURATION)

func _generate_threaded(generator: MapGenerator, rng: RandomState) -> void:
	var new_generated_map: GeneratedMap = generator.generate(generation_config, rng.rand_int(0, 10000), rng.is_legacy())
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
	(%DEBUG_TextureRect_DistanceToLand as TextureRect).texture = generated_map.distance_to_land_texture
	(%DEBUG_TextureRect_Depth as TextureRect).texture = generated_map.land_depth_texture

	(%MapSpriteRenderer as MapSpriteRenderer).placements = generated_map.sprites
	((%MapSpriteRenderer as MapSpriteRenderer).material as ShaderMaterial).set_shader_parameter(
		'river_sink_sdf', generated_map.nonland_sdf)

	((%CloudSea as ColorRect).material as ShaderMaterial).set_shader_parameter(
		'landmass_sdf', generated_map.distance_to_land_texture)
	((%CloudSea as ColorRect).material as ShaderMaterial).set_shader_parameter(
		'shard_tex', generated_map.shard_base_texture)

	(%CompassIcon as Control).rotation = RandomState.new(random_seed).rand_float(0, TAU)

	await get_tree().process_frame  # Distribute load between frames.
	if not generated_map:  # Still valid?
		return

	# Generate FOW mask.
	var clouds_image := generated_map.blurred_biome_sdfs[MapBiomes.CLOUDS].get_image()
	fow_image = Image.create_empty(get_map_size().x, get_map_size().y, false, Image.Format.FORMAT_RG8)
	for y in get_map_size().y:
		for x in get_map_size().x:
			var cloud_dist := clouds_image.get_pixel(x, y).r8
			fow_image.set_pixel(x, y, Color.from_rgba8(255, cloud_dist, 0, 0))
	(%TextureRect_FogOfWar as TextureRect).texture = ImageTexture.create_from_image(fow_image)
	await get_tree().process_frame  # Distribute load between frames.
	if not generated_map:  # Still valid?
		return

	reveal_fow(generated_map.starting_point, initial_fow_reveal_radius)
	await get_tree().process_frame  # Distribute load between frames.
	if not generated_map:  # Still valid?
		return

	_generation_in_progress = false  # The rest should happen async

	# DEBUG: Generate debug grid.
	if Utils.is_dev():
		var debug_grid_image := Image.create_empty(get_map_size().x, get_map_size().y, false, Image.Format.FORMAT_R8)
		for y in get_map_size().y:
			for x in get_map_size().x:
				var biome := generated_map.biome_bitmap[y * get_map_size().x + x]
				debug_grid_image.set_pixel(x, y, Color.from_rgba8(biome, 0, 0, 0))
		(%DEBUG_TextureRect_Grid as TextureRect).texture = ImageTexture.create_from_image(debug_grid_image)

	_regenerate_edge_clouds()
	await get_tree().process_frame  # Distribute load between frames.
	if not generated_map:  # Still valid?
		return

	if Utils.ensure(%CloudArea_FogOfWar.get_child_count()):
		if Utils.is_compatibility_renderer() or not GameSettings.Display.clouds_on_map.value():
			# Not supported in compatibility renderer due to instance uniforms.
			Utils.clear_node(%CloudArea_FogOfWar)
		else:
			((%CloudArea_FogOfWar.get_child(0) as FowCloud).material as ShaderMaterial).set_shader_parameter(
				'fow_texture', (%TextureRect_FogOfWar as TextureRect).texture)

	(%MapEffectsSystem as MapEffectsSystem).regenerate()
	await get_tree().process_frame  # Distribute load between frames.
	if not generated_map:  # Still valid?
		return

	await (%CloudArea_CloudSea as CloudArea).update(false, 50)
	cloud_generation_finished.emit()

func get_sprite_renderer() -> MapSpriteRenderer:
	return %MapSpriteRenderer as MapSpriteRenderer

func get_placement_sprite_renderer() -> MapSpriteRenderer:
	return %MapSpriteRenderer_Placement as MapSpriteRenderer

func get_road_manager() -> MapRoadManager:
	return %MapRoadManager as MapRoadManager

func reveal_fow_tween(center: Vector2i, radius: int) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EaseType.EASE_OUT)
	tween.tween_method(func(r: int) -> void: reveal_fow(center, r), 1, radius, FOW_TWEEN_DURATION)
	tween.set_speed_scale(Utils.anim_speed())
	tween.play()
	await tween.finished

func reveal_fow(center: Vector2i, radius: int) -> void:
	for dy in range(-radius - fow_margin, radius + fow_margin + 1):
		for dx in range(-radius - fow_margin, radius + fow_margin + 1):
			var x := center.x + dx
			var y := center.y + dy
			if x < 0 or x >= generation_config.size.x or y < 0 or y >= generation_config.size.y:
				continue
			var sample := fow_image.get_pixel(x, y)
			var current_fow := remap(sample.r, 0, 1, -1, 1)
			if current_fow <= -0.999:
				continue

			var dist := sqrt(dx * dx + dy * dy) - radius
			var new_fow := clampf(remap(dist, -fow_margin, fow_margin, -1, 1), -1, 1)
			if new_fow >= current_fow:
				continue

			var new_fow_quantized := roundi(remap(new_fow, -1, 1, 0, 255))
			fow_image.set_pixel(x, y, Color.from_rgba8(new_fow_quantized, sample.g8, 0, 0))

	((%TextureRect_FogOfWar as TextureRect).texture as ImageTexture).set_image(fow_image)
	var run := Utils.get_active_run()
	if run:  # Could be null in trailer/screenshot scenes.
		run.record_fow_reveal(center, radius)

func reset_all_fow() -> void:
	for y in fow_image.get_height():
		for x in fow_image.get_width():
			var sample := fow_image.get_pixel(x, y)
			fow_image.set_pixel(x, y, Color.from_rgba8(255, sample.g8, 0, 0))
	((%TextureRect_FogOfWar as TextureRect).texture as ImageTexture).set_image(fow_image)

func clear_all_fow() -> void:
	for y in fow_image.get_height():
		for x in fow_image.get_width():
			var sample := fow_image.get_pixel(x, y)
			fow_image.set_pixel(x, y, Color.from_rgba8(0, sample.g8, 0, 0))
	((%TextureRect_FogOfWar as TextureRect).texture as ImageTexture).set_image(fow_image)
	var run := Utils.get_active_run()
	run.record_fow_reveal(Vector2i(-1, -1), -1)

func is_in_fow(map_location: Vector2i) -> bool:
	if (map_location.x < 0 or map_location.y < 0
			or map_location.x >= get_map_size().x or map_location.y >= get_map_size().y):
		return 1.0
	return fow_image.get_pixel(map_location.x, map_location.y).r > 0.5

func get_fow_texture() -> Texture2D:
	return (%TextureRect_FogOfWar as TextureRect).texture

func get_fow_layer() -> Control:
	return %TextureRect_FogOfWar as TextureRect

func get_cloud_density(map_location: Vector2) -> float:
	if (map_location.x < 0 or map_location.y < 0
			or map_location.x >= get_map_size().x - 1 or map_location.y >= get_map_size().y - 1):
		return 1.0
	var sample := fow_image.get_pixel(floori(map_location.x), floori(map_location.y))
	var fow_distance := sample.r8
	var cloud_distance := 255 - sample.g8
	var min_dist := minf(fow_distance, 280 - cloud_distance)
	return clampf(remap(min_dist, 127 + 10, 127 + fow_margin, 0, 1), 0, 1)

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

func get_biome_at_position(map_location: Vector2) -> MapBiomes.Biome:
	var discrete_location := Vector2i(map_location)
	if (discrete_location.x < 0 or discrete_location.y < 0
			or discrete_location.x >= get_map_size().x or discrete_location.y >= get_map_size().y):
		return MapBiomes.CLOUDS
	return generated_map.biome_bitmap[discrete_location.y * get_map_size().x + discrete_location.x] as MapBiomes.Biome

func get_biomes_in_radius(map_location: Vector2, radius: float) -> Array[MapBiomes.Biome]:
	var result: Dictionary[MapBiomes.Biome, bool]
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var sample_location := map_location + Vector2(x, y)
			var distance := map_location.distance_to(sample_location)
			if distance <= radius:
				var biome := get_biome_at_position(map_location + Vector2(x, y))
				result[biome] = true
	return result.keys()

func get_biome_counts_in_radius(map_location: Vector2, radius: float) -> Dictionary[MapBiomes.Biome, int]:
	var result: Dictionary[MapBiomes.Biome, int]
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var sample_location := map_location + Vector2(x, y)
			var distance := map_location.distance_to(sample_location)
			if distance <= radius:
				var biome := get_biome_at_position(map_location + Vector2(x, y))
				result[biome] = result.get(biome, 0) + 1
	return result

func get_spot_types_at_position(map_location: Vector2, radius: float, num_spots: int) -> Array[SpotType]:
	# Make sure the center tile is valid.
	var center_biome := get_biome_at_position(map_location)
	if not is_biome_valid_settlement_spot(center_biome):
		return []

	var PRIORITIZED_SPOTS := [
		load('res://stage/spots/square/spot_square.tres') as SpotType,
		load('res://stage/spots/building_small/spot_building_small.tres') as SpotType,
		load('res://stage/spots/building_large/spot_building_large.tres') as SpotType,
		# Too large and tend to dominate.
		#load('res://stage/spots/cliff/spot_cliff.tres') as SpotType,
		#load('res://stage/spots/canyon/spot_canyon.tres') as SpotType,
	]

	# Collect spot counts and minimum distances to center, taking both sprites and biomes.
	# Biomes with the same spot type (e.g. sea & seashore) are merged.
	var biome_areas: Dictionary[SpotType, int]
	var biome_distances: Dictionary[SpotType, float]
	var prioritized_sprites: Array[MapSpritePlacement]
	var biome_location_sums: Dictionary[SpotType, Vector2]
	var biome_location_counts: Dictionary[SpotType, int]

	for placement: MapSpritePlacement in generated_map.sprites_quad_tree.query_circle(map_location, radius, false):
		var spot_type := placement.sprite_type.provided_spot_type as SpotType
		if spot_type and not placement.used_by:
			if spot_type in PRIORITIZED_SPOTS:
				prioritized_sprites.append(placement)
			else:
				var distance := map_location.distance_to(placement.location)
				distance -= placement.sprite_type.footprint_radius  # HACK: Not accuate, but close enough.
				distance -= radius  # Sprite-provided spots are always prioritized as they are rarer.
				biome_areas[spot_type] = biome_areas.get(spot_type, 0) + PI * pow(placement.sprite_type.footprint_radius, 2)
				biome_distances[spot_type] = min(biome_distances.get(spot_type, radius), distance)
			biome_location_sums[spot_type] = biome_location_sums.get(spot_type, Vector2.ZERO) + placement.location
			biome_location_counts[spot_type] = biome_location_counts.get(spot_type, 0) + 1
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var sample_location := map_location + Vector2(x, y)
			var distance := map_location.distance_to(sample_location)
			if distance <= radius:
				var biome := get_biome_at_position(map_location + Vector2(x, y))
				var spot_type := biome_to_spot_type(biome)
				if spot_type:
					if biome == MapBiomes.SEA:
						distance /= 2.0  # Prioritize seashore, since we always have to be outsie it.
					biome_areas[spot_type] = biome_areas.get(spot_type, 0) + 1
					biome_distances[spot_type] = min(biome_distances.get(spot_type, radius), distance)
					biome_location_sums[spot_type] = biome_location_sums.get(spot_type, Vector2.ZERO) + sample_location
					biome_location_counts[spot_type] = biome_location_counts.get(spot_type, 0) + 1

	# Sort by the biomes by distance to center.
	var sorted_biomes: Array[SpotType]
	sorted_biomes.assign(biome_distances.keys())
	sorted_biomes.sort_custom(func(a: SpotType, b: SpotType) -> bool:
		var dist_a := biome_distances[a]
		var dist_b := biome_distances[b]
		if dist_a == dist_b:  # Ensure stability!
			return a.spot_type_id < b.spot_type_id
		else:
			return dist_a < dist_b)

	# Prioritize the center biome.
	var center_spot_type := biome_to_spot_type(center_biome)
	if center_spot_type:
		sorted_biomes.erase(center_spot_type)
		sorted_biomes.insert(0, center_spot_type)

	# Special case: if we want just one spot, seashore and directly targeted sprites should win.
	if num_spots == 1:
		# Choose the targeted sprite if any.
		var min_sprite_distance := INF
		var min_sprite_spot_type: SpotType = null
		for placement: MapSpritePlacement in generated_map.sprites_quad_tree.query_circle(map_location, 0.5, false):
			var spot_type := placement.sprite_type.provided_spot_type as SpotType
			if spot_type:
				var distance := map_location.distance_to(placement.location)
				if not min_sprite_spot_type or distance < min_sprite_distance:
					min_sprite_spot_type = spot_type
					min_sprite_distance = distance
		if min_sprite_spot_type:
			return [min_sprite_spot_type]
		# Prioritize seashore.
		if biome_distances.get(biome_to_spot_type(MapBiomes.SEA), 999) <= 5:
			return [biome_to_spot_type(MapBiomes.SEA)]
		# If no sprite, use the regular biome rule.
		for biome in sorted_biomes:
			if biome_distances[biome] + radius <= 0:
				return [sorted_biomes[0]]

	# Pass 0: Take the prioritized sprites.
	var result: Array[SpotType]
	prioritized_sprites.sort_custom(func(a: MapSpritePlacement, b: MapSpritePlacement) -> bool:
		var dist_a := map_location.distance_to(a.location)
		var dist_b := map_location.distance_to(b.location)
		if dist_a == dist_b:  # Ensure stability!
			return a.sprite_type.provided_spot_type.spot_type_id < b.sprite_type.provided_spot_type.spot_type_id
		else:
			return dist_a < dist_b)
	for i in num_spots:
		if prioritized_sprites:
			result.append(prioritized_sprites.pop_front().sprite_type.provided_spot_type)
	if result.size() < num_spots:
		# Pass 1: Take the closest biomes.
		for i: int in min(num_spots - result.size(), sorted_biomes.size()):
			result.append(sorted_biomes[i])

		# Pass 2: If we need more spots, take extra biomes based on area.
		var num_left := num_spots - result.size()
		if num_left > 0:
			var total: float = 0
			for count: float in biome_areas.values():
				total += count

			# Compute real‐valued "ideal" shares and distribute their whole parts.
			var assigned := 0
			var remainders: Array[Array]  # [-rem, spot_type] so that Array.sort() sorts descending.
			for spot_type: SpotType in biome_areas.keys():
				var share := float(num_left) * biome_areas[spot_type] / total
				for _i in floori(share):
					result.append(spot_type)
				assigned += floori(share)
				remainders.append([-fmod(share, 1), spot_type])

			# Distribute leftovers to those with largest fractional parts.
			remainders.sort()
			for i in num_left - assigned:
				var spot_type := remainders[i][1] as SpotType
				result.append(spot_type)

	# Sort based on centerpoint X coordinate on the map, so that the Spot UIs more closely match the map.
	result.sort_custom(func(a: SpotType, b: SpotType) -> bool:
		var x_a := (biome_location_sums[a] / biome_location_counts[a]).x
		var x_b := (biome_location_sums[b] / biome_location_counts[b]).x
		return x_a < x_b
	)

	return result

func biome_to_spot_type(biome: MapBiomes.Biome) -> SpotType:
	if not _biome_to_spot_type_cache:
		_biome_to_spot_type_cache = {
			MapBiomes.SEA: load('res://stage/spots/seashore/spot_seashore.tres'),
			MapBiomes.DESERT: load('res://stage/spots/desert/spot_desert.tres'),
			MapBiomes.WASTELAND: load('res://stage/spots/wasteland/spot_wasteland.tres'),
			MapBiomes.SWAMP: load('res://stage/spots/swamp/spot_swamp.tres'),
			MapBiomes.STEPPE: load('res://stage/spots/steppe/spot_steppe.tres'),
			MapBiomes.PLAINS: load('res://stage/spots/plains/spot_plains.tres'),
			MapBiomes.BRUSHLAND: load('res://stage/spots/brushland/spot_brushland.tres'),
			MapBiomes.FOREST: load('res://stage/spots/forest/spot_forest.tres'),
			MapBiomes.SEASHORE: load('res://stage/spots/seashore/spot_seashore.tres'),
		}
	return _biome_to_spot_type_cache.get(biome)

func is_biome_valid_settlement_spot(biome: MapBiomes.Biome) -> bool:
	match biome:
		MapBiomes.CLOUDS, MapBiomes.SEA: return false
		_: return true

func add_map_object(node: Node) -> void:
	%MapObjects.add_child(node)
	map_object_added.emit(node)

func set_map_object_location(node: Node, map_location: Vector2) -> void:
	@warning_ignore('unsafe_property_access')
	node.position = map_location * get_map_scale()

func get_map_object_location(node: Node) -> Vector2:
	Utils.ensure(node.get_parent() == %MapObjects)
	@warning_ignore('unsafe_property_access')
	return node.position / get_map_scale()

func get_map_objects() -> Array[Node]:
	return %MapObjects.get_children()

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

func get_credits_icon() -> CreditsIcon:
	return %CreditsIcon as CreditsIcon

func get_compass_icon() -> TextureRect:
	return %CompassIcon as TextureRect

func get_current_target_position() -> Vector2:
	return get_location_at_map_viewport_position(_target_position)

func instant_focus_location(map_location: Vector2, new_zoom: float) -> void:
	if _focus_tween:
		_focus_tween.kill()
	_target_zoom = new_zoom
	_camera.zoom.x = _target_zoom
	_camera.zoom.y = _target_zoom
	_target_position = _clamp_camera_position(get_map_viewport_position_at_location(map_location))
	_camera.position = _target_position

func focus_location(map_location: Vector2, new_zoom: float, duration: float = DEFAULT_FOCUS_DURATION) -> void:
	if _focus_tween:
		_focus_tween.kill()

	_target_position = _camera.position
	_focus_tween = create_tween()
	_focus_tween.set_ease(Tween.EaseType.EASE_IN_OUT)
	_focus_tween.tween_property(self, '_target_zoom', new_zoom, duration)
	_focus_tween.parallel().tween_property(self, '_target_position', get_map_viewport_position_at_location(map_location), duration)
	_focus_tween.play()
	if new_zoom - get_zoom() > MIN_ZOOM_DELTA_FOR_SFX:
		GlobalAudioSystem.play(AK.EVENTS.SFX_MAP_CLOUD)

func is_camera_moving() -> bool:
	if _focus_tween and _focus_tween.is_running():
		return true
	return not (is_equal_approx(_camera.zoom.x, _target_zoom)
				and _target_position.is_equal_approx(_camera.position))

func stop_focus_tween() -> void:
	if _focus_tween:
		_focus_tween.kill()

func _manual_regenerate() -> void:
	if randomize_seed:
		random_seed = randi_range(0, 10000)
	var profiler := QuickProfiler.new()
	profiler.begin('Generator')
	var new_generated_map: GeneratedMap = (%MapGenerator as MapGenerator).generate(
				generation_config, RandomState.new(random_seed).rand_int(0, 10000))
	profiler.end('Generator')
	profiler.begin('Update Nodes')
	await set_generated_map(new_generated_map)
	profiler.end('Update Nodes')
	profiler.report('Map Generation')

func _regenerate_edge_clouds() -> void:
	Utils.clear_node(%EdgeClouds)
	if Utils.is_compatibility_renderer() or not GameSettings.Display.clouds_on_map.value():
		# Not supported in compatibility renderer due to instance uniforms.
		return
	var cloud_points: Array[Vector2] = generated_map.edge_cloud_points.duplicate()
	var rng := RandomState.new(random_seed)
	rng.shuffle(cloud_points)  # To randomize z-index.
	for point in cloud_points:
		var cloud := EdgeCloud.new()
		cloud.map_rect = get_map_content_rect()
		cloud.land_sdf = generated_map.distance_to_land_texture
		cloud.land_depth = generated_map.land_depth_texture
		%EdgeClouds.add_child(cloud)
		cloud.set_owner(self)
		var cloud_pos := point * get_map_scale()
		cloud_pos.x += rng.rand_float(-edge_cloud_position_randomization, edge_cloud_position_randomization)
		cloud.position = cloud_pos
		cloud.scale = Vector2(edge_cloud_scale, edge_cloud_scale)
		cloud.scale *= 1.0 + rng.rand_float(-edge_cloud_scale_randomization, 0)

func _tween_zoom_at(mult: float, pivot_screen: Vector2) -> void:
	var z_src := _camera.zoom.x as float
	var z_dst := clampf(z_src * mult, min_zoom, max_zoom)
	if is_equal_approx(z_src, z_dst):
		return

	if _focus_tween:
		_focus_tween.kill()

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

func _handle_click(screen_position: Vector2) -> void:
	clicked.emit(get_location_at_screen_position(screen_position))

func _on_settlements_list_settlement_clicked(settlement: Settlement) -> void:
	focus_location(settlement.state.map_location, maxf(get_zoom(), DEFAULT_FOCUS_ZOOM))

func _on_settlements_list_capital_clicked() -> void:
	var capital := Utils.get_active_run().get_capital()
	if capital:
		focus_location(capital.map_location, maxf(get_zoom(), DEFAULT_FOCUS_ZOOM))

func _on_map_sprite_renderer_placement_added(_placement: MapSpritePlacement) -> void:
	# Adjust it lazily whenever we need to animate. Hacky, but works fine.
	if get_sprite_renderer().animation_duration >= 0:
		if GameSettings.Display.animate_sprite_changes.value():
			get_sprite_renderer().animation_duration = Utils.anim_duration(2.0)
		else:
			get_sprite_renderer().animation_duration = 0

func _on_map_sprite_renderer_placement_removed(placement: MapSpritePlacement) -> void:
	_on_map_sprite_renderer_placement_added(placement)

func _should_dynamically_flip_settlements() -> bool:
	var run := Utils.get_active_run()
	if not run:
		return false
	if GlobalUI.is_dragging():
		return true
	elif run.get_current_scene() is StageSelector:
		var stage_selector := run.get_current_scene() as StageSelector
		return stage_selector.is_selecting()
	else:
		return false
