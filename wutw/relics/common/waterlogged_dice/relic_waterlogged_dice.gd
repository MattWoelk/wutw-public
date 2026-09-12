@tool
class_name Relic_WaterloggedDice
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_added.connect(_on_card_added)

func on_removed() -> void:
	_run.signals.card_added.disconnect(_on_card_added)
	super.on_removed()

func _on_card_added(_card_type: CardType) -> void:
	_run.run_or_queue_action(func() -> void:
		triggered.emit()
		_run.get_vars().modify_base_value(RunVars.Var.CARD_REWARD_REROLLS, 1)
	)
