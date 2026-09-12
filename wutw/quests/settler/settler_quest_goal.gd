@abstract
class_name SettlerQuestGoal
extends Resource

@warning_ignore('unused_signal')
signal achieved

@abstract func start_listening(run: Run) -> void
@abstract func stop_listening(run: Run) -> void
@abstract func describe() -> String

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return []
