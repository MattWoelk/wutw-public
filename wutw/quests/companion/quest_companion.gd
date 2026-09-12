@tool
class_name Quest_Companion
extends Quest

@export var event_var_id: String

func instantiate(initial_state: int = QuestInstance.STATE_ACTIVE, _initial_goals_completed: Array[bool] = []) -> QuestInstance:
	return super.instantiate(initial_state, [true, false, false])

func on_run_entered(instance: QuestInstance, _run: Run) -> void:
	assert(not GlobalSaveGame.changed.is_connected(_on_savegame_changed.bind(instance)))
	GlobalSaveGame.changed.connect(_on_savegame_changed.bind(instance))

func on_run_exited(instance: QuestInstance, _run: Run) -> void:
	assert(GlobalSaveGame.changed.is_connected(_on_savegame_changed.bind(instance)))
	GlobalSaveGame.changed.disconnect(_on_savegame_changed.bind(instance))

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	_on_savegame_changed(instance)

func _on_savegame_changed(instance: QuestInstance) -> void:
	if instance.is_active():
		var progress := GlobalSaveGame.get_events_state().get_int_or_default('global', event_var_id, 0)
		if progress >= 2:
			instance.set_goal_finished(1)
		if progress >= 3:
			instance.set_goal_finished(2)
		if instance.is_ready_to_finish():
			instance.finish(null)
