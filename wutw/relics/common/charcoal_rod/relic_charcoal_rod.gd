@tool
class_name Relic_AshWreath
extends Relic

@export var heal_amount: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.ability_finished.connect(_on_ability_cast)

func on_removed() -> void:
	_run.signals.ability_finished.disconnect(_on_ability_cast)
	super.on_removed()

func _on_ability_cast(_card: Card, ability: CardAbility) -> void:
	if ability is CardAbility_Discard:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_run.modify_inspiration(heal_amount, Run.InspirationChangeReason.RELIC)
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % heal_amount
