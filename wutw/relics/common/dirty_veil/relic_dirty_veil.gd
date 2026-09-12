@tool
class_name Relic_DirtyVeil
extends Relic

@export var aspect_type: AspectType
@export var bonus_type: BonusType
@export var amount_gained: int = 5

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_slotted)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	super.on_removed()

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	if aspect_type in card.card_type.aspects:
		_run.run_or_queue_action(func() -> void:
			_run.gain_bonus(BonusGain.new(bonus_type, amount_gained, self))
			triggered.emit()
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % [aspect_type.get_term_tag(), amount_gained, bonus_type.get_term_tag()]
