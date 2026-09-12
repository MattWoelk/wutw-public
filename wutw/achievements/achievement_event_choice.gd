class_name Achievement_EventChoice
extends Achievement

@export var event: Event
@export var choice_indices: Array[int]

func start_listening() -> void:
	GlobalSaveGame.event_choice_discovered.connect(_on_event_choice_discovered)

func stop_listening() -> void:
	GlobalSaveGame.event_choice_discovered.disconnect(_on_event_choice_discovered)

func _on_event_choice_discovered(discovered_event: Event) -> void:
	if discovered_event == event:
		check()

func check() -> void:
	if choice_indices:
		for choice_index in choice_indices:
			if GlobalSaveGame.has_seen_event_choice(event, choice_index):
				achieved.emit()
				break
	else:
		if GlobalSaveGame.has_seen_event(event):
			achieved.emit()
