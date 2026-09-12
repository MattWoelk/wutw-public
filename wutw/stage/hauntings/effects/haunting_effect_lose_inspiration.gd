@tool
class_name HauntingEffect_LoseInspiration
extends HauntingEffect

@export var base_amount: int = 1
@export var extra_amount_per_season: int = 1

func get_description(_mode: HauntingTrigger.Mode) -> String:
	var amount := base_amount
	var run := Utils.get_active_run()
	if run:
		amount += run.get_current_season_index() * extra_amount_per_season
	return tr('lose %d <term:inspiration>') % amount

func get_short_description(_mode: HauntingTrigger.Mode) -> String:
	var amount := base_amount
	var run := Utils.get_active_run()
	if run:
		amount += run.get_current_season_index() * extra_amount_per_season
	return tr('Lose %d <term:inspiration>') % amount

func scales() -> bool:
	return extra_amount_per_season != 0

func triggered(_related_gain: BonusGain, _related_slot: AspectSlot, _related_card: CardType) -> void:
	var run := Utils.get_active_run()
	var stage := run.get_current_stage()
	var amount := base_amount + run.get_current_season_index() * extra_amount_per_season
	stage.queue_action(func() -> void:
		run.modify_inspiration(-amount, Run.InspirationChangeReason.HAUNTING)
		await run.get_tree().create_timer(Utils.anim_duration(0.3)).timeout
	)
