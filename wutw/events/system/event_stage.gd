@tool
class_name Event_Stage
extends Event

enum Probability { LANDMARK, ALMOST_CERTAIN, VERY_HIGH, HIGH, NORMAL, LOW, VERY_LOW }
enum Repeatability { ONCE_EVER, ONCE_PER_RUN, ONCE_PER_STAGE }

@export var default_probability_weight: Probability = Probability.NORMAL
@export var default_spot_upgrade: SpotUpgrade
@export var repeatability: Repeatability = Repeatability.ONCE_PER_RUN

@warning_ignore('unused_parameter')
func get_probability_weight(run: Run) -> Probability:
	return default_probability_weight

func should_mark_all_choices_seen() -> bool:
	return repeatability == Repeatability.ONCE_EVER

func get_applicable_spot_upgrades() -> Array[SpotUpgrade]:
	return [default_spot_upgrade]

func is_requirement_satisfied(run: Run) -> bool:
	if repeatability == Repeatability.ONCE_PER_RUN:
		if run.get_events_state().get_int_or_default(event_id, Event.TRIGGERED_STAGE_INDEX_VAR, -1) != -1:
			return false
	elif repeatability == Repeatability.ONCE_EVER:
		if GlobalSaveGame.get_events_state().get_bool_or_default(event_id, Event.TRIGGERED_EVER_VAR, false):
			return false
	return super.is_requirement_satisfied(run)

func get_associated_landmark() -> ShopType:
	if default_probability_weight != Probability.LANDMARK:
		return null
	for step in steps:
		for choice in step.choices:
			var shop_type := _find_landmark_outcome(choice.outcome)
			if shop_type:
				return shop_type
	push_warning('Could not find associated landmark for event: ' + event_id)
	return null

func _find_landmark_outcome(outcome: EventOutcome) -> ShopType:
	if outcome is EventOutcome_UnlockShop:
		return (outcome as EventOutcome_UnlockShop).shop_type
	elif outcome is EventOutcome_All:
		for suboutcome: EventOutcome in (outcome as EventOutcome_All).suboutcomes:
			var shop_type := _find_landmark_outcome(suboutcome)
			if shop_type:
				return shop_type
	return null

func get_search_text() -> Array[String]:
	var result := super.get_search_text()
	if Utils.ensure(default_spot_upgrade != null):
		result.append(tr(default_spot_upgrade.name))
	return result
