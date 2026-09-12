@abstract
class_name SettlerQuestReward
extends Resource

@abstract func grant(_quest: Quest_Settler, run: Run) -> EventOutcomeWidget
@abstract func describe() -> String

func _get_mod_tag(quest: Quest_Settler) -> String:
	# Duplicate quests are disallowed, so this is safe.
	return '%s_reward_%d' % [quest.quest_id, quest.rewards.find(self)]
