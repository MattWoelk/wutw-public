class_name Tutorial_Museum
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	var hub := Utils.get_active_hub()
	var museum := hub.get_node('%HubContent').get_node('%HubMuseum').get_node('TooltipAnchor') as Control
	if museum.is_visible_in_tree():
		ready_to_trigger.emit()

func stop_listening() -> void:
	pass  # Triggers on hub start.

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().create_timer(1.1).timeout  # Let transitions, dialogue delays, etc. finish.

	var text := tr('''
This museum keeps track of everything you've encountered during your <term_lower:run>s.

It also contains hints about things you're yet to discover.

Visit it to learn more, or %s the exhibits to customize what they display.
''').strip_edges() % InputPrompts.get_input_markup(InputPrompts.InputType.LEFT_CLICK)

	var museum := hub.get_node('%HubContent').get_node('%HubMuseum').get_node('TooltipAnchor') as Control
	_outline_controls([museum])
	_show_tooltip(museum, text, [Tooltip.RelativeDirection.BELOW])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'museum'

func _on_continued() -> void:
	var hub := Utils.get_active_hub()
	hub.get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
