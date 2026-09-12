class_name Achievement_TotalCardsUnlocked
extends Achievement

var _num_unlocked_by_default: int = 0

func start_listening() -> void:
	var auto_unlocked: Dictionary[CardType, bool]
	for card_type in SaveGame.get_starter_cards():
		auto_unlocked[card_type] = true
	for card_type in SaveGame.get_auto_unlocked_cards():
		auto_unlocked[card_type] = true
	_num_unlocked_by_default = auto_unlocked.size()
	GlobalSaveGame.card_unlocked.connect(check)

func stop_listening() -> void:
	GlobalSaveGame.card_unlocked.disconnect(check)

func check() -> void:
	# Increment-only, so this is safe even on multiple saves.
	stat_changed.emit(GlobalSaveGame.get_num_unlocked_cards() - _num_unlocked_by_default)
	# Achievement unlocked automatically based on stat range.
