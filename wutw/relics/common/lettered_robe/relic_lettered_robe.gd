@tool
class_name Relic_LetteredRobe
extends Relic

@export var min_strokes_to_trigger: int = 10
@export var bonus_type: BonusType
@export var amount_gained: int = 10

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.card_slotted.connect(_on_card_played)

func on_removed() -> void:
	_run.signals.card_slotted.disconnect(_on_card_played)
	super.on_removed()

func _on_card_played(card: Card, _aspect_slot: AspectSlot) -> void:
	var total_strokes := 0
	for count: int in Stroke.get_strokes_for_kanji(card.card_type.symbol).values():
		total_strokes += count
	if total_strokes >= min_strokes_to_trigger:
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			_run.gain_bonus(BonusGain.new(bonus_type, amount_gained, self))
			await _brief_wait()
		)

func get_description() -> String:
	return tr(default_description) % [min_strokes_to_trigger, amount_gained, bonus_type.get_term_tag()]
