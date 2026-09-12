class_name Achievement_AllInHand
extends Achievement_HandBase

func check_hand(deck: CardDeck) -> void:
	if deck.get_num_draw_pile_cards() == 0 and deck.get_num_discard_pile_cards() == 0:
		achieved.emit()
