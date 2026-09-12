class_name Achievement_SmallDeck
extends Achievement_RunBase

@export var desired_max_size := 5

func on_run_entered(run: Run) -> void:
	run.signals.card_removed.connect(_on_card_removed)

func on_run_exited(run: Run) -> void:
	run.signals.card_removed.disconnect(_on_card_removed)

func _on_card_removed(_card_type: CardType) -> void:
	check_in_run(Utils.get_active_run())

func check_in_run(run: Run) -> void:
	if run.get_deck_cards().size() <= desired_max_size:
		achieved.emit()
