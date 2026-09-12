class_name Tutorial_SettlerQuests
extends TutorialBase

const ANIM_DURATION := 0.5
const ZOOM_SPEED_FACTOR := 0.4
const DISTANCE_SPEED_FACTOR := 0.002

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	GlobalSaveGame.changed.connect(_on_savegame_changed)
	GlobalSaveGame.quest_started.connect(_on_quest_started)
	_on_savegame_changed()

func stop_listening() -> void:
	GlobalSaveGame.changed.disconnect(_on_savegame_changed)
	GlobalSaveGame.quest_started.disconnect(_on_quest_started)

func _on_quest_started(_quest_instance: QuestInstance) -> void:
	_on_savegame_changed()

func _on_savegame_changed() -> void:
	var hub := Utils.get_active_hub()
	if hub and Utils.is_settler_questing_unlocked():
		for character in hub.get_spawned_characters():
			if character.offered_quest:
				ready_to_trigger.emit()
				return

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().process_frame  # Make sure size is updated.

	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var offering_character: HubCharacter
	for character in hub.get_spawned_characters():
		if character.offered_quest:
			offering_character = character
			if character.job == load('res://characters/jobs/job_scholar.tres'):  # Prefer scholars.
				break

	await _move_camera(offering_character.global_position, hub.max_zoom)

	var tooltip_anchor := offering_character.get_node('%TooltipAnchor') as Control
	var text := tr('''
You can now accept <term:settler_quest>s.

Settlers around the <term:hub> are looking to join expeditions with specific plans.

If you accept them into the next expedition, they will offer a task that grants a reward.

Settler quests only apply to the next <term_lower:run>, and add a difficulty modifier, \
but increase <term:insight> gains.
''').strip_edges()

	_outline_controls([tooltip_anchor])
	_show_tooltip(tooltip_anchor, text,
				  [Tooltip.RelativeDirection.RIGHT,
				   Tooltip.RelativeDirection.LEFT])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'settler_quest'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show

func _move_camera(location: Vector2, zoom: float) -> void:
	var hub := Utils.get_active_hub()
	var zoom_factor := absf(zoom - hub.get_zoom()) * ZOOM_SPEED_FACTOR
	var distance_factor := (location - hub.get_current_target_position()).length() * DISTANCE_SPEED_FACTOR
	var duration := ANIM_DURATION + maxf(zoom_factor, distance_factor)
	await hub.focus_location(location, zoom, Utils.anim_duration(duration))
