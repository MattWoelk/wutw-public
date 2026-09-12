class_name Achievement_DrawsPerTurn
extends Achievement_RunBase

var _cards_drawn_this_turn := 0

func on_run_entered(run: Run) -> void:
	run.signals.redraw_started.connect(_on_redraw_started)
	run.signals.card_drawn.connect(_on_card_drawn)

func on_run_exited(run: Run) -> void:
	run.signals.redraw_started.disconnect(_on_redraw_started)
	run.signals.card_drawn.disconnect(_on_card_drawn)

func _on_redraw_started(_is_first: bool) -> void:
	_cards_drawn_this_turn = 0

func _on_card_drawn(_card: Card, _reason: CardDeck.CardDrawReason, from_discards: bool) -> void:
	if not from_discards:
		_cards_drawn_this_turn += 1
		# Increment-only, so this is safe even on multiple saves.
		stat_changed.emit(_cards_drawn_this_turn)
		# Achievement unlocked automatically based on stat range.

func check_in_run(_run: Run) -> void:
	return  # Can't be unlocked when loading.
