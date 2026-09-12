class_name HubDialoguePlayer
extends Node2D

const ANIM_DURATION := 1.0
const ZOOM_SPEED_FACTOR := 0.4
const DISTANCE_SPEED_FACTOR := 0.002

@export var character_manager: HubCharacterManager
@export var teo: Character
@export var halo_material: Material

# Lifetime-scope state.
var _hub: Hub
var _spawners: Dictionary[HubCharacterSpec.Socket, HubSpawner_Single]
var _audience_spawner: HubSpawner_Multi
# Dialogue-scope state.
var _playing: bool = false
var _starting_camera_zoom: float
var _starting_camera_position: Vector2
# Scene-scope state.
var _spawned_characters: Dictionary[Character, HubCharacter]
var _mouse_catcher: Button
var _speaking_character: HubCharacter
var _waiting_for_click: bool = false

func _ready() -> void:
	_hub = Utils.get_active_hub()
	for child in get_children():
		if child is HubSpawner_Single:
			_spawners[(child as HubSpawner_Single).socket] = child as HubSpawner_Single
		elif child is HubSpawner_Multi:
			Utils.ensure(not _audience_spawner)
			_audience_spawner = child as HubSpawner_Multi
		else:
			Utils.ensure(false)

func play_dialogue(dialogue: Dialogue) -> void:
	# Set up.
	Utils.ensure(not _playing)
	_playing = true

	# Remember original camera state.
	_starting_camera_zoom = _hub.get_zoom()
	_starting_camera_position = _hub.get_current_target_position()

	# Add mouse catcher to dialogue UI layer.
	_mouse_catcher = Button.new()
	_mouse_catcher.modulate.a = 0
	_mouse_catcher.custom_minimum_size = Vector2(1920, 1080)
	_mouse_catcher.pressed.connect(_on_mouse_catcher_clicked)
	GlobalUI.add_layer_content(_mouse_catcher, UI.Layer.DIALOGUE)
	_mouse_catcher.grab_focus.call_deferred(true)

	# Hide standard characters.
	var fadeout_tween := create_tween()
	fadeout_tween.set_speed_scale(Utils.anim_speed())
	fadeout_tween.tween_property(character_manager, 'modulate:a', 0.0, ANIM_DURATION)
	fadeout_tween.parallel().tween_property(self, 'modulate:a', 1.0, ANIM_DURATION)  # In case prev. dialogue hid it.
	fadeout_tween.play()
	# Don't wait, so the zoom animation in _play_page() plays at the same time.

	# Play all the pages in order.
	for page in dialogue.get_pages():
		await _play_page(page)

	# Restore camera state.
	_move_camera(_starting_camera_position, _starting_camera_zoom)

	# Swap back to standard characters.
	var fadein_tween := create_tween()
	fadein_tween.set_speed_scale(Utils.anim_speed())
	fadein_tween.tween_property(self, 'modulate:a', 0.0, ANIM_DURATION)
	fadein_tween.parallel().tween_property(character_manager, 'modulate:a', 1.0, ANIM_DURATION)
	fadein_tween.play()
	await fadein_tween.finished
	for spawner: HubSpawner_Single in _spawners.values():
		spawner.clear()
	_audience_spawner.clear()

	# Clean up.
	_mouse_catcher.queue_free()
	_mouse_catcher = null
	GlobalSaveGame.mark_dialogue_seen(dialogue)
	_playing = false

func _play_page(page: Dialogue.Page) -> void:
	# Spawn the NPCs involved in this page.
	var fadein_tween := create_tween()
	fadein_tween.set_speed_scale(Utils.anim_speed())
	var any_chracters_fading_in := false
	var sum_location: Vector2 = Vector2i.ZERO
	for character in page.characters:
		var socket := page.character_sockets[character]
		if Utils.ensure(socket in _spawners):
			var spawner := _spawners[socket]
			if (not spawner.get_spawned_characters() or
				spawner.get_spawned_characters()[0].character.get_character() != character):
				var specs := character.hub_specs
				if specs.size() > 1:
					specs = specs.duplicate()
					specs.shuffle()
					for spec in specs:
						if spawner._matches_direction(spec):
							spawner.spawn(spec)
				if spawner.get_spawned_characters().is_empty():
					spawner.spawn(character.hub_specs[0])
				spawner.modulate.a = 0
				fadein_tween.parallel().tween_property(spawner, 'modulate:a', 1.0, ANIM_DURATION)
				any_chracters_fading_in = true
			_spawned_characters[character] = spawner.get_spawned_characters()[0]
			sum_location += spawner.global_position  # Relative to the hub contents subviewport.

	# Here we could support hiding NPCs from previous pages if we ever need it.

	# Special handling for TEO.
	if teo in page.characters:
		_spawned_characters[teo].say('', Tooltip.Alignment.CENTERED, false, false)
		if GlobalSaveGame.get_main_quest_progress() < SaveGame.MainQuestProgress.P300_STARTED_LEADERSHIP:
			var portrait := _spawned_characters[teo].get_speech_bubble().get_node('%Portrait') as TextureRect
			portrait.material = halo_material

	# Spacial case for audience.
	if page.show_audience:
		_audience_spawner.spawn_random()
		for character in _audience_spawner.get_spawned_characters():
			# Not really "accepted", but clears the quest, removing the confusing attention icon.
			character.mark_quest_accepted()
		sum_location += _audience_spawner.global_position
		_audience_spawner.modulate.a = 0
		fadein_tween.parallel().tween_property(_audience_spawner, 'modulate:a', 1.0, ANIM_DURATION)
		any_chracters_fading_in = true

	if any_chracters_fading_in:
		fadein_tween.play()
	else:
		fadein_tween.kill()

	# Move the camera to frame these characters.
	var target_location := Vector2(sum_location / (page.characters.size() + int(page.show_audience)))
	await _move_camera(target_location, _hub.max_zoom)

	await get_tree().create_timer(Utils.anim_duration(ANIM_DURATION * 0.5)).timeout

	var last_character: Character = null
	for line in page.lines:
		if last_character and last_character != line.character:
			_spawned_characters[last_character].get_speech_bubble().hide_tooltip()

		_speaking_character = _spawned_characters[line.character]
		var flipped := false
		if last_character and last_character != line.character:
			flipped = _speaking_character.global_position.x > _spawned_characters[last_character].global_position.x
		elif page.characters.size() > 1:
			var other := page.characters[1 if page.characters[0] == line.character else 0]
			flipped = _speaking_character.global_position.x > _spawned_characters[other].global_position.x
		await _speaking_character.say(line.text, Tooltip.Alignment.CENTERED, flipped, false)

		_waiting_for_click = true
		while _waiting_for_click:
			await get_tree().process_frame

		last_character = line.character
		_speaking_character = null

	_spawned_characters[last_character].get_speech_bubble().hide_tooltip()
	# Special handling for TEO.
	if teo in page.characters:
		_spawned_characters[teo].get_speech_bubble().hide_tooltip()

func _move_camera(location: Vector2, zoom: float) -> void:
	var zoom_factor := absf(zoom - _hub.get_zoom()) * ZOOM_SPEED_FACTOR
	var distance_factor := (location - _hub.get_current_target_position()).length() * DISTANCE_SPEED_FACTOR
	var duration := ANIM_DURATION + maxf(zoom_factor, distance_factor)
	await _hub.focus_location(location, zoom, Utils.anim_duration(duration))

func _on_mouse_catcher_clicked() -> void:
	if _waiting_for_click:
		_waiting_for_click = false
	elif _speaking_character:
		var bubble := _speaking_character.get_speech_bubble()
		if bubble:
			bubble.fast_forward()
