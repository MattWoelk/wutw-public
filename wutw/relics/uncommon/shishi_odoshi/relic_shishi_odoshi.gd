@tool
class_name Relic_ShishiOdoshi
extends Relic

var _triggered_this_stage: bool = false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.ability_finished.connect(_on_ability_cast)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.ability_finished.disconnect(_on_ability_cast)
	super.on_removed()

func _on_stage_started() -> void:
	_triggered_this_stage = false
	_state = State.ACTIVE

func _on_ability_cast(_card: Card, ability: CardAbility) -> void:
	if _triggered_this_stage:
		return
	if ability is CardAbility_Discard:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_triggered_this_stage = true
			await _run.get_current_stage().get_card_deck().draw(CardDeck.CardDrawReason.RELIC, true)
			_state = State.PASSIVE
		)
