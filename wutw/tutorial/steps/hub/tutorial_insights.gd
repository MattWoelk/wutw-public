class_name Tutorial_Insights
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	ready_to_trigger.emit()

func stop_listening() -> void:
	pass  # Triggers on hub start.

func get_tutorial_order() -> int:
	return 10

func trigger() -> void:
	var hub := Utils.get_active_hub()
	var text := tr('''
These are your <term:insight> points.

<term:insight>s are gained during <term_lower:run>s, with each established <term_lower:settlement>.
''').strip_edges()
	var insights_counter := hub.get_top_hud().get_insights_counter()
	_outline_controls([insights_counter])
	_show_tooltip(insights_counter, text, [Tooltip.RelativeDirection.BELOW])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'insights'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
