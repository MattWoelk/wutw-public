class_name Tutorial_Season
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func _on_run_state_changed() -> void:
	var run := Utils.get_active_run()
	if run.scaling.stages_per_season >= 100:  # No seasons in first run.
		return
	if run.get_state() != RunData.State.STAGE_SELECTOR:
		return
	ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()

	# Make sure the stage selector UI is sized.
	await run.get_tree().process_frame

	var text := tr('''
After 6 <term_lower:foray>s, the <term:season> will end and you will establish the <term:capital> starting a <term:harmonization>.
''').strip_edges()

	var title_container := run.get_current_scene().get_node('%TitleLabel') as Control
	_outline_controls([title_container])
	_show_tooltip(title_container, text, [Tooltip.RelativeDirection.BELOW])

func get_skip_id() -> String:
	return 'season'
