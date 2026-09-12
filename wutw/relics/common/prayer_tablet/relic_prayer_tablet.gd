@tool
class_name Relic_PrayerTablet
extends Relic

@export var bonus_type: BonusType
@export var amount_gained: int = 3

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_cast_finished.connect(_on_card_cast)

func on_removed() -> void:
	_run.signals.card_cast_finished.disconnect(_on_card_cast)
	super.on_removed()

func _on_card_cast(card: Card) -> void:
	if card.card_type.rarity == CardType.Rarity.NEGATIVE:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_run.gain_bonus(BonusGain.new(bonus_type, amount_gained, self))
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % [amount_gained, bonus_type.get_term_tag()]
