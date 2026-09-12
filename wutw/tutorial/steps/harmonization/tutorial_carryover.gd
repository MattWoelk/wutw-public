class_name Tutorial_Carryover
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 50

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.HARMONIZATION:
		ready_to_trigger.emit()

func trigger() -> void:
	var text := tr('''
The state of all your <term_lower:settlement>s and the <term:capital> carries over to the next <term_lower:season>.
''').strip_edges()

	_outline_controls([])
	_show_tooltip(Utils.get_active_run().get_map(), text, [Tooltip.RelativeDirection.FORCE_CENTER])

func get_skip_id() -> String:
	return 'harmonization_carryover'
