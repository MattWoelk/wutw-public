class_name Tutorial_Retry
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_state_changed)

func _on_state_changed() -> void:
	if GlobalSaveGame.get_total_playtime() < 60 * 60 and not Utils.is_dev():
		return  # Don't bother the player until we know they're invested.
	var run := Utils.get_active_run()
	if run.get_state() == RunData.State.STAGE_END:
		if run.get_var(RunVars.Var.CURRENT_INSPIRATION) <= 0:
			ready_to_trigger.emit()

func trigger() -> void:
	var run := Utils.get_active_run()
	var text := tr('''
If you find yourself wondering if you could've played this <term_lower:stage> differently, \
you can try restarting it from the pause menu (%s).

It's for you to decide if that counts as cheating.
''').strip_edges() % InputPrompts.get_input_markup(InputPrompts.InputType.ESCAPE)
	var stage_end := run.get_current_scene() as StageEnd
	_outline_controls([])
	_show_tooltip(stage_end.get_node('%ScrollPanel') as Control, text,
				  [Tooltip.RelativeDirection.FORCE_CENTER])

func get_skip_id() -> String:
	return 'retry'
