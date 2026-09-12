@tool
class_name AudioSystem
extends Node

static var BANK := AsyncLoadedResource.new('res://Wwise/resources/SoundBank/{E9E810C1-7603-4795-937B-4E62E1177604}.tres', false, AsyncLoadedResource.LoadPhase.INITIAL)
static var AMBIENCE_VOLUME_CURVE := AsyncLoadedResource.new('res://audio/ambience_volume_curve.tres', false, AsyncLoadedResource.LoadPhase.NORMAL)

var _master_volume: float
var _music_volume: float
var _ambience_volume: float
var _effects_volume: float
var _ui_volume: float
var _voice_volume: float

const DEBUG_DRAW := false

const BIOME_AMBIENTS: Dictionary[MapBiomes.Biome, int] = {  # Ak Event IDs
	MapBiomes.Biome.CLOUDS: AK.EVENTS.AMB_ZONE_CLOUD_LOOP,
	MapBiomes.Biome.SEA: AK.EVENTS.AMB_ZONE_SEASHORE_BASE_LOOP,  # TODO: Replace with an open sea one.
	MapBiomes.Biome.DESERT: AK.EVENTS.AMB_ZONE_DESSERT_LOOP,
	MapBiomes.Biome.WASTELAND: AK.EVENTS.AMB_ZONE_WASTELAND_LOOP,
	MapBiomes.Biome.SWAMP: AK.EVENTS.AMB_ZONE_SWAMP_LOOP,
	MapBiomes.Biome.STEPPE: AK.EVENTS.AMB_ZONE_STEPPE_LOOP,
	MapBiomes.Biome.PLAINS: AK.EVENTS.AMB_ZONE_PLANE_BASE_LOOP,
	MapBiomes.Biome.MOUNTAIN: AK.EVENTS.AMB_ZONE_MOUNTAIN_BASE_LOOP,
	MapBiomes.Biome.BRUSHLAND: AK.EVENTS.AMB_ZONE_SHRUBLAND_LOOP,
	MapBiomes.Biome.FOREST: AK.EVENTS.AMB_ZONE_FOREST_LOOP,
	MapBiomes.Biome.SEASHORE: AK.EVENTS.AMB_ZONE_SEASHORE_BASE_LOOP,
}
const MAP_AMBIENT_RADIUS_INNER := 20
const MAP_AMBIENT_RADIUS_OUTER := 60
const MAP_AMBIENT_SAMPLE_RADIUS := 50
const AMBIENT_UPDATE_INTERVAL := 1.0 / 10.0
const HUB_ATTENUATION_FACTOR := 0.15

const BIOME_DEBUG_COLORS: Dictionary[MapBiomes.Biome, Color] = {
	MapBiomes.Biome.DESERT: Color.YELLOW,
	MapBiomes.Biome.WASTELAND: Color.BROWN,
	MapBiomes.Biome.SWAMP: Color.DARK_GREEN,
	MapBiomes.Biome.STEPPE: Color.ORANGE,
	MapBiomes.Biome.BRUSHLAND: Color.CADET_BLUE,
	MapBiomes.Biome.FOREST: Color.MEDIUM_SEA_GREEN,
	MapBiomes.Biome.CLOUDS: Color.WHITE,
	MapBiomes.Biome.PLAINS: Color.GREEN_YELLOW,
	MapBiomes.Biome.SEA: Color.LIGHT_BLUE,
	MapBiomes.Biome.MOUNTAIN: Color.SADDLE_BROWN,
	MapBiomes.Biome.SEASHORE: Color.BLUE,
}

var map: Map:
	set(value):
		if map == value:
			return
		if map:
			_stop_map_ambient()
		map = value
		if map:
			if not Utils.ensure(hub == null):
				hub = null
			_start_map_ambient()

var hub: Hub:
	set(value):
		if hub == value:
			return
		if hub:
			_stop_hub_ambient()
		hub = value
		if hub:
			if not Utils.ensure(map == null):
				map = null
			_start_hub_ambient()

# State management.
var is_in_stage: bool = false:
	set(value):
		is_in_stage = value
		_update_state()
var is_in_event: bool = false:
	set(value):
		is_in_event = value
		_update_state()
var is_in_dialog: bool = false:
	set(value):
		is_in_dialog = value
		_update_state()
var is_in_deck_menu: bool = false:
	set(value):
		is_in_deck_menu = value
		_update_state()
var is_in_settings_menu: bool = false:
	set(value):
		is_in_settings_menu = value
		_update_state()
var is_in_audio_settings: bool = false:
	set(value):
		is_in_audio_settings = value
		_update_state()

var active_menus: Array[Node]

# Ambient stuff
var _audio_stubbed_out := false
var _listener: AkListener3D
var _ambient_curve: Curve
var _ambient_timer: Timer
var _ambient_playing_ids: Dictionary[Node, int]
# Map
var _biome_emitters: Dictionary[MapBiomes.Biome, Node]
var _ambient_tracker: MapAmbianceTracker
var _sprite_emitters: Dictionary[WwiseEvent, Node]
var _sprite_locations: Dictionary[WwiseEvent, Array]  # Array[Vector2]
var _debug_biome_markers: Array[ColorRect]
var _debug_sprite_markers: Array[ColorRect]
# Hub
var _hub_emitters: Dictionary[WwiseEvent, Node]
var _hub_emitter_areas: Dictionary[WwiseEvent, Array]  # Array[HubAmbientSound]

var _unfocus_fade_tween: Tween

func _ready() -> void:
	if Utils.is_in_editor():
		return
	if not DirAccess.dir_exists_absolute('res://audio/generated_soundbanks'):
		_audio_stubbed_out = true
		set_process(false)
		return

	await GlobalStartup.wait_loaded_initial()

	var bank := AkBank.new()
	bank.bank = BANK.get_loaded()
	bank.load_on = AkUtils.GAMEEVENT_ENTER_TREE
	add_child(bank)
	_listener = AkListener3D.new()
	add_child(_listener)

	set_master_volume(GameSettings.Audio.master_volume.value())
	set_music_volume(GameSettings.Audio.music_volume.value())
	set_ambience_volume(GameSettings.Audio.ambience_volume.value())
	set_effects_volume(GameSettings.Audio.effects_volume.value())
	set_ui_volume(GameSettings.Audio.ui_volume.value())
	set_voice_volume(GameSettings.Audio.voice_volume.value())

	play(AK.EVENTS.PLAY_MUSIC, self)

	var window: Window = get_window()
	window.focus_exited.connect(_on_window_focus_exited)
	window.focus_entered.connect(_on_window_focus_entered)

func _process(_delta: float) -> void:
	if (map or hub) and not _ambient_curve:
		_ambient_curve = AMBIENCE_VOLUME_CURVE.get_loaded()

	if map:
		_listener.position = _transform_at(map.get_camera_location()).origin
		var zoom_factor := _ambient_curve.sample(map.get_zoom())
		Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_AMB, zoom_factor * get_ambience_volume(), null)
	elif hub:
		_listener.position = _transform_at(hub.get_camera_location() * HUB_ATTENUATION_FACTOR).origin
		var zoom_factor := _ambient_curve.sample(remap(hub.get_zoom(), hub.min_zoom, hub.max_zoom, 2.6, 7))
		Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_AMB, zoom_factor * get_ambience_volume(), null)

func _on_window_focus_exited() -> void:
	if _audio_stubbed_out:
		return
	if GameSettings.Audio.mute_unfocused.value():
		AudioServer.set_bus_mute(AudioServer.get_bus_index('Master'), true)
		if _unfocus_fade_tween:
			_unfocus_fade_tween.kill()
		_unfocus_fade_tween = create_tween()
		_unfocus_fade_tween.tween_method(func(value: float) -> void:
			Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_MASTER, _master_volume * value, null)
		, 1.0, 0.0, 0.5)
		_unfocus_fade_tween.play()

func _on_window_focus_entered() -> void:
	if _audio_stubbed_out:
		return
	AudioServer.set_bus_mute(AudioServer.get_bus_index('Master'), false)
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_MASTER, _master_volume, null)
	if GameSettings.Audio.mute_unfocused.value():
		if _unfocus_fade_tween:
			_unfocus_fade_tween.kill()
		_unfocus_fade_tween = create_tween()
		_unfocus_fade_tween.tween_method(func(value: float) -> void:
			Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_MASTER, _master_volume * value, null)
		, 0.0, 1.0, 0.5)
		_unfocus_fade_tween.play()
	else:
		Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_MASTER, _master_volume, null)

func get_master_volume() -> float:
	return _master_volume

func set_master_volume(new_volume: float) -> void:
	_master_volume = clampf(new_volume, 0, 1)
	if _audio_stubbed_out:
		return
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_MASTER, _master_volume, null)
	GameSettings.Audio.master_volume.set_value(_master_volume, true)

func get_music_volume() -> float:
	return _music_volume

func set_music_volume(new_volume: float) -> void:
	_music_volume = clampf(new_volume, 0, 1)
	if _audio_stubbed_out:
		return
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_MUSIC, _music_volume, null)
	GameSettings.Audio.music_volume.set_value(_music_volume, true)

func get_ambience_volume() -> float:
	return _ambience_volume

func set_ambience_volume(new_volume: float) -> void:
	_ambience_volume = clampf(new_volume, 0, 1)
	if _audio_stubbed_out:
		return
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_AMB, _ambience_volume, null)
	GameSettings.Audio.ambience_volume.set_value(_ambience_volume, true)

func get_effects_volume() -> float:
	return _effects_volume

func set_effects_volume(new_volume: float) -> void:
	_effects_volume = clampf(new_volume, 0, 1)
	if _audio_stubbed_out:
		return
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_SFX, _effects_volume, null)
	GameSettings.Audio.effects_volume.set_value(_effects_volume, true)

func get_ui_volume() -> float:
	return _ui_volume

func set_ui_volume(new_volume: float) -> void:
	_ui_volume = clampf(new_volume, 0, 1)
	if _audio_stubbed_out:
		return
	Wwise.set_rtpc_value_id(AK.GAME_PARAMETERS.MENU_SLIDER_UI, _ui_volume, null)
	GameSettings.Audio.ui_volume.set_value(_ui_volume, true)

func get_voice_volume() -> float:
	return _voice_volume

func set_voice_volume(new_volume: float) -> void:
	_voice_volume = clampf(new_volume, 0, 1)
	# If we ever move voice to Wwise, this should be propagated there.
	GameSettings.Audio.voice_volume.set_value(_voice_volume, true)

func switch_music(wwise_switch_id: int) -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return
	set_switch(AK.SWITCHES.MUSIC.GROUP, wwise_switch_id, self)

func play(wwise_id: int, object: Node = null) -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return
	Wwise.post_event_id(wwise_id, object if object else self)

func start_loop(wwise_id: int, object: Node = null) -> int:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return 0
	return Wwise.post_event_id(wwise_id, object if object else self)

func stop_loop(playing_id: int) -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return
	Wwise.stop_event(playing_id, 100, AkUtils.AK_CURVE_LINEAR)

func set_parameter(parameter_id: int, value: float, object: Node = null) -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return
	Wwise.set_rtpc_value_id(parameter_id, value, object)

func set_switch(group_id: int, switch_id: int, object: Node) -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return
	Wwise.set_switch_id(group_id, switch_id, object)

func notify_menu_opened(menu: Node) -> void:
	if menu not in active_menus:
		active_menus.append(menu)
		menu.tree_exited.connect(_update_state)
		_update_state()

func notify_menu_closed(menu: Node) -> void:
	if menu in active_menus:
		active_menus.erase(menu)
		menu.tree_exited.disconnect(_update_state)
		_update_state()

func _update_state() -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return

	var num_menus_active := 0
	for i in range(active_menus.size() - 1, -1, -1):
		if active_menus[i] and active_menus[i].is_inside_tree():
			num_menus_active += 1
		else:
			active_menus.remove_at(i)

	var state_id: int
	if is_in_audio_settings:
		state_id = AK.STATES.GAMESTATE.STATE.NONE
	elif is_in_settings_menu:
		state_id = AK.STATES.GAMESTATE.STATE.GAMESTATE_MENU_SETTING
	elif is_in_deck_menu:
		state_id = AK.STATES.GAMESTATE.STATE.GAMESTATE_DRAWCARD
	elif is_in_event or is_in_dialog:
		state_id = AK.STATES.GAMESTATE.STATE.GAMESTATE_EVENT
	elif num_menus_active > 0:
		state_id = AK.STATES.GAMESTATE.STATE.GAMESTATE_MENU_GENERIC
	elif is_in_stage:
		state_id = AK.STATES.GAMESTATE.STATE.GAMESTATE_FOREY
	else:
		state_id = AK.STATES.GAMESTATE.STATE.NONE
	Wwise.set_state_id(AK.STATES.GAMESTATE.GROUP, state_id)

func _start_map_ambient() -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return

	# Biome ambients.
	for biome in BIOME_AMBIENTS:
		var emitter := Node.new()
		Wwise.register_game_obj(emitter, 'biome_emitter_' + str(biome))
		_set_emitter_positions(emitter, [])
		_ambient_playing_ids[emitter] = Wwise.post_event_id(BIOME_AMBIENTS[biome], emitter)
		_biome_emitters[biome] = emitter

	_ambient_timer = Timer.new()
	_ambient_timer.autostart = true
	_ambient_timer.ignore_time_scale = true
	_ambient_timer.one_shot = false
	_ambient_timer.wait_time = AMBIENT_UPDATE_INTERVAL
	_ambient_timer.timeout.connect(_tick_map_ambient)
	add_child(_ambient_timer)

	_ambient_tracker = MapAmbianceTracker.new()
	_ambient_tracker.initialize(map.generated_map.biome_bitmap, map.generated_map.size)

	# Sprite ambients.
	for sprite in map.generated_map.sprites:
		_add_sprite_emitter(sprite, true)
	for sound in _sprite_emitters:
		_set_emitter_positions(_sprite_emitters[sound], _sprite_locations[sound])
	map.get_sprite_renderer().placement_added.connect(_add_sprite_emitter)
	map.get_sprite_renderer().placement_removed.connect(_remove_sprite_emitter)

func _stop_map_ambient() -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return

	for playing_id: int in _ambient_playing_ids.values():
		Wwise.stop_event(playing_id, 100, AkUtils.AK_CURVE_LINEAR)
	_ambient_playing_ids.clear()

	# Biome ambients.
	for emitter: Node in _biome_emitters.values():
		Wwise.unregister_game_obj(emitter)
		emitter.queue_free()
	_biome_emitters.clear()

	_ambient_timer.stop()
	_ambient_timer.queue_free()
	_ambient_timer = null

	_ambient_tracker.reset()
	_ambient_tracker = null

	# Sprite ambients.
	for sound in _sprite_emitters:
		var emitter := _sprite_emitters[sound]
		Wwise.unregister_game_obj(emitter)
		emitter.queue_free()
	_sprite_emitters.clear()
	_sprite_locations.clear()
	map.get_sprite_renderer().placement_added.disconnect(_add_sprite_emitter)
	map.get_sprite_renderer().placement_removed.disconnect(_remove_sprite_emitter)

	# Debug.
	if DEBUG_DRAW:
		for marker in _debug_biome_markers + _debug_sprite_markers:
			marker.queue_free()
		_debug_biome_markers.clear()
		_debug_sprite_markers.clear()

func _tick_map_ambient() -> void:
	_ambient_tracker.update(map.get_camera_location())
	for biome in BIOME_AMBIENTS:
		var locations: Array[Vector2]
		for sample in _ambient_tracker.get_biome_samples(biome):
			locations.append(Vector2(sample))
		_set_emitter_positions(_biome_emitters[biome], locations)

	if DEBUG_DRAW:
		for marker in _debug_biome_markers:
			marker.queue_free()
		_debug_biome_markers.clear()
		for biome in BIOME_AMBIENTS:
			for sample in _ambient_tracker.get_biome_samples(biome):
				_debug_biome_markers.append(
					_place_debug_marker(Vector2(sample), BIOME_DEBUG_COLORS[biome]))

func _start_hub_ambient() -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return

	for ambient in hub.get_ambient_sounds():
		_add_hub_ambient_emitter(ambient)

	_ambient_timer = Timer.new()
	_ambient_timer.autostart = true
	_ambient_timer.ignore_time_scale = true
	_ambient_timer.one_shot = false
	_ambient_timer.wait_time = AMBIENT_UPDATE_INTERVAL
	_ambient_timer.timeout.connect(_tick_hub_ambient)
	add_child(_ambient_timer)

func _stop_hub_ambient() -> void:
	if Utils.is_in_editor() or _audio_stubbed_out:
		return

	for playing_id: int in _ambient_playing_ids.values():
		Wwise.stop_event(playing_id, 100, AkUtils.AK_CURVE_LINEAR)
	_ambient_playing_ids.clear()

	for sound in _hub_emitters:
		var emitter := _hub_emitters[sound]
		Wwise.unregister_game_obj(emitter)
		emitter.queue_free()
	_hub_emitters.clear()
	_hub_emitter_areas.clear()

	_ambient_timer.stop()
	_ambient_timer.queue_free()
	_ambient_timer = null

func _tick_hub_ambient() -> void:
	var listener_location := hub.get_camera_location()
	for sound in _hub_emitter_areas:
		var locations: Array[Vector2]
		for area: HubAmbientSound in _hub_emitter_areas[sound]:
			var distance := listener_location.distance_to(area.position)
			if distance <= area.radius:
				locations.append(listener_location * HUB_ATTENUATION_FACTOR)
			else:
				var dx := (listener_location.x - area.position.x)
				var dy := (listener_location.y - area.position.y)
				locations.append(Vector2(
					area.position.x + (dx / distance) * area.radius,
					area.position.y + (dy / distance) * area.radius
				) * HUB_ATTENUATION_FACTOR)
		_set_emitter_positions(_hub_emitters[sound], locations)

func _set_emitter_positions(emitter: Node, locations: Array[Vector2]) -> void:
	if not locations:
		locations = [Vector2(-1000, -1000)]
	var positions: Array[Transform3D]
	for location in locations:
		positions.append(_transform_at(location))
	Wwise.set_multiple_positions_3d(emitter, positions, positions.size(), AkUtils.TYPE_MULTI_DIRECTIONS)

func _add_sprite_emitter(sprite: MapSpritePlacement, skip_position_update: bool = false) -> void:
	var sound := sprite.sprite_type.sound as WwiseEvent
	if not sound:
		return
	if sound not in _sprite_emitters:
		var emitter := Node.new()
		Wwise.register_game_obj(emitter, 'sprite_emitter_' + str(sprite.get_instance_id()))
		_ambient_playing_ids[emitter] = sound.post(emitter)
		_sprite_emitters[sound] = emitter
		_sprite_locations[sound] = [] as Array[Vector2]
	_sprite_locations[sound].append(sprite.location)
	if not skip_position_update:
		_set_emitter_positions(_sprite_emitters[sound], _sprite_locations[sound])
	if DEBUG_DRAW:
		_debug_sprite_markers.append(
			_place_debug_marker(sprite.location, Color.DARK_RED))

func _add_hub_ambient_emitter(hub_ambient: HubAmbientSound) -> void:
	assert(hub_ambient.sound)
	if hub_ambient.sound not in _hub_emitters:
		var emitter := Node.new()
		Wwise.register_game_obj(emitter, 'sprite_emitter_' + str(hub_ambient.get_instance_id()))
		_ambient_playing_ids[emitter] = hub_ambient.sound.post(emitter)
		_hub_emitters[hub_ambient.sound] = emitter
		_hub_emitter_areas[hub_ambient.sound] = [] as Array[HubAmbientSound]
	_hub_emitter_areas[hub_ambient.sound].append(hub_ambient)

func _remove_sprite_emitter(sprite: MapSpritePlacement) -> void:
	var sound := sprite.sprite_type.sound as WwiseEvent
	if not sound:
		return
	if sound in _sprite_emitters:
		if _sprite_locations[sound].size() > 1:
			_sprite_locations[sound].erase(sprite.location)
			_set_emitter_positions(_sprite_emitters[sound], _sprite_locations[sound])
		else:
			_sprite_locations.erase(sound)
			Wwise.unregister_game_obj(_sprite_emitters[sound])
			_sprite_emitters[sound].queue_free()
			_sprite_emitters.erase(sound)

func _place_debug_marker(location: Vector2, color: Color) -> ColorRect:
	var marker := ColorRect.new()
	map.add_map_object(marker)
	marker.size.x = 5
	marker.size.y = 5
	marker.modulate = color
	map.set_map_object_location(marker, Vector2(location))
	return marker

func _transform_at(location: Vector2) -> Transform3D:
	var t: Transform3D
	t.origin.x = location.x
	t.origin.y = 0
	t.origin.z = location.y
	return t
