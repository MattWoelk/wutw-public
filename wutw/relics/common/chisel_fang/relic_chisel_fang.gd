@tool
class_name Relic_ChiselFang
extends Relic

@export var max_deck_size_exclusive: int = 10
@export var foray_goal_reduction_percent: int = 10

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_added.connect(_on_deck_changed.unbind(1))
	_run.signals.card_removed.connect(_on_deck_changed.unbind(1))
	_on_deck_changed()

func on_removed() -> void:
	_run.signals.card_added.disconnect(_on_deck_changed.unbind(1))
	_run.signals.card_removed.disconnect(_on_deck_changed.unbind(1))
	_on_deck_changed()
	super.on_removed()

func _on_deck_changed() -> void:
	_run.run_or_queue_action(func() -> void:
		if _run.get_deck_cards().size() < max_deck_size_exclusive:
			if _state != State.ACTIVE:
				_run.get_vars().add_modifier(RunVars.Var.STAGE_REQUIREMENTS_PERCENTAGE, -foray_goal_reduction_percent, _get_modifier_tag())
				_state = State.ACTIVE
				triggered.emit()
		else:
			if _state != State.PASSIVE:
				_run.get_vars().remove_modifier(_get_modifier_tag())
				_state = State.PASSIVE
				triggered.emit()
	)

func get_description() -> String:
	return tr(default_description) % [max_deck_size_exclusive, foray_goal_reduction_percent]
