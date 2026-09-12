class_name SettlerQuestGoal_Event
extends SettlerQuestGoal

@export var event: Event

func start_listening(run: Run) -> void:
	run.signals.event_finished.connect(_on_event_finished)

func stop_listening(run: Run) -> void:
	run.signals.event_finished.disconnect(_on_event_finished)

func _on_event_finished(finished_event: Event) -> void:
	if event == finished_event:
		achieved.emit()

func describe() -> String:
	assert(event)
	return tr('Encounter the <event:%s> <term_lower:event>.') % event.event_id
