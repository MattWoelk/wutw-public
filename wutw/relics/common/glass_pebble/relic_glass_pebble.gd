@tool
class_name Relic_GlassPebble
extends Relic

@export var triggering_aspect_type: AspectType

func on_added(run: Run, apply_modifiers: bool) -> void:
	super.on_added(run, apply_modifiers)
	_run.signals.aspect_slot_filled.connect(_on_aspect_slot_filled)

func on_removed() -> void:
	_run.signals.aspect_slot_filled.disconnect(_on_aspect_slot_filled)
	super.on_removed()

func _on_aspect_slot_filled(aspect_slot: AspectSlot) -> void:
	if triggering_aspect_type != aspect_slot.aspect_type:
		return

	var is_acceptable: Callable = func(card_type: CardType) -> bool:
		return triggering_aspect_type in card_type.aspects
	var tier_weights := _run.get_current_card_reward_weights()
	var choices := Utils.choose_card_rewards(_run, tier_weights, 1, true, is_acceptable, false)
	if not Utils.ensure(not choices.is_empty()):
		return

	_run.run_or_queue_action(func() -> void:
		var stage := _run.get_current_stage()
		if Utils.ensure(stage != null):
			triggered.emit()
			await stage.get_card_deck().add_card_to_hand(choices[0], CardDeck.CardDrawReason.RELIC)
	)

func get_description() -> String:
	return tr(default_description) % [
		triggering_aspect_type.get_term_tag(), triggering_aspect_type.get_term_tag()]
