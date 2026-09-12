class_name Tutorial_HarmonizationStart
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 10

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.CAPITAL_PLACEMENT:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()

	# Make sure the harmonization UI is sized.
	await run.get_tree().process_frame

	var text := tr('''
Now, at the end of the <term_lower:season>, it's time to establish the <term:capital>.

This final step is called the <term:harmonization>.
''').strip_edges()

	_outline_controls([])
	_show_tooltip(run.get_map(), text, [Tooltip.RelativeDirection.FORCE_CENTER])

func get_skip_id() -> String:
	return 'harmonization_start'
