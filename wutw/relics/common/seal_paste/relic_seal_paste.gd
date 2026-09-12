@tool
class_name Relic_SealPaste
extends Relic

@export var hand_size_increase: int = 1

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.harmonization_started.connect(_on_harmonization_started)
	_run.signals.harmonization_finished.connect(_on_harmonization_finished)

func on_removed() -> void:
	_run.signals.harmonization_started.disconnect(_on_harmonization_started)
	_run.signals.harmonization_finished.disconnect(_on_harmonization_finished)
	super.on_removed()

func _on_harmonization_started() -> void:
	_run.get_vars().add_modifier(RunVars.Var.HAND_SIZE, hand_size_increase, _get_modifier_tag())
	triggered.emit()
	_state = State.ACTIVE

func _on_harmonization_finished() -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag())
	_state = State.PASSIVE

func get_description() -> String:
	return tr(default_description) % hand_size_increase
