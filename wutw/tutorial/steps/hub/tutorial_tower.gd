class_name Tutorial_Tower
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	GlobalSaveGame.changed.connect(_on_savegame_changed)
	_on_savegame_changed()

func stop_listening() -> void:
	GlobalSaveGame.changed.disconnect(_on_savegame_changed)

func _on_savegame_changed() -> void:
	if Utils.are_shard_types_unlocked():
		ready_to_trigger.emit()

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().create_timer(1.0).timeout  # HACK: Wait for quest UI.
	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var tower := hub.get_node('%HubContent').get_node('%Tower').get_node('TooltipAnchor') as Control
	var text := tr('''
You can view previously resettled <term:world_shard>s here, as well as explore potential <term_lower:shard_type>s.
''').strip_edges()

	_outline_controls([tower], false, [], Vector2(5, 5))
	_show_tooltip(tower, text, [Tooltip.RelativeDirection.LEFT])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'tower'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
