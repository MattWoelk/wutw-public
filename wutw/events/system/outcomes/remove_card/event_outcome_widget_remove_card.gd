class_name EventOutcomeWidget_RemoveCard
extends EventOutcomeWidget

var card_type: CardType
var aspect: AspectType = null

func _ready() -> void:
	var run := Utils.get_active_run()
	var removed_card := card_type
	if not card_type:
		if aspect:
			for option in run.get_deck_cards():
				if aspect in option.aspects:
					removed_card = option
					break
		else:
			removed_card = run.get_events_random().pick(run.get_deck_cards())
	if not Utils.ensure(removed_card != null):
		visible = false
		finished.emit()
		return
	run.remove_card_from_deck(removed_card)

	# Also remove from the current deck being played.
	var stage := run.get_current_stage()
	if stage:
		var deck := stage.get_card_deck()
		deck.erase_card(removed_card)

	(%Card as Card).card_type = removed_card
	await (%Card as Card).tear_up()

	finished.emit()
