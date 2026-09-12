@tool
class_name HauntingEffect_LoseGoal
extends HauntingEffect

@export var base_amount: int = 5
@export var extra_amount_per_season: int = 5

func get_description(_mode: HauntingTrigger.Mode) -> String:
	var amount := base_amount
	var run := Utils.get_active_run()
	if run:
		amount += run.get_current_season_index() * extra_amount_per_season
	return tr('lose %d of a random <term_lower:stage_goal>') % amount

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	var amount := base_amount
	var run := Utils.get_active_run()
	if run:
		amount += run.get_current_season_index() * extra_amount_per_season
	return tr('Lose %d Goal Yield') % amount

func scales() -> bool:
	return extra_amount_per_season != 0

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var goal := stage.get_goal()
	assert(goal)  # Assume convergence can't be haunted.
	var bonus_type := run.get_events_random().pick(goal.bonus_requirements.keys()) as BonusType
	var amount := base_amount + run.get_current_season_index() * extra_amount_per_season
	stage.queue_action(func() -> void:
		run.gain_bonus(BonusGain.new(bonus_type, -amount, self))
		await run.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
	)
