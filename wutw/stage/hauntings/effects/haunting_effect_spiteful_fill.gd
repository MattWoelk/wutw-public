@tool
class_name HauntingEffect_SpitefulFill
extends HauntingEffect

func get_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('<term_lower:fill> a random <term_lower:aspect_slot>')

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	return tr('Fill Random')

func scales() -> bool:
	return false

func triggered(_related_gain: BonusGain, related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()

	stage.queue_action(func() -> void:
		var original_spot := Utils.get_typed_ancestor(related_slot, Spot) as Spot
		var aspect_slots_availability := stage.get_aspect_slots_availability()
		var pool: Array[AspectSlot] = []
		var pool_preferred: Array[AspectSlot] = []
		for aspect_slot in aspect_slots_availability:
			if aspect_slots_availability.get(aspect_slot):
				var owner_spot := Utils.get_typed_ancestor(aspect_slot, Spot)
				if owner_spot and owner_spot != original_spot:
					pool_preferred.append(aspect_slot)
				else:
					pool.append(aspect_slot)
		# TODO: Prefer slots which activate dead-end recipes that don't contribute to goals.
		if not pool_preferred and not pool:
			return

		var slot := stage.get_card_deck().get_random_state().pick(pool_preferred if pool_preferred else pool) as AspectSlot
		await stage.ensure_slot_visible(slot)
		await slot.animate_fill()
	)
