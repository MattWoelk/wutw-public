@tool
class_name Relic_RoofTile
extends Relic

@export var min_upgrades: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_finished.connect(_on_stage_finished)
	_run.signals.card_choice_finished.connect(_on_card_choice_finished)

func on_removed() -> void:
	_run.signals.foray_finished.disconnect(_on_stage_finished)
	_run.signals.card_choice_finished.disconnect(_on_card_choice_finished)
	super.on_removed()

func _on_stage_finished(settlement_state: SettlementState) -> void:
	var num_sufficiently_developed := 0
	for upgrades in settlement_state.activated_upgrades:
		if upgrades.size() >= min_upgrades:
			num_sufficiently_developed += 1
	if num_sufficiently_developed >= settlement_state.spot_types.size():
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_run.get_vars().add_modifier(RunVars.Var.CARD_REWARD_CHOICES, 1, _get_modifier_tag())
			await _brief_wait()
		)

func _on_card_choice_finished() -> void:
	_run.get_vars().remove_modifier(_get_modifier_tag())

func get_description() -> String:
	return tr(default_description) % min_upgrades
