class_name Achievement_LegendaryCardDiscovered
extends Achievement

var _legendary_cards: Array[CardType]

func start_listening() -> void:
	_legendary_cards = CardType.get_all_card_types_by_tier(CardType.Rarity.LEGENDARY)
	GlobalSaveGame.card_discovered.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.card_discovered.disconnect(check)

func check() -> void:
	for card_type in _legendary_cards:
		if GlobalSaveGame.has_seen_card(card_type):
			achieved.emit()
			break
