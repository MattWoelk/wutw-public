@tool
class_name Quest_Settler
extends Quest

@export_multiline var intro_text: String
@export var challenges: Array[SettlerQuestChallenge]
@export var settler_goals: Array[SettlerQuestGoal]
@export var rewards: Array[SettlerQuestReward]

@export_group('Selection')
@export var restrict_to_jobs: Array[Job]
@export var exclude_jobs: Array[Job]
@export var restrict_to_ages: Array[HubCharacterSpec.Age]
@export var min_main_quest: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO

const BASE_MAX_QUESTS := 5
const INSIGHT_BONUS_PERCENT := 10
const STATE_MODIFIERS_APPLIED := 110

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	assert(run)
	if instance.get_state() < STATE_MODIFIERS_APPLIED:
		assert(instance.get_state() == QuestInstance.STATE_ACTIVE)
		var mod_tag := quest_id + '-insights'
		run.get_vars().add_modifier(RunVars.Var.INSIGHT_EXTRA_PERCENT, INSIGHT_BONUS_PERCENT, mod_tag)
		for challenge in challenges:
			challenge.apply_starting_modifiers(self, run)
		instance.update_progress(STATE_MODIFIERS_APPLIED)
	for challenge in challenges:
		challenge.start_listening(run)
	for settler_goal in settler_goals:
		settler_goal.start_listening(run)
		settler_goal.achieved.connect(_on_goal_achieved.bind(instance, settler_goal))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	assert(run)
	for challenge in challenges:
		challenge.stop_listening(run)
	for settler_goal in settler_goals:
		settler_goal.stop_listening(run)
		settler_goal.achieved.disconnect(_on_goal_achieved.bind(instance, settler_goal))

func get_decorated_goals() -> Array[String]:
	var result: Array[String]
	for settler_goal in settler_goals:
		result.append(settler_goal.describe())
	return result

func _on_goal_achieved(instance: QuestInstance, settler_goal: SettlerQuestGoal) -> void:
	if instance.get_state() < QuestInstance.STATE_READY_TO_FINISH:  # Can be triggered while receiving reward.
		instance.set_goal_finished(settler_goals.find(settler_goal))
		if instance.is_ready_to_finish():
			GlobalSaveGame.mark_settler_quest_completed(self)
			instance.finish(null)  # Quest finished notification will handle reward.

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	var result: Array[SpotUpgrade]
	for goal in settler_goals:
		result.append_array(goal.get_ensured_upgrades())
	return result
