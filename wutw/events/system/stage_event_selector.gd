class_name StageEventSelector
extends RefCounted

const PROBABILITY_WEIGHTS: Dictionary[Event_Stage.Probability, float] = {
	# SHOULD BE SELECTED BEFORE WEIGHING: Event_Stage.Probability.LANDMARK
	Event_Stage.Probability.ALMOST_CERTAIN: 999999,
	Event_Stage.Probability.VERY_HIGH: 40,
	Event_Stage.Probability.HIGH: 7,
	Event_Stage.Probability.NORMAL: 1,
	Event_Stage.Probability.LOW: 0.333,
	Event_Stage.Probability.VERY_LOW: 0.1,
}
const WEIGHT_BOOST_PER_CHOOSABLE_CHOICE = 3.
const WEIGHT_BOOST_ACHIEVABLE_ON_GOAL = 8.
const WEIGHT_BOOST_ACHIEVABLE_RELIC_DURING_QUEST = 20.

var _upgrade_to_spot: Dictionary[SpotUpgrade, SpotType]
var _all_stage_events: Dictionary[SpotType, Array]  # Array[Event_Stage]

func _init() -> void:
	for spot_type in SpotType.get_all_spot_types():
		for upgrade in spot_type.upgrades:
			_add_to_spot_lookup(spot_type, upgrade)
		_all_stage_events[spot_type] = []

	for event: Event in Event.get_all_events().values():
		var stage_event := event as Event_Stage
		if stage_event:
			assert(stage_event.default_spot_upgrade)
			var spot_type := _upgrade_to_spot[stage_event.default_spot_upgrade]
			_all_stage_events[spot_type].append(stage_event)

func select_events(rng: RandomState, run: Run, spot_types: Array[SpotType], goal_types: Array[BonusType]) -> Dictionary[SpotUpgrade, Event_Stage]:
	var num_events_to_pick := maxi(0, run.get_var(RunVars.Var.MAX_EVENTS_PER_STAGE))
	if not num_events_to_pick:
		return {}

	var result: Dictionary[SpotUpgrade, Event_Stage]
	var conditional_event_weights: Dictionary[Event_Stage, float]

	var previous_spot_types: Array[SpotType]
	for spot_type in spot_types:
		for event: Event_Stage in _all_stage_events[spot_type]:
			if not event.is_requirement_satisfied(run):
				continue
			if not event.default_spot_upgrade.is_allowed(run, spot_type not in previous_spot_types):
				continue
			var probability := event.get_probability_weight(run)
			if probability == Event_Stage.Probability.LANDMARK:
				result[event.default_spot_upgrade] = event
			else:
				var weight := PROBABILITY_WEIGHTS[probability]
				var num_choosable := event.get_num_choosable_choices(run)
				if num_choosable:  # Not even goal boost if we can choose nothing (practically impossible).
					for goal_type in goal_types:
						if goal_type in event.default_spot_upgrade.granted_bonuses:
							weight *= WEIGHT_BOOST_ACHIEVABLE_ON_GOAL
							break
					# -1 for the exit choice, which is virtually always available.
					weight *= max(1, num_choosable - 1) * WEIGHT_BOOST_PER_CHOOSABLE_CHOICE
					# Make it easier to get relics during the early quest.
					if GlobalSaveGame.get_main_quest_progress() < SaveGame.MainQuestProgress.P115_GATHERED_RELICS:
						if _can_get_relic(event):
							weight *= WEIGHT_BOOST_ACHIEVABLE_RELIC_DURING_QUEST
				conditional_event_weights[event] = weight
		previous_spot_types.append(spot_type)

	for pinned: Event_Stage in GlobalSaveGame.get_pinned_events():
		if pinned in conditional_event_weights:
			result[pinned.default_spot_upgrade] = pinned
			num_events_to_pick -= 1
			rng.rand_float()  # Advance the RNG state to avoid affecting future rolls.
			if not num_events_to_pick:
				break

	for event: Event_Stage in conditional_event_weights.keys():
		if event.get_probability_weight(run) == Event_Stage.Probability.ALMOST_CERTAIN:
			if event.default_spot_upgrade not in result:
				result[event.default_spot_upgrade] = event
				num_events_to_pick -= 1
				rng.rand_float()  # Advance the RNG state to avoid affecting future rolls.
				if num_events_to_pick <= 0:
					break

	while conditional_event_weights and num_events_to_pick > 0:
		var event: Event_Stage = rng.pick_weighted_dict(conditional_event_weights)[0]
		if event.default_spot_upgrade not in result:
			result[event.default_spot_upgrade] = event
			num_events_to_pick -= 1
		conditional_event_weights.erase(event)

	return result

func _add_to_spot_lookup(spot_type: SpotType, upgrade: SpotUpgrade) -> void:
	_upgrade_to_spot[upgrade] = spot_type
	for child in upgrade.child_upgrades:
		_add_to_spot_lookup(spot_type, child)

func _can_get_relic(event: Event) -> bool:
	var run := Utils.get_active_run()
	if not event.steps:
		return false
	for choice in event.steps[0].choices:
		if not choice.requirement or choice.requirement.is_satisfied(run, event):
			# We can probably ignore EventOutcome_All for this.
			if choice.outcome is EventOutcome_AddRelic:
				return true
	return false
