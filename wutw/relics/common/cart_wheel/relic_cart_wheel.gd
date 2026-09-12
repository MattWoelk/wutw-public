@tool
class_name Relic_CartWheel
extends Relic

@export var satisfy_amount: int = 5

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.ability_started.connect(_on_ability_started)

func on_removed() -> void:
	_run.signals.ability_started.disconnect(_on_ability_started)
	super.on_removed()

func _on_ability_started(_card: Card, ability: CardAbility) -> void:
	if ability is CardAbility_Continue:
		var stage := _run.get_current_stage()
		if stage.mode == Stage.Mode.REGULAR:
			_run.run_or_queue_action(func() -> void:
				var reqs := stage.get_goal().get_remaining_requirements(stage.get_stage_bonus_amounts())
				if not reqs.is_empty():
					var bonus_type := stage.get_card_deck().get_random_state().pick(reqs.keys()) as BonusType
					triggered.emit()
					_run.gain_bonus(BonusGain.new(bonus_type, satisfy_amount, self))
					await _brief_wait()
			)

func get_description() -> String:
	return tr(default_description) % satisfy_amount
