class_name SettlerQuestChallenge_DamageOnRemoval
extends SettlerQuestChallenge

@export var damage: int = 10

func start_listening(run: Run) -> void:
	run.signals.card_removed.connect(_on_card_removed)

func stop_listening(run: Run) -> void:
	run.signals.card_removed.disconnect(_on_card_removed)

func _on_card_removed(_card_type: CardType) -> void:
	var run := Utils.get_active_run()
	run.signals.settler_quest_challenge_triggered.emit(self)
	run.modify_inspiration(-damage, Run.InspirationChangeReason.SETTLER_QUEST)

func describe() -> String:
	return tr('Lose %d <term:inspiration> whenever a <term_lower:glyph> is <term_lower:remove_card>d from your <term_lower:card_deck>.') % damage
