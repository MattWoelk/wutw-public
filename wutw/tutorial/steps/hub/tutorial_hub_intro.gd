class_name Tutorial_Hub_Intro
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	ready_to_trigger.emit()

func stop_listening() -> void:
	pass  # Triggers on hub start.

func get_tutorial_order() -> int:
	return 0

func trigger() -> void:
	var hub := Utils.get_active_hub()
	await hub.get_tree().create_timer(1.1).timeout  # Let transitions, dialogue delays, etc. finish.
	while GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) > UI.Layer.GAME:
		await hub.get_tree().process_frame

	var text := tr('''
This is the <term:hub> from which we launch our <term_lower:run>s.

It will continue to evolve as we resettle the shards.

You can zoom with the %s and pan with %s.
''').strip_edges() % [
	InputPrompts.get_input_markup(InputPrompts.InputType.ZOOM),
	InputPrompts.get_input_markup(InputPrompts.InputType.PAN),
]
	_outline_controls([])
	_show_tooltip(hub.get_node('%SubViewportContainer') as Control, text, [Tooltip.RelativeDirection.FORCE_CENTER])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'hub_intro'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
