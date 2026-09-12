class_name Tutorial_Skills
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.HUB

func start_listening() -> void:
	ready_to_trigger.emit()

func stop_listening() -> void:
	pass  # Triggers on hub start.

func get_tutorial_order() -> int:
	return 20

func trigger() -> void:
	var hub := Utils.get_active_hub()
	var shrine := hub.get_node('%HubContent').get_node('%Shrine').get_node('TooltipAnchor') as Control
	var text := tr('''
You can spend <term:insight>s here to permanently unlock new <term:skill>s.

Skill can provide numerical bonuses or unlock completely new gameplay systems.

More <term_lower:skill>s will become available as you continue the story.
''').strip_edges()
	_outline_controls([shrine])
	_show_tooltip(shrine, text, [Tooltip.RelativeDirection.BELOW])

	hub.get_tree().process_frame.connect(_check_should_wait)

func get_skip_id() -> String:
	return 'skills'

func _on_continued() -> void:
	Utils.get_active_hub().get_tree().process_frame.disconnect(_check_should_wait)
	super._on_continued()

func _check_should_wait() -> void:
	_set_visible(GlobalUI.get_highest_interactive_layer(UI.Layer.TUTORIAL) <= UI.Layer.GAME)

func _set_visible(should_show: bool) -> void:
	_get_container().visible = should_show
	if _tooltip:
		_tooltip.visible = should_show
