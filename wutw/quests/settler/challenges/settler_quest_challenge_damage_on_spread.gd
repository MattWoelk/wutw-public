class_name SettlerQuestChallenge_DamageOnSpread
extends SettlerQuestChallenge

@export var damage: int = 1

func start_listening(run: Run) -> void:
	run.signals.card_cast_finished.connect(_on_cast_finished)

func stop_listening(run: Run) -> void:
	run.signals.card_cast_finished.disconnect(_on_cast_finished)

func _on_cast_finished(card: Card) -> void:
	var has_spread := false
	for ability in card.card_type.abilities:
		if ability is CardAbility_Spread:
			has_spread = true
	if has_spread:
		var run := Utils.get_active_run()
		run.run_or_queue_action(func() -> void:
			run.signals.settler_quest_challenge_triggered.emit(self)
			run.modify_inspiration(-damage, Run.InspirationChangeReason.SETTLER_QUEST)
		)

func describe() -> String:
	return tr('Lose %d <term_lower:inspiration> when a <term:card_ability.spread> or <term:card_ability.mirror> <term_lower:card_ability> is <term_lower:cast_card>.') % damage
