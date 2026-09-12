class_name Achievement_TotalEventsDiscovered
extends Achievement

var _seen_events: Dictionary[Event, bool]

func start_listening() -> void:
	GlobalSaveGame.event_choice_discovered.connect(_on_event_choice_discovered)
	for event: Event in Event.get_all_events().values():
		if GlobalSaveGame.has_seen_event(event):
			_seen_events[event] = true

func stop_listening() -> void:
	GlobalSaveGame.event_choice_discovered.disconnect(_on_event_choice_discovered)

func _on_event_choice_discovered(event: Event) -> void:
	if event not in _seen_events:
		_seen_events[event] = true
		check()

func check() -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(_seen_events.size())
	# Achievement unlocked automatically based on stat range.
