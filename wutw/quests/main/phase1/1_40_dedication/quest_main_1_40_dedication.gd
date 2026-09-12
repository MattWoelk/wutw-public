@tool
class_name Quest_Main140_Dedication
extends Quest

@export var bonus_type: BonusType
@export var bonus_amount: int = 150
@export var monasteries: Array[SpotUpgrade]
@export var end_dialogue: Dialogue

const STATE_PROMPT_SHOWN := 210

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.bonus_gained.connect(_on_bonus_gained.bind(instance, run))
	run.signals.spot_recipe_activated.connect(_on_spot_recipe_activated.bind(instance, run))
	run.state_changed.connect(_on_run_state_changed.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.bonus_gained.disconnect(_on_bonus_gained.bind(instance, run))
	run.signals.spot_recipe_activated.disconnect(_on_spot_recipe_activated.bind(instance, run))
	run.state_changed.disconnect(_on_run_state_changed.bind(instance, run))

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	var result: Array[SpotUpgrade] = monasteries.duplicate()
	for spot_upgrade in SpotUpgrade.get_all_spot_upgrades():
		if bonus_type in spot_upgrade.granted_bonuses:
			result.append(spot_upgrade)
	return result

func _on_bonus_gained(_gained_type: BonusType, _amount: int, _reason: BonusGain.Reason, instance: QuestInstance, run: Run) -> void:
	assert(instance)
	if instance.get_state() < STATE_PROMPT_SHOWN:
		if run.get_bonus_amounts().get_amount(bonus_type) >= bonus_amount:
			instance.set_goal_finished(0)
			_maybe_show_prompt(instance)
		else:
			instance.set_goal_unfinished(0)

func _on_spot_recipe_activated(spot_recipe: SpotRecipe, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if spot_recipe.spot_upgrade in monasteries:
		instance.set_goal_finished(1)
		_maybe_show_prompt(instance)

func _on_run_state_changed(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	if instance.is_finished():
		return
	if run.get_state() in [RunData.State.RUN_LOST, RunData.State.RUN_WON]:
		if instance.is_ready_to_finish():
			GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P140_DEDICATED_STATUE)
			instance.finish(null)  # Main quest progress will trigger a cutscene.
		else:
			instance.set_goal_unfinished(0)
			instance.set_goal_unfinished(1)

func _maybe_show_prompt(instance: QuestInstance) -> void:
	if instance.is_ready_to_finish() and instance.get_state() < STATE_PROMPT_SHOWN:
		instance.update_progress(STATE_PROMPT_SHOWN)
		await GlobalUI.show_dialogue(end_dialogue)
