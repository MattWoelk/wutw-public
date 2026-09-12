@tool
class_name Relic_IncensePellet
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.haunting_blocked.connect(triggered.emit.unbind(1))

func on_removed() -> void:
	_run.signals.haunting_blocked.disconnect(triggered.emit.unbind(1))
	super.on_removed()
