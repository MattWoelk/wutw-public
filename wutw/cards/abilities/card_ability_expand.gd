@tool
class_name CardAbility_Expand
extends CardAbility

@export var count: int = 1

func get_ability_name(_markedup: bool = false, _short: bool = false) -> String:
	if count > 0:
		return tr('Expand', 'ABILITY') + ' ' + str(count)
	elif count < 0:
		return tr('Shrink', 'ABILITY') + ' ' + str(-count)
	else:
		Utils.ensure(false)
		return ''

func get_ability_tooltip(_card: Card) -> String:
	if count > 0:
		return (tr('Increase your <term:hand_size> by %d for the rest of the <term:stage>.')
		 		% count)
	elif count < 0:
		return (tr('Reduce your <term:hand_size> by %d for the rest of the <term:stage>.')
		 		% -count)
	else:
		Utils.ensure(false)
		return ''

func get_term() -> Term:
	if count > 0:
		return load('res://cards/abilities/terms/term_card_ability_expand.tres')
	elif count < 0:
		return load('res://cards/abilities/terms/term_card_ability_shrink.tres')
	else:
		Utils.ensure(false)
		return null

func cast(_card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.add_modifier(RunVars.Var.HAND_SIZE, count)
	await stage.get_card_deck().animated_hand_size_change(count > 0)

func estimate_power(_card_type: CardType) -> int:
	return 5 + 11 * count
