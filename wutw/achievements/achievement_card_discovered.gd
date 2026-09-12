class_name Achievement_CardDiscovered
extends Achievement

@export var card_type: CardType

func start_listening() -> void:
	GlobalSaveGame.card_discovered.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.card_discovered.disconnect(check)

func check() -> void:
	if GlobalSaveGame.has_seen_card(card_type):
		achieved.emit()
