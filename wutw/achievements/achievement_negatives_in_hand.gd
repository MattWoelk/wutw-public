class_name Achievement_NegativesInHand
extends Achievement_HandBase

func check_hand(deck: CardDeck) -> void:
	var num_negatives := 0
	for card in deck.get_hand_cards():
		if card.card_type.rarity == CardType.Rarity.NEGATIVE:
			num_negatives += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_negatives)
	# Achievement unlocked automatically based on stat range.
