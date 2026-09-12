@tool
class_name CardAbility_Fill
extends CardAbility

@export var points: int = 1

func get_ability_name(markedup: bool = false, _short: bool = false) -> String:
	if markedup:
		return '<term:fill> %d' % points
	else:
		return tr('Fill', 'ABILITY') + ' ' + str(points)

func get_ability_tooltip(_card: Card) -> String:
	var result: String
	if points == 1:
		result = tr('<term:fill> a random <term_lower:aspect_slot> in a <term:spot_upgrade>')
		if Skill.get_skill_var(Skill.Var.SURVEYS):
			result += tr(' or <term:task>')
	else:
		result = tr('<term:fill> %d random <term_lower:aspect_slot>s in <term:spot_upgrade>s') % points
		if Skill.get_skill_var(Skill.Var.SURVEYS):
			result += tr(' or <term:task>s')
	return result + tr('.')

func get_term() -> Term:
	return load('res://cards/abilities/terms/term_card_ability_fill.tres')

func cast(_card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var slots_filled := [0]  # Array, so we can capture it.
	var error_shown := [false]  # Array, so we can capture it.
	for _i in range(points + run.get_var(RunVars.Var.FILL_ABILITY_BONUS)):
		stage.queue_action(func() -> void:
			var aspect_slots_availability := stage.get_aspect_slots_availability()
			var pool: Array[AspectSlot] = []
			for aspect_slot in aspect_slots_availability:
				if aspect_slots_availability.get(aspect_slot):
					pool.append(aspect_slot)
			if pool:
				var slot := stage.get_card_deck().get_random_state().pick(pool) as AspectSlot
				await stage.ensure_slot_visible(slot)
				await slot.animate_fill()
				slots_filled[0] += 1
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
	return 10 + 8 * (points - 1)
