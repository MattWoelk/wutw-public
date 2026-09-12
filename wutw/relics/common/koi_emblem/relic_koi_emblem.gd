@tool
class_name Relic_KoiEmblem
extends Relic

@export var extra_cards: int = 2

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.foray_finished.connect(_on_stage_finished)
	_run.signals.redraw_finished.connect(_on_redraw_finished)

func on_removed() -> void:
	_run.signals.foray_finished.disconnect(_on_stage_finished)
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	super.on_removed()

func _on_stage_finished(settlement_state: SettlementState) -> void:
	var num_unsatisfied := settlement_state.goal.get_remaining_requirements(
		settlement_state.bonus_amounts).size()
	if num_unsatisfied > 0:
		_state = State.ACTIVE

func _on_redraw_finished(_is_first: bool) -> void:
	_run.run_or_queue_action(func() -> void:
		if _state == State.ACTIVE:
			triggered.emit()
			var deck := _run.get_current_stage().get_card_deck()
			for _i in range(extra_cards):
				await deck.draw(CardDeck.CardDrawReason.RELIC, true)
			_state = State.PASSIVE
	)

func get_description() -> String:
	return tr(default_description) % extra_cards
