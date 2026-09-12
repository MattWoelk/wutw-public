class_name SettlerQuestChallenge_HarmOnAspectCards
extends SettlerQuestChallenge

@export var aspect_type: AspectType
@export var damage: int = 0
@export var bonus_loss_type: BonusType
@export var bonus_loss: int = 0

func start_listening(run: Run) -> void:
	run.signals.card_slotted.connect(_on_card_slotted)
	run.signals.card_cast_finished.connect(_on_cast_finished)

func stop_listening(run: Run) -> void:
	run.signals.card_slotted.disconnect(_on_card_slotted)
	run.signals.card_cast_finished.disconnect(_on_cast_finished)

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	_on_cast_finished(card)

func _on_cast_finished(card: Card) -> void:
	if aspect_type in card.card_type.aspects:
		var run := Utils.get_active_run()
		run.run_or_queue_action(func() -> void:
			run.signals.settler_quest_challenge_triggered.emit(self)
			if damage > 0:
				run.modify_inspiration(-damage, Run.InspirationChangeReason.SETTLER_QUEST)
			if bonus_loss > 0:
				run.gain_bonus(BonusGain.new(bonus_loss_type, -bonus_loss, self))
		)

func describe() -> String:
	if damage > 0 and bonus_loss > 0:
		return tr('Lose %d <term_lower:inspiration> and %d %s when a <term_lower:glyph> with %s is played.') % [
			damage, bonus_loss, bonus_loss_type.get_term_tag(), aspect_type.get_term_tag()]
	elif damage > 0:
		return tr('Lose %d <term_lower:inspiration> when a <term_lower:glyph> with %s is played.') % [
			damage, aspect_type.get_term_tag()]
	elif bonus_loss > 0:
		return tr('Lose %d %s when a <term_lower:glyph> with %s is played.') % [
			bonus_loss, bonus_loss_type.get_term_tag(), aspect_type.get_term_tag()]
	else:
		Utils.ensure(false)
		return tr('None')
