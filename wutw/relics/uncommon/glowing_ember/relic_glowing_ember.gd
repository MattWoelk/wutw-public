@tool
class_name Relic_GlowingEmber
extends Relic

@export var aspect: AspectType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.aspect_slot_filled.connect(_on_slot_filled)

func on_removed() -> void:
	_run.signals.aspect_slot_filled.disconnect(_on_slot_filled)
	super.on_removed()

func _on_slot_filled(aspect_slot: AspectSlot) -> void:
	if aspect_slot.aspect_type == aspect:
		_run.run_or_queue_action(func() -> void:
			if not _run.get_current_stage():
				return  # Sometimes capital slots on the map get filled outside of a stage.
			triggered.emit()
			await _run.get_current_stage().get_card_deck().draw(CardDeck.CardDrawReason.RELIC, true)
		)
