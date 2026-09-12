@tool
class_name MuseumDetail_Relic
extends Control

static var RELIC_POOL_OUTCOME := AsyncLoadedResource.new('res://events/landmark/endless_ruin/endless_ruin_relics.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var relic: Relic:
	set(value):
		if relic == value:
			return
		relic = value
		if is_node_ready():
			_recreate()

var include_undiscovered: bool = true

func _ready() -> void:
	_update_font_size()
	GlobalGameSettings.changed.connect(_update_font_size)
	_recreate()

func _update_font_size() -> void:
	Utils._scale_font_size(%MainText as RichTextLabel, false, 18)

func _recreate() -> void:
	if not relic:
		return

	var description: String
	if Utils.is_in_editor() or GlobalSaveGame.has_seen_relic(relic):
		(%TitleLabel as Label).text = relic.get_relic_name()
		(%Illustration as TextureRect).texture = relic.icon
		description = relic.get_markedup_description()
		description += '\n\n'
	else:
		(%TitleLabel as Label).text = tr('???')
		(%Illustration as TextureRect).texture = null
	if relic.rarity == Relic.Rarity.UNCOMMON:
		(%TitleLabel as Label).text += tr(' (Uncommon)')
	elif relic.rarity == Relic.Rarity.RARE:
		(%TitleLabel as Label).text += tr(' (Rare)')
	elif relic.rarity == Relic.Rarity.ACT_REWARD:
		(%TitleLabel as Label).text += tr(' (Phase Reward)')

	var sources := _get_relic_sources()
	if sources:
		description += '[ul]' + '\n'.join(sources) + '[/ul]'

	(%MainText as MarkedUpLabel).set_markedup_text(description.strip_edges(), MarkedUpLabel.LinkMode.LINK)

func _get_relic_sources() -> Array[String]:
	var result: Array[String]

	if relic.rarity == Relic.Rarity.ACT_REWARD:
		result.append(tr('Can be offered at the end of a <term:harmonization>.'))

	for event: Event in Event.get_all_events().values():
		if _event_grants_this_relic(event):
			result.append(tr('Can be obtained from the <term_lower:event>: <event:%s>.') % event.event_id)

	for episode: SurveyEpisode in SurveyEpisode.get_all_episodes().values():
		if _survey_grants_this_relic(episode):
			result.append(tr('Can be obtained from the <term_lower:survey> <term_lower:encounter>: <encounter:%s>.') % episode.episode_id)

	var relics_pool := (RELIC_POOL_OUTCOME.get_loaded() as EventOutcome_ChooseRelic).relic_choice_pool
	if relic in relics_pool:
		result.append(tr('Can be obtained at the <shop:get_relics> <term_lower:shop>.'))

	if include_undiscovered or Utils.is_explorer_trips_unlocked():
		var random_trip_rewards := load('res://hub/trip/random_trip_rewards.tres') as RandomTripRewards
		var unlocked_from_trips := false
		for reward: TripReward in random_trip_rewards.rewards.values():
			if reward.unlocked_relic == relic:
				unlocked_from_trips = true
				break
		if not unlocked_from_trips:
			for shard_type: ShardType in ShardType.get_all_shard_types().values():
				if shard_type.trip_reward and shard_type.trip_reward.unlocked_relic == relic:
					unlocked_from_trips = true
					break
				for reward_override in shard_type.trip_reward_overrides:
					if reward_override.trip_reward.unlocked_relic == relic:
						unlocked_from_trips = true
						break
				if unlocked_from_trips:
					break
		if unlocked_from_trips:
			result.append(tr('Can be unlocked through <term:explorer_trip>s and selected as a starting relic.'))

	if include_undiscovered or Utils.is_settler_questing_unlocked():
		for quest: Quest in Quest.get_all_quests().values():
			if quest is Quest_Settler:
				for reward in (quest as Quest_Settler).rewards:
					if reward is SettlerQuestReward_AddRelic:
						if (reward as SettlerQuestReward_AddRelic).relic == relic:
							result.append(tr('Can be obtained from the <term_lower:settler_quest> <quest:%s>.') % quest.quest_id)
					elif reward is SettlerQuestReward_ChooseRelic:
						for relic_choice in (reward as SettlerQuestReward_ChooseRelic).relic_choice_pool:
							if relic_choice == relic:
								result.append(tr('Can be obtained from the <term_lower:settler_quest> <quest:%s>.') % quest.quest_id)
								break

	return result

func _event_grants_this_relic(event: Event) -> bool:
	var _bonuses: Array[BonusType]
	var _cards: Array[CardType]
	var relics: Array[Relic]
	var _shop_types: Array[ShopType]
	for step in event.steps:
		for choice in step.choices:
			EventChoice.collect_outcome_details(event, choice, choice.outcome, _bonuses, _cards, relics, _shop_types, include_undiscovered)
		if step.exit_choice:
			EventChoice.collect_outcome_details(event, step.exit_choice, step.exit_choice.outcome, _bonuses, _cards, relics, _shop_types, include_undiscovered)
		if relic in relics:
			return true
	return false

func _survey_grants_this_relic(episode: SurveyEpisode) -> bool:
	for choice in episode.choices:
		if _survey_outcome_grants_this_relic(choice.outcome):
			return true
	return false

func _survey_outcome_grants_this_relic(outcome: EventOutcome) -> bool:
	if outcome is EventOutcome_AddRelic:
		if (outcome as EventOutcome_AddRelic).relic == relic:
			return true
	elif outcome is EventOutcome_All:
		for suboutcome in (outcome as EventOutcome_All).suboutcomes:
			if _survey_outcome_grants_this_relic(suboutcome):
				return true
	elif outcome is EventOutcome_Random:
		for suboutcome in (outcome as EventOutcome_Random).suboutcomes:
			if _survey_outcome_grants_this_relic(suboutcome):
				return true
	return false
