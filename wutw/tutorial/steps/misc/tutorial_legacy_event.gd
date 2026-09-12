class_name Tutorial_LegacyEvent
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().signals.event_started.connect(_on_event_started)

func stop_listening() -> void:
	Utils.get_active_run().signals.event_started.disconnect(_on_event_started)

func _on_event_started(event: Event) -> void:
	if Event.Category.RECORD in event.categories:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	# Wait for animation.
	await run.get_tree().create_timer(1.0).timeout

	var text := tr('''
You have encountered a Legacy Event.

Choices made during such events have long-term story consequences!
''').strip_edges()

	var title_container := run.get_current_event_scene().get_node('%TitleLabel') as Control
	_outline_controls([title_container])
	_show_tooltip(title_container, text, [Tooltip.RelativeDirection.LEFT])

func get_skip_id() -> String:
	return 'legacy_event'
