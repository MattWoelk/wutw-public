@abstract
class_name SettlerQuestChallenge
extends Resource

func apply_starting_modifiers(_quest: Quest_Settler, _run: Run) -> void:
	pass

func start_listening(_run: Run) -> void:
	pass

func stop_listening(_run: Run) -> void:
	pass

@abstract func describe() -> String

func _get_mod_tag(quest: Quest_Settler) -> String:
	# Duplicate quests are disallowed, so this is safe.
	return '%s_challenge_%d' % [quest.quest_id, quest.challenges.find(self)]
