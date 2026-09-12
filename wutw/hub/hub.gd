class_name Hub
extends Node2D

signal run_requested(run_config: RunConfig)
signal zoom_changed
signal controls_changed
signal menu_opened(menu: Node)

static var CRAFTING_SCENE := AsyncLoadedResource.new('res://hub/crafting/crafting.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var SKILL_MANAGEMENT_SCENE := AsyncLoadedResource.new('res://hub/skill_management/skill_management.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var RUN_SETUP_SCENE := AsyncLoadedResource.new('res://hub/run_setup/run_setup.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var MUSEUM_BROWSER_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_browser.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var NAME_SCROLL_DISPLAY_SCENE := AsyncLoadedResource.new('res://hub/name_scroll_display.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var MUSEUM_EXHIBIT_SELECTOR_SCENE := AsyncLoadedResource.new('res://hub/museum/museum_exhibit_selector.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var SHARD_EXPLORER_SCENE := AsyncLoadedResource.new('res://hub/shard_explorer/shard_explorer.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var TRIP_MENU_SCENE := AsyncLoadedResource.new('res://hub/trip/trip_menu.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var SETTLER_QUEST_LIST_SCENE := AsyncLoadedResource.new('res://hub/settler_quest_list.tscn', true, AsyncLoadedResource.LoadPhase.UNLIKELY)
static var SPEECH_ARGUMENT_MENU_SCENE := AsyncLoadedResource.new('res://debate/speech_argument_menu.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var SETTLER_QUEST_OFFER_SCENE := AsyncLoadedResource.new('res://quests/settler/settler_quest_offer.tscn', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var EVENT_SCENE := AsyncLoadedResource.new('res://events/system/scenes/event_scene.tscn', false, AsyncLoadedResource.LoadPhase.LIKELY)
static var TOP_HUD_SCENE := AsyncLoadedResource.new('res://hub/hub_top_hud.tscn')
static var BLANKS_PRACTICE_SCENE := AsyncLoadedResource.new('res://japanese/practice_blanks/blanks_practice.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

const ZOOM_SPEED := 0.3
const DEFAULT_FOCUS_DURATION := 1.0
const DEFAULT_FOCUS_ZOOM := 4.0
const CANVAS_RECT := Rect2(0, 0, 1920, 1080)

@export_group('Camera Settings')
@export var view_controls_enabled: bool = true:
	set(value):
		view_controls_enabled = value
		controls_changed.emit()
@export var pan_speed: float = 600.0
@export var zoom_step: float = 0.3
@export var zoom_step_keyboard: float = 4.5
@export var min_zoom: float = 1.0
@export var max_zoom: float = 3.0

var _target_zoom: float = 1.05
var _target_position: Vector2
var _focus_tween: Tween
var _dragging: bool = false
var _drag_start_cursor: Vector2
var _drag_start_camera: Vector2
var _event_scene: EventScene
var _top_hud: HubTopHud
var _camera: Camera2D
var _opened_menus: Array[Node]
var _claimed_settler_quests: Dictionary[Quest_Settler, bool]  # Set

func _ready() -> void:
	_camera = %Camera
	_target_zoom = _camera.zoom.x
	_target_position = _camera.position
	_switch_to_hub_music()
	_start_initial_event_if_available()

	GlobalUI.pause_menu_opened.connect(disable_interaction)
	GlobalUI.pause_menu_closed.connect(enable_interaction)

	# Clear settler quests if they were started.
	for quest_instance in GlobalSaveGame.get_all_quest_instances():
		if quest_instance.get_quest() is Quest_Settler:
			if quest_instance.get_state() >= Quest_Settler.STATE_MODIFIERS_APPLIED:
				GlobalSaveGame.remove_quest_instance(quest_instance)

	GlobalSaveGame.save_game()

	# IMPORTANT: After the game is saved, so characters are deterministic.
	if not Utils.is_running_in_single_scene_mode():
		(%HubContent as HubContents).setup()

	GlobalTutorialSystem.hub_started()

func _enter_tree() -> void:
	GlobalAudioSystem.hub = self
	Utils.set_active_hub(self)
	_top_hud = TOP_HUD_SCENE.instantiate_loaded_scene() as HubTopHud
	GlobalUI.add_layer_content(_top_hud, UI.Layer.HUD_TOP)

func _exit_tree() -> void:
	GlobalAudioSystem.hub = null
	GlobalTutorialSystem.hub_ended()
	_top_hud.queue_free()
	_top_hud = null
	Utils.set_active_hub(null)

func _process(delta: float) -> void:
	if not is_equal_approx(_camera.zoom.x, _target_zoom):
		_camera.zoom = Vector2.ONE * lerp(_camera.zoom.x, _target_zoom, ZOOM_SPEED)
		zoom_changed.emit()
	_camera.position = _clamp_camera_position(lerp(_camera.position, _target_position, ZOOM_SPEED) as Vector2)

	if view_controls_enabled and not GlobalUI.is_higher_level_active(self):
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

func claim_settler_quest(quest: Quest_Settler) -> void:
	assert(quest not in _claimed_settler_quests)
	_claimed_settler_quests[quest] = true

func is_settler_quest_claimed(quest: Quest_Settler) -> bool:
	return quest in _claimed_settler_quests

func spawn_character(character: HubCharacter) -> bool:
	return (%HubContent as HubContents).spawn_character(character)

func get_spawned_characters() -> Array[HubCharacter]:
	return (%HubContent as HubContents).get_spawned_characters()

func hold_debate_speech(argument: DebateArgument) -> void:
	await GlobalUI.show_dialogue(argument.dialogue)
	GlobalSaveGame.use_argument(argument)
	GlobalSaveGame.save_game()

func play_dialogue(dialogue: Dialogue) -> void:
	for i in range(_opened_menus.size() - 1, -1, -1):
		# This is why we need interfaces.
		if Utils.ensure(_opened_menus[i].has_method('_close')):
			@warning_ignore('unsafe_method_access')
			_opened_menus[i]._close()
	await (%HubContent as HubContents).get_dialogue_player().play_dialogue(dialogue)

func get_top_hud() -> HubTopHud:
	return _top_hud

func get_ambient_sounds() -> Array[HubAmbientSound]:
	return (%HubContent as HubContents).get_ambient_sounds()

func _switch_to_hub_music() -> void:
	var mq_state := GlobalSaveGame.get_main_quest_progress()
	if mq_state < SaveGame.MainQuestProgress.P200_STARTED_MAGIC:
		if GameSettings.Audio.skip_claimed_music.value():
			GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_1_STREAMER)
		else:
			GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_1)
	elif mq_state < SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP:
		GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_2)
	elif mq_state < SaveGame.MainQuestProgress.P400_STARTED_DEPRESSION:
		GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_3)
	elif mq_state < SaveGame.MainQuestProgress.P500_STARTED:
		GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_4)
	else:
		if GameSettings.Audio.skip_claimed_music.value():
			GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_ALL_STREAMER)
		else:
			GlobalAudioSystem.switch_music(AK.SWITCHES.MUSIC.SWITCH.HUB_ALL)

## UI window handlers

func _on_hub_content_main_gate_clicked() -> void:
	disable_interaction()
	if not Skill.get_skill_var(Skill.Var.SIGNATURE_CARDS):
		# No customization yet.
		var confirm := GlobalUI.show_confirm(
			tr('Start Expedition'),
			tr('Are you ready to start a new expedition?'),
			tr('Embark'),
			tr('Cancel'))
		confirm.canceled.connect(enable_interaction)
		await confirm.confirmed
		var run_config := RunConfig.new()
		if Utils.is_convergence_unlocked():
			run_config.run_type = load('res://run/types/run_type_standard.tres')
		else:
			run_config.run_type = load('res://run/types/run_type_tutorial.tres') as RunType
		run_config.run_seed = randi_range(1, 10000)
		run_config.starting_cards = SaveGame.get_starter_cards()
		_start_run(run_config)
	else:
		var run_setup := RUN_SETUP_SCENE.instantiate_loaded_scene() as RunSetup
		_open_menu(run_setup)
		run_setup.run_requested.connect(_start_run)
		await run_setup.closed
		_menu_closed()

func _start_run(run_config: RunConfig) -> void:
	const TARGET_LOCATION := Vector2i(488, 193)
	const TARGET_ZOOM := 2.8
	await focus_location(TARGET_LOCATION, TARGET_ZOOM, 1.0)
	GlobalSaveGame.get_hub_random().rand_float()  # Advance manually.
	run_requested.emit(run_config)

func _on_hub_content_shrine_clicked() -> void:
	var skill_management := SKILL_MANAGEMENT_SCENE.instantiate_loaded_scene() as SkillManagement
	_open_menu(skill_management)
	await skill_management.closed
	_menu_closed()

func _on_hub_content_studio_clicked() -> void:
	var crafting := CRAFTING_SCENE.instantiate_loaded_scene() as Crafting
	_open_menu(crafting)
	await crafting.closed
	_menu_closed()

func _on_hub_content_museum_clicked() -> void:
	var museum_browser := MUSEUM_BROWSER_SCENE.instantiate_loaded_scene() as MuseumBrowser
	_open_menu(museum_browser)
	await museum_browser.closed
	_menu_closed()

func _on_hub_content_scroll_clicked() -> void:
	if GameSettings.Japanese.practice_enabled.value():
		var blanks_practice := BLANKS_PRACTICE_SCENE.instantiate_loaded_scene() as BlanksPractice
		_open_menu(blanks_practice)
		await blanks_practice.closed
	else:
		var name_scroll_display := NAME_SCROLL_DISPLAY_SCENE.instantiate_loaded_scene() as NameScrollDisplay
		_open_menu(name_scroll_display)
		await name_scroll_display.closed
	_menu_closed()

func open_museum(resource: Resource, layer: UI.Layer = UI.Layer.GAME_MENU) -> void:
	var museum_browser := MUSEUM_BROWSER_SCENE.instantiate_loaded_scene() as MuseumBrowser
	museum_browser._initial_resource_to_open = resource
	_open_menu(museum_browser, layer)
	await museum_browser.closed
	_menu_closed()

func _on_hub_content_museum_exhibit_clicked(index: int, exhibit: MuseumExhibit) -> void:
	var exhibit_selector := MUSEUM_EXHIBIT_SELECTOR_SCENE.instantiate_loaded_scene() as MuseumExhibitSelector
	exhibit_selector.exhibit_index = index
	exhibit_selector.exhibit = exhibit
	_open_menu(exhibit_selector)
	await exhibit_selector.closed
	_menu_closed()

func _on_hub_content_lookout_tower_clicked() -> void:
	open_shard_explorer()

func open_shard_explorer(layer: UI.Layer = UI.Layer.GAME_MENU) -> void:
	var shard_explorer := SHARD_EXPLORER_SCENE.instantiate_loaded_scene() as ShardExplorer
	_open_menu(shard_explorer, layer)
	await shard_explorer.closed
	_menu_closed()

func _on_hub_content_portal_network_clicked() -> void:
	if Utils.is_explorer_trips_unlocked():
		var trip_menu := TRIP_MENU_SCENE.instantiate_loaded_scene() as TripMenu
		_open_menu(trip_menu)
		await trip_menu.closed
		_menu_closed()

func _on_hub_content_notice_board_clicked() -> void:
	var settler_quest_list := SETTLER_QUEST_LIST_SCENE.instantiate_loaded_scene() as SettlerQuestList
	_open_menu(settler_quest_list)
	settler_quest_list.quest_accepted.connect(func(hub_character: HubCharacter) -> void:
		hub_character.mark_quest_accepted()
	)
	await settler_quest_list.closed
	_menu_closed()

func _on_hub_content_companion_clicked(companion: Companion) -> void:
	disable_interaction()
	MuseumBrowser.open_museum_entry(companion, UI.Layer.GAME_MENU)

func _on_hub_content_character_clicked(character: HubCharacter) -> void:
	if character.offered_quest:
		var quest_offer := SETTLER_QUEST_OFFER_SCENE.instantiate_loaded_scene() as SettlerQuestOffer
		quest_offer.hub_character = character
		quest_offer.quest_accepted.connect(character.mark_quest_accepted)
		_open_menu(quest_offer)
		await quest_offer.closed
		_menu_closed()
	else:
		for other_character in get_spawned_characters():
			if other_character != character:
				var bubble := other_character.get_speech_bubble()
				if bubble:
					bubble.hide_tooltip()
		focus_location(
			character.global_position,
			maxf((min_zoom + max_zoom) / 2.0, get_zoom()))
		character.bark()

func _on_debate_status_bar_on_speech_requested() -> void:
	var speech_menu := SPEECH_ARGUMENT_MENU_SCENE.instantiate_loaded_scene() as SpeechArgumentMenu
	speech_menu.speech_confirmed.connect(hold_debate_speech)
	_open_menu(speech_menu)
	await speech_menu.closed
	_menu_closed()

func _open_menu(menu: Node, layer: UI.Layer = UI.Layer.GAME_MENU) -> void:
	disable_interaction()
	GlobalUI.add_layer_content(menu, layer)
	_opened_menus.append(menu)
	menu_opened.emit(menu)

func _menu_closed() -> void:
	_opened_menus.pop_back()
	if not _opened_menus:
		enable_interaction()

func get_opened_menu() -> Node:
	return _opened_menus[-1] if _opened_menus else null

func disable_interaction() -> void:
	view_controls_enabled = false
	(%HubContent as HubContents)._hovering_enabled = false

func enable_interaction() -> void:
	view_controls_enabled = true
	(%HubContent as HubContents)._hovering_enabled = true

## Event stuff

func _start_initial_event_if_available() -> void:
	for event: Event in Event.get_all_events().values():
		if event is Event_Hub:
			if event.is_requirement_satisfied(null):
				_start_event(event)
				return

func _start_event(event: Event) -> void:
	_event_scene = EVENT_SCENE.instantiate_loaded_scene() as EventScene
	_event_scene.event = event
	_event_scene.finished.connect(func() -> void:
		_event_scene.queue_free()
		_event_scene = null
		GlobalSaveGame.save_game()
		# Only one event a time. As of Jun 2026 hub events aren't even used...
	)
	GlobalUI.add_layer_content(_event_scene, UI.Layer.GAME_MENU)

## Zoom/pan stuff - simplified version of map logic.

func get_location_at_screen_position(screen_position: Vector2, zoom: float = -1) -> Vector2:
	zoom = zoom if zoom > 0 else _camera.zoom.x
	return _screen_offset_from_center(screen_position) / zoom + _camera.position

func get_screen_position_at_location(location: Vector2, zoom: float = -1) -> Vector2:
	zoom = zoom if zoom > 0 else _camera.zoom.x
	return (CANVAS_RECT.size * 0.5) + zoom * (location - _camera.position)

func get_zoom() -> float:
	return _camera.zoom.x

func get_camera_location() -> Vector2:
	return _camera.position

func get_current_target_position() -> Vector2:
	return _target_position

func get_subviewport_half_size() -> Vector2i:
	@warning_ignore('integer_division')
	return (%SubViewport as SubViewport).size / 2

func focus_location(location: Vector2i, new_zoom: float, duration: float = DEFAULT_FOCUS_DURATION) -> void:
	if _focus_tween:
		_focus_tween.kill()

	_target_position = _camera.position
	_focus_tween = create_tween()
	_focus_tween.set_ease(Tween.EaseType.EASE_IN_OUT)
	_focus_tween.set_trans(Tween.TRANS_QUAD)
	_focus_tween.tween_property(self, '_target_zoom', new_zoom, duration)
	_focus_tween.parallel().tween_property(self, '_target_position', _clamp_camera_position(location, new_zoom), duration)
	_focus_tween.play()

	while (abs(_camera.zoom.x - new_zoom) > 0.1
	 	   or (_clamp_camera_position(Vector2(location)) - _camera.position).length() > 10):
		await get_tree().process_frame

func is_camera_moving() -> bool:
	if _focus_tween and _focus_tween.is_running():
		return true
	return not (is_equal_approx(_camera.zoom.x, _target_zoom)
				and _target_position.is_equal_approx(_camera.position))

func _tween_zoom_at(mult: float, pivot_screen: Vector2) -> void:
	var z_src := _camera.zoom.x as float
	var z_dst := clampf(z_src * mult, min_zoom, max_zoom)
	if is_equal_approx(z_src, z_dst):
		return

	if _focus_tween:
		_focus_tween.kill()

	# Cursor location before zoom in world coords.
	var pivot_world := get_location_at_screen_position(pivot_screen)
	# Offset of pivot from center at original zoom in screen coords.
	var delta_screen := _screen_offset_from_center(pivot_screen)
	# Offset of pivot from center at new zoom in viewport coords.
	var delta_viewport := delta_screen / z_dst
	# Adjusted camera position in viewport coords.
	var dst_viewport := pivot_world - delta_viewport

	_target_zoom = z_dst
	_target_position = dst_viewport

func _clamp_camera_position(raw_pos: Vector2, zoom_override: float = -1) -> Vector2:
	var zoom := _camera.zoom.x if zoom_override < 0 else zoom_override
	var margin: Vector2 = (%SubViewport as SubViewport).size / zoom / 2.0
	return Vector2(clampf(raw_pos.x, CANVAS_RECT.position.x + margin.x, CANVAS_RECT.end.x - margin.x),
				   clampf(raw_pos.y, CANVAS_RECT.position.y + margin.y, CANVAS_RECT.end.y - margin.y))

func _screen_offset_from_center(screen_pos: Vector2) -> Vector2:
	return screen_pos - (CANVAS_RECT.size * 0.5)
