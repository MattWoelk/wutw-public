@tool
class_name Relic_MirrorInk
extends Relic

var triggered_this_stage: bool = false

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.stage_started.connect(_on_stage_started)
	_run.signals.card_slotted.connect(_on_card_slotted)

func on_removed() -> void:
	_run.signals.stage_started.disconnect(_on_stage_started)
	_run.signals.card_slotted.disconnect(_on_card_slotted)
	super.on_removed()

func _on_stage_started() -> void:
	triggered_this_stage = false
	_state = State.ACTIVE

func _on_card_slotted(card: Card, _aspect_slot: AspectSlot) -> void:
	if not triggered_this_stage and card.card_type.abilities:
		triggered_this_stage = true
		_run.run_or_queue_action(func() -> void:
			triggered.emit()
			await _run.get_current_stage().cast_card(card, true)
			_state = State.PASSIVE
		)
