@abstract
class_name Achievement_HandBase
extends Achievement_RunBase

@abstract func check_hand(deck: CardDeck) -> void

func on_run_entered(run: Run) -> void:
	run.signals.card_added_to_hand.connect(_on_card_added_to_hand)

func on_run_exited(run: Run) -> void:
	run.signals.card_added_to_hand.disconnect(_on_card_added_to_hand)

func _on_card_added_to_hand(_card: Card, _reason: CardDeck.CardDrawReason, _from_discards: bool) -> void:
	var run := Utils.get_active_run()
	assert(run)
	assert(run.get_current_stage())
	check_hand(run.get_current_stage().get_card_deck())

func check_in_run(run: Run) -> void:
	if not run.get_current_stage():
		return
	check_hand(run.get_current_stage().get_card_deck())
