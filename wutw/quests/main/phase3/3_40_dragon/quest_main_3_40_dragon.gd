@tool
class_name Quest_Main340_Dragon
extends Quest

@export var koi: Companion
@export var dragon: Companion
@export var end_dialogue: Dialogue
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.connect(_on_event_finished.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.disconnect(_on_event_finished.bind(instance, run))

func _on_event_finished(_event: Event, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if GlobalSaveGame.has_unlocked_companion(koi):
		instance.set_goal_finished(0)
	if GlobalSaveGame.has_unlocked_companion(dragon):
		instance.set_goal_finished(1)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P340_SUMMONED_DRAGON)
		instance.finish(next_quest)
		GlobalSaveGame.save_game()

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	if GlobalSaveGame.get_events_state().get_int_or_default('global', 'companion_koi', 0) < 3:
		# Ensure there's always at least one cliff and one lake while looking for the koi.
		config = config.duplicate(true)
		for stamp in config.stamp_configs:
			if stamp.comment in ['cliff', 'lake']:
				stamp.stamp_count_range.x = 1
	return config
