class_name Tutorial_Hub_Gate
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	ready_to_trigger.emit()

func stop_listening() -> void:
	pass  # Triggers on hub start.

func get_tutorial_order() -> int:
	return 30

func trigger() -> void:
	var hub := Utils.get_active_hub()
	var gate := hub.get_node('%HubContent').get_node('%MainGate').get_node('TooltipAnchor') as Control
	var text := tr('You can use this gate to launch a new <term_lower:run>.')
	_outline_controls([gate])
	_show_tooltip(gate, text, [Tooltip.RelativeDirection.BELOW])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'hub_gate'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
