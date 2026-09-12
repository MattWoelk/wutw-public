class_name Tutorial_ExplorerTrips
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
	if hub and Utils.is_explorer_trips_unlocked():
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().process_frame  # Make sure size is updated.

	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var portal_network := hub.get_node('%HubContent').get_node('%PortalNetwork').get_node('TooltipAnchor') as Control
	var text := tr('''
The Explorer can now visit previously settled shards.

Such trips may discover historical developments, reveal new <term_lower:skill>s, or advance the story.

It will take one <term_lower:season> of an <term_lower:run> to visit one shard.
''').strip_edges()

	_outline_controls([portal_network])
	_show_tooltip(portal_network, text, [Tooltip.RelativeDirection.BELOW])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'explorer_trips'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
