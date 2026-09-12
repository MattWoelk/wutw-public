class_name Tutorial_Debate
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	GlobalSaveGame.changed.connect(_on_savegame_changed)
	_on_savegame_changed()

func stop_listening() -> void:
	GlobalSaveGame.changed.disconnect(_on_savegame_changed)

func _on_savegame_changed() -> void:
	var hub := Utils.get_active_hub()
	if hub and (hub.get_node('%DebateStatusBar') as CanvasItem).visible:
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().process_frame  # Make sure size is updated.

	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var text := tr('''
The Scribe and the Historian will now hold speeches to sway the people's opinion.

To do so, %s Hold Speech and choose a topic.

This topic choice determines who will give the speech and how the public opinion is affected.
''').strip_edges() % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	_outline_controls([])
	_show_tooltip(hub.get_node('%DebateStatusBar') as Control, text,
				  [Tooltip.RelativeDirection.FORCE_CENTER])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'debate'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
