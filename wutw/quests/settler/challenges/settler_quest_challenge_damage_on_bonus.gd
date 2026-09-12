class_name SettlerQuestChallenge_DamageOnBonus
extends SettlerQuestChallenge

@export var bonus_type: BonusType
@export var on_loss: bool = true
@export var damage: int = 1

func start_listening(run: Run) -> void:
	if on_loss:
		run.signals.bonus_lost.connect(_on_bonus_triggered)
	else:
		run.signals.bonus_gained.connect(_on_bonus_triggered)

func stop_listening(run: Run) -> void:
	if on_loss:
		run.signals.bonus_lost.disconnect(_on_bonus_triggered)
	else:
		run.signals.bonus_gained.disconnect(_on_bonus_triggered)

func _on_bonus_triggered(in_bonus_type: BonusType, _amount: int, _reason: BonusGain.Reason) -> void:
	if in_bonus_type == bonus_type:
		var run := Utils.get_active_run()
		run.run_or_queue_action(func() -> void:
			run.signals.settler_quest_challenge_triggered.emit(self)
			run.modify_inspiration(-damage, Run.InspirationChangeReason.SETTLER_QUEST)
		)

func describe() -> String:
	if on_loss:
		return tr('Lose %d <term_lower:inspiration> when %s is lost.') % [
			damage, bonus_type.get_term_tag()]
	else:
		return tr('Lose %d <term_lower:inspiration> when %s is gained.') % [
			damage, bonus_type.get_term_tag()]
