@tool
class_name Relic_RepairedSandal
extends Relic

@export var granted_card: CardType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.ability_started.connect(_on_ability_started)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.ability_started.disconnect(_on_ability_started)
	super.on_removed()

func _on_stage_started() -> void:
	_state = State.ACTIVE

func _on_ability_started(_card: Card, ability: CardAbility) -> void:
	if ability is CardAbility_Split:
		_run.run_or_queue_action(func() -> void:
			if _state != State.PASSIVE:
				triggered.emit()
				await _run.get_current_stage().get_card_deck().add_card_to_hand(
					granted_card, CardDeck.CardDrawReason.RELIC)
				_state = State.PASSIVE
		)

func get_description() -> String:
	return tr(default_description) % granted_card.get_term_tag()
