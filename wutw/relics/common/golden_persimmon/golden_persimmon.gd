@tool
class_name Relic_GoldenPersimmon
extends Relic

@export var triggering_bonus_type: BonusType
@export var penalty_bonus_type: BonusType
@export var percentage_chance: int = 25

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func _on_bonus_gained(gained_bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if gained_bonus_type == triggering_bonus_type and amount > 0:
		if _run.get_card_deck_random().rand_float() * 100 <= percentage_chance:
			_run.gain_bonus(BonusGain.new(penalty_bonus_type, -amount, self))
			triggered.emit()

func get_description() -> String:
	return tr(default_description) % [
			triggering_bonus_type.get_term_tag(), percentage_chance, penalty_bonus_type.get_term_tag()]
