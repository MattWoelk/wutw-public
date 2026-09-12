class_name Tutorial_CapitalLocaton
extends TutorialBase

func get_tutorial_type() -> Type:
	return Type.RUN

func start_listening() -> void:
	Utils.get_active_run().state_changed.connect(_on_run_state_changed)

func stop_listening() -> void:
	Utils.get_active_run().state_changed.disconnect(_on_run_state_changed)

func get_tutorial_order() -> int:
	return 30

func _on_run_state_changed() -> void:
	if Utils.get_active_run().get_state() == RunData.State.CAPITAL_PLACEMENT:
		ready_to_trigger.emit()

func trigger() -> void:
	var text := tr('Our first task is to choose a location for the <term_lower:capital>.')
	_outline_controls([])
	_show_tooltip(Utils.get_active_run().get_map(), text, [Tooltip.RelativeDirection.FORCE_CENTER])

func get_skip_id() -> String:
	return 'harmonization_capital_location'
