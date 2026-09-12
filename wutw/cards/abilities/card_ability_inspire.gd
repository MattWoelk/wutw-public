@tool
class_name CardAbility_Inspire
extends CardAbility

@export var points: int = 1

func get_ability_name(markedup: bool = false, _short: bool = false) -> String:
	if points > 0:
		return tr('Inspire', 'ABILITY') + ' %d' % points + ('[img width=1.25em height=1.25em]res://run/inspiration.png[/img]' if markedup else '')
	else:
		return tr('Despair', 'ABILITY') + ' %d' % -points + ('[img width=1.25em height=1.25em]res://run/inspiration.png[/img]' if markedup else '')

func get_ability_tooltip(_card: Card) -> String:
	if points > 0:
		return tr_n(
			'Restore %d point of <term_lower:inspiration>.',
			'Restore %d points of <term_lower:inspiration>.',
			points
		) % points
	else:
		return tr_n(
			'Lose %d point of <term_lower:inspiration>.',
			'Lose %d points of <term_lower:inspiration>.',
			-points
		) % -points

func get_term() -> Term:
	if points > 0:
		return load('res://cards/abilities/terms/term_card_ability_inspire.tres')
	else:
		return load('res://cards/abilities/terms/term_card_ability_despair.tres')

func cast(_card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.modify_inspiration(points, Run.InspirationChangeReason.ABILITY)
		await run.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
	)

func estimate_power(_card_type: CardType) -> int:
	return roundi((5.0 if points > 0 else 3.0) * points)

func scales_when_looped() -> bool:
	return points > 0
