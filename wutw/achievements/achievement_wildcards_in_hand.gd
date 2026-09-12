class_name Achievement_WildcardsInHand
extends Achievement_HandBase

const NUM_ASPECT_TYPES := 7

func check_hand(deck: CardDeck) -> void:
	var num_wildcards := 0
	for card in deck.get_hand_cards():
		if card.card_type.aspects.size() == NUM_ASPECT_TYPES:
			num_wildcards += 1
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(num_wildcards)
	# Achievement unlocked automatically based on stat range.
