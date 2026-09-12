@tool
class_name Relic_CicadaShell
extends Relic

@export var hand_size_increase: int = 1
@export var heal_percent: int = 20

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.inspiration_exhausted.connect(_on_inspiration_exhausted)

func on_removed() -> void:
	_run.signals.inspiration_exhausted.disconnect(_on_inspiration_exhausted)
	_run.get_vars().remove_modifier(_get_modifier_tag())
	super.on_removed()

func _on_inspiration_exhausted(_reason: Run.InspirationChangeReason) -> void:
	_run.run_or_queue_action(func() -> void:
		if _state != State.EXPIRED:
			var current_inspiration := _run.get_var(RunVars.Var.CURRENT_INSPIRATION)
			if current_inspiration > 0:
				# This can happen if another effect has saved the player from exhausting inspiration.
				return
			triggered.emit()
			var heal_amount := floori(_run.get_var(RunVars.Var.MAX_INSPIRATION) * float(heal_percent) / 100.0)
			_run.get_vars().modify_base_value(RunVars.Var.CURRENT_INSPIRATION, heal_amount)
			_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())
			_state = State.EXPIRED
			await _brief_wait()
	)

func get_description() -> String:
	var text := tr(default_description) % [heal_percent, hand_size_increase]
	if _state == State.EXPIRED:
		text += '\n\n'
		text += tr('[b]This relic has already been used and is now expired.[/b]')
	return text
