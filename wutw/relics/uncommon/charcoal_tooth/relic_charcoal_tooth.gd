@tool
class_name Relic_CharcoalTooth
extends Relic

@export var max_percent: int = 25
@export var heal_amount: int = 10

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_started.connect(_on_stage_started)
	_run.signals.inspiration_gained.connect(_on_inspiration_changed.unbind(2))
	_run.signals.inspiration_lost.connect(_on_inspiration_changed.unbind(2))
	_on_inspiration_changed()

func on_removed() -> void:
	_run.signals.foray_started.disconnect(_on_stage_started)
	_run.signals.inspiration_gained.disconnect(_on_inspiration_changed.unbind(2))
	_run.signals.inspiration_lost.disconnect(_on_inspiration_changed.unbind(2))
	super.on_removed()

func _on_stage_started() -> void:
	var current := _run.get_var(RunVars.Var.CURRENT_INSPIRATION)
	var maximum := _run.get_var(RunVars.Var.MAX_INSPIRATION)
	var percent := float(current) / float(maximum) * 100.0
	if percent < max_percent:
		_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)
		triggered.emit()

func _on_inspiration_changed() -> void:
	var current := _run.get_var(RunVars.Var.CURRENT_INSPIRATION)
	var maximum := _run.get_var(RunVars.Var.MAX_INSPIRATION)
	var percent := float(current) / float(maximum) * 100.0
	_state = State.ACTIVE if percent < max_percent else State.PASSIVE

func get_description() -> String:
	return tr(default_description) % [max_percent, heal_amount]
