@tool
class_name Relic_PlumWine
extends Relic

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.ability_finished.connect(_on_ability_finished)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.ability_finished.disconnect(_on_ability_finished)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_ability_finished(_card: Card, ability: CardAbility) -> void:
	if _state != State.ACTIVE:
		return
	if ability is CardAbility_Topdeck:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _run.get_current_stage().get_card_deck().draw(CardDeck.CardDrawReason.RELIC, true)
			_state = State.PASSIVE
		)
