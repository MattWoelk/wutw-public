class_name Achievement_BigDeck
extends Achievement_RunBase

func on_run_entered(run: Run) -> void:
	run.signals.card_added.connect(_on_card_added)

func on_run_exited(run: Run) -> void:
	run.signals.card_added.disconnect(_on_card_added)

func _on_card_added(_card_type: CardType) -> void:
	check_in_run(Utils.get_active_run())

func check_in_run(run: Run) -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(run.get_deck_cards().size())
	# Achievement unlocked automatically based on stat range.
