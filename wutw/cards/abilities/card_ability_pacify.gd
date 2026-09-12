@tool
class_name CardAbility_Pacify
extends CardAbility

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	return (tr('Mitigate', 'ABILITY') if Utils.is_realistic_era() else tr('Pacify', 'ABILITY')) + ' ' + str(count)

func get_ability_tooltip(_card: Card) -> String:
	if count == 1:
		return tr('<term:fill> a random <term_lower:aspect_slot> in a <term:haunting>.')
	else:
		return tr('<term:fill> %d random <term_lower:aspect_slot>s in <term:haunting>s.') % count

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_pacify.tres')

func cast(_card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var slots_filled := [0]  # Array, so we can capture it.
	var error_shown := [false]  # Array, so we can capture it.
	for _i in range(count + run.get_var(RunVars.Var.FILL_ABILITY_BONUS)):
		stage.queue_action(func() -> void:
			var aspect_slots_availability := stage.get_aspect_slots_availability()
			var pool: Array[AspectSlot] = []
			for haunting in stage.get_hauntings():
				for slot in haunting.get_aspect_slots():
					if aspect_slots_availability.get(slot):
						pool.append(slot)
			if pool:
				var slot := stage.get_card_deck().get_random_state().pick(pool) as AspectSlot
				await stage.ensure_slot_visible(slot)
				await slot.animate_fill()
			else:
				if not error_shown[0]:
					if slots_filled[0]:
						GlobalUI.show_error(tr('Ran out of <term_lower:aspect_slot>s to fill after %d.') % slots_filled[0])
					else:
						GlobalUI.show_error(tr('No valid <term_lower:aspect_slot>s to fill.'))
					error_shown[0] = true
					await run.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
		)

func estimate_power(_card_type: CardType) -> int:
	return 7 * count

func get_search_text() -> String:
	return ' '.join([tr('Pacify', 'ABILITY'), tr('Mitigate', 'ABILITY'), str(count)])
