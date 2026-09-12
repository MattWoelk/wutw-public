@tool
class_name Relic_CleanSleeve
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.inspiration_lost.connect(_on_inspiration_lost)

func on_removed() -> void:
	_run.signals.inspiration_lost.disconnect(_on_inspiration_lost)
	super.on_removed()

func _on_inspiration_lost(_amount: int, _reason: Run.InspirationChangeReason) -> void:
	_run.run_or_queue_action(func() -> void:
		if _state == State.ACTIVE:
			triggered.emit()
			_run.get_current_stage().add_modifier(RunVars.Var.HAND_SIZE, 1)
			await _brief_wait()
			_state = State.PASSIVE
	)
