class_name Tutorial_HarmonizationEnd
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 60

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.HARMONIZATION:
		ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var text := tr('''
Each <term:lack> left un<term_lower:satisfy_lack>ed by the end of the <term:harmonization> will reduce your <term:inspiration> by %d points.
''').strip_edges() % run.get_var(RunVars.Var.INSPIRATION_LOSS_PER_LACK)
	_outline_controls([])
	_show_tooltip(run.get_map(), text, [Tooltip.RelativeDirection.FORCE_CENTER])

func get_skip_id() -> String:
	return 'harmonization_end'
