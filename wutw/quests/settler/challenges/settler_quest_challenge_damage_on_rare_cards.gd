class_name SettlerQuestChallenge_DamageOnEpicCards
extends SettlerQuestChallenge

@export var damage: int = 1

func start_listening(run: Run) -> void:
	run.signals.card_slotted.connect(_on_card_slotted)
	run.signals.card_cast_finished.connect(_on_cast_finished)

func stop_listening(run: Run) -> void:
	run.signals.card_slotted.disconnect(_on_card_slotted)
	run.signals.card_cast_finished.disconnect(_on_cast_finished)

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	_on_cast_finished(card)

func _on_cast_finished(card: Card) -> void:
	if card.card_type.rarity in [CardType.Rarity.EPIC, CardType.Rarity.LEGENDARY]:
		var run := Utils.get_active_run()
		run.run_or_queue_action(func() -> void:
			run.signals.settler_quest_challenge_triggered.emit(self)
			run.modify_inspiration(-damage, Run.InspirationChangeReason.SETTLER_QUEST)
		)

func describe() -> String:
	return tr('Lose %d <term_lower:inspiration> when an Epic or Legendary <term_lower:glyph> is played.') % damage
