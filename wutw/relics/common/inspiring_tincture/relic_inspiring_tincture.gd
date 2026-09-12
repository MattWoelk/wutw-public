@tool
class_name Relic_InspiringTincture
extends Relic

@export var amount_gained: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.event_started.connect(_on_event_started)

func on_removed() -> void:
	_run.signals.event_started.disconnect(_on_event_started)
	super.on_removed()

func _on_event_started(_event: Event) -> void:
	_run.run_or_queue_action(func() -> void:
		_run.modify_inspiration(2, Run.InspirationChangeReason.RELIC)
		triggered.emit()
		await _brief_wait()
	)

func get_description() -> String:
	return tr(default_description) % amount_gained
