@tool
class_name HauntingTrigger_BonusLost
extends HauntingTrigger

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('any <term_lower:bonus> is lost')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('<term:bonus> Lost')

func setup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.pre_bonus_gained.connect(_on_pre_bonus_gained)

func cleanup(_spot: Spot, _settlement: Settlement) -> void:
	var run := Utils.get_active_run()
	run.signals.pre_bonus_gained.disconnect(_on_pre_bonus_gained)

func _on_pre_bonus_gained(gain: BonusGain) -> void:
	if gain.amount >= 0:
		return
	var card_type: CardType
	if gain.get_reason() == BonusGain.Reason.ABILITY:
		card_type = (gain.source as Card).card_type
	triggered.emit(gain, null, card_type)
