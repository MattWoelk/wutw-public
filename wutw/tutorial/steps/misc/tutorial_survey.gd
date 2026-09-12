class_name Tutorial_Survey
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.SURVEY_SELECTOR:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()

	# Make sure the stage selector UI is sized.
	await run.get_tree().process_frame

	var text := tr('''
After 3 <term_lower:foray>s, a <term_lower:survey> team will go out to map a region of the shard.

They will have to deal with a variety of <term_lower:encounter>s, both challenges and opportunities.

You can choose to end their trip at any time, but the further you advance,\
 the more of the map you will reveal.
''').strip_edges()

	var title_container := run.get_current_scene().get_node('%TitleLabel') as Control
	_outline_controls([title_container])
	_show_tooltip(title_container, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'survey'
