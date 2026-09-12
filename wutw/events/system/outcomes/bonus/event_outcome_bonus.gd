@tool
class_name EventOutcome_Bonus
extends EventOutcome

static var WIDGET_SCENE := AsyncLoadedResource.new('res://events/system/outcomes/bonus/event_outcome_widget_bonus.tscn', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var bonus_type: BonusType
@export var amount: int
@export var extra_per_season: int = 0

func apply(event: Event) -> EventOutcomeWidget:
	assert(bonus_type)
	assert(amount != 0)
	var widget := WIDGET_SCENE.instantiate_loaded_scene() as EventOutcomeWidget_Bonus
	widget.bonus_type = bonus_type
	widget.amount = amount
	widget.extra_per_season = extra_per_season
	widget.event = event
	return widget

func describe(run: Run) -> String:
	var effective_amount := amount
	if run:
		effective_amount += extra_per_season * run.get_current_season_index()
	if effective_amount > 0:
		return tr('Get %d %s') % [effective_amount, bonus_type.get_term_tag()]
	else:
		return tr('Lose %d %s') % [-effective_amount, bonus_type.get_term_tag()]
