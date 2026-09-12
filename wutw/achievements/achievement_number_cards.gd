class_name Achievement_NumberCards
extends Achievement_RunBase

@export var required_cards: Array[CardType]

func on_run_entered(run: Run) -> void:
	run.signals.card_added.connect(_on_card_added)
	check_in_run(run)  # In case in starting deck.

func on_run_exited(run: Run) -> void:
	run.signals.card_added.disconnect(_on_card_added)

func _on_card_added(_card_type: CardType) -> void:
	check_in_run(Utils.get_active_run())

func check_in_run(run: Run) -> void:
	var deck_cards := run.get_deck_cards()
	for card_type in required_cards:
		if card_type not in deck_cards:
			return
	achieved.emit()
