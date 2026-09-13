@tool
class_name HauntingEffect_LoseBonus
extends HauntingEffect

@export var bonus_type: BonusType
@export var base_amount: int = 5
@export var extra_amount_per_season: int = 5

func get_description(_mode: HauntingTrigger.Mode) -> String:
	var amount := base_amount
	var run := Utils.get_active_run()
	if run:
		amount += run.get_current_season_index() * extra_amount_per_season
	return tr('lose %d %s') % [amount, bonus_type.get_term_tag()]

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	var amount := base_amount
	var run := Utils.get_active_run()
	if run:
		amount += run.get_current_season_index() * extra_amount_per_season
	return (tr('Lose %d') % amount) + ' [img width=1.5em height=1.5em]%s[/img]' % [bonus_type.icon.resource_path]

func scales() -> bool:
	return extra_amount_per_season != 0

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var amount := base_amount + run.get_current_season_index() * extra_amount_per_season
	var stage := run.get_current_stage()
	stage.queue_action(func() -> void:
		run.gain_bonus(BonusGain.new(bonus_type, -amount, self))
		await run.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
	)
