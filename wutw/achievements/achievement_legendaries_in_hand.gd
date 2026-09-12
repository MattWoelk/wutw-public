class_name Achievement_LegendariesInHand
extends Achievement_HandBase

func check_hand(deck: CardDeck) -> void:
	var num_legendaries := 0
	for card in deck.get_hand_cards():
		if card.card_type.rarity == CardType.Rarity.LEGENDARY:
			num_legendaries += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_legendaries)
	# Achievement unlocked automatically based on stat range.
