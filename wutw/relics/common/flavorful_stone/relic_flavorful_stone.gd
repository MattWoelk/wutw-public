@tool
class_name Relic_FlavorfulStone
extends Relic

@export var triggering_bonus: BonusType
@export var amount_required: int = 10

var _amount_gained := 0

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.redraw_finished.connect(_on_redraw_finished)
	_run.signals.bonus_gained.connect(_on_bonus_gained)

func on_removed() -> void:
	_run.signals.redraw_finished.disconnect(_on_redraw_finished)
	_run.signals.bonus_gained.disconnect(_on_bonus_gained)
	super.on_removed()

func get_current_counter() -> int:
	return mini(_amount_gained, amount_required)

func get_max_counter() -> int:
	return amount_required

func _on_bonus_gained(bonus_type: BonusType, amount: int, _reason: BonusGain.Reason) -> void:
	if bonus_type == triggering_bonus:
		_amount_gained += amount
		counter_changed.emit()

func _on_redraw_finished(is_first: bool) -> void:
	if _amount_gained >= amount_required and not is_first:
		_run.run_or_queue_action(func() -> void:
			_run.get_current_stage().get_card_deck().draw(CardDeck.CardDrawReason.RELIC, true)
			triggered.emit()
			await _brief_wait()
		)

	_amount_gained = 0
	counter_changed.emit()

func get_description() -> String:
	return tr(default_description) % [amount_required, triggering_bonus.get_term_tag()]
