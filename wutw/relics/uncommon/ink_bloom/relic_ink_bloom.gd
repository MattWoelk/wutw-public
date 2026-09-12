@tool
class_name Relic_InkBloom
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.ability_finished.connect(_on_ability_cast)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.ability_finished.disconnect(_on_ability_cast)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_ability_cast(card: Card, ability: CardAbility) -> void:
	_run.run_or_queue_action(func() -> void:
		if _state == State.ACTIVE:
			if ability is CardAbility_Spread:
				triggered.emit()
				_state = State.PASSIVE
				await _run.get_current_stage().cast_ability(card, ability)
	)
