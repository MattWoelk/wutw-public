class_name Tutorial_PracticeMinigame
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	GlobalGameSettings.changed.connect(_on_settings_changed)
	_on_settings_changed()

func stop_listening() -> void:
	GlobalGameSettings.changed.disconnect(_on_settings_changed)

func get_tutorial_order() -> int:
	return 900

func _on_settings_changed() -> void:
	if GameSettings.Japanese.practice_enabled.value():
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().create_timer(1.5).timeout  # HACK: Wait for quest UI.

	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var text := tr('''
This is the scroll on which the original survivors had written their names.

Nowadays novices read it to practice their glyphs.

%s on the scroll to start a kanji practice minigame!
''').strip_edges() % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var scroll := hub.get_node('%HubContent').get_node('%Scroll').get_node('TooltipAnchor') as Control
	_outline_controls([scroll])
	_show_tooltip(scroll, text, [Tooltip.RelativeDirection.LEFT])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'practice_minigame'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
