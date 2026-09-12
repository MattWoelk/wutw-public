@tool
class_name CardAbility_Gain
extends CardAbility

@export var bonus_type: BonusType
@export var points: int = 1

func get_ability_name(markedup: bool = false, short: bool = false) -> String:
	if markedup:
		if short:
			if points > 0:
				return tr('Gain', 'ABILITY') + ' %d [img width=1.25em height=1.25em]%s[/img]' % [points, bonus_type.icon.resource_path]
			else:
				return tr('Lose', 'ABILITY') + ' %d [img width=1.25em height=1.25em]%s[/img]' % [-points, bonus_type.icon.resource_path]
		else:
			if points > 0:
				return tr('Gain', 'ABILITY') + ' %d %s' % [points, bonus_type.get_term_tag()]
			else:
				return tr('Lose', 'ABILITY') + ' %d %s' % [-points, bonus_type.get_term_tag()]
	else:
		if points > 0:
			return '%s +%d' % [tr(bonus_type.name), points]
		else:
			return '%s %d' % [tr(bonus_type.name), points]

func get_ability_tooltip(_card: Card) -> String:
	if points > 0:
		return tr('Gain %d points of %s.') % [points, bonus_type.get_term_tag()]
	else:
		return tr('Lose %d points of %s.') % [-points, bonus_type.get_term_tag()]

func get_term() -> Term:
	if points > 0:
		return load('res://cards/abilities/terms/term_card_ability_gain.tres')
	else:
		return load('res://cards/abilities/terms/term_card_ability_lose.tres')

func cast(card: Card) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.gain_bonus(BonusGain.new(bonus_type, points, card))
		await run.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
	)

func estimate_power(_card_type: CardType) -> int:
	return roundi(points * 0.8)

func scales_when_looped() -> bool:
	return points > 0

func get_search_text() -> String:
	return '%s %d %s ' % [tr('Gain', 'ABILITY') if points > 0 else tr('Lose', 'ABILITY'), points, tr(bonus_type.name)]
