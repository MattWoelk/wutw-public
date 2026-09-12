@tool
class_name Quest_Main310_Listen
extends Quest

@export var begin_dialogue: Dialogue
@export var end_dialogue: Dialogue
@export var singing_cascades: Event
@export var rocks_reply: Event
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.connect(_on_event_finished.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.disconnect(_on_event_finished.bind(instance, run))

func _on_event_finished(event: Event, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if event == singing_cascades:
		instance.set_goal_finished(0)
	elif event == rocks_reply:
		instance.set_goal_finished(1)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		instance.start()
		GlobalSaveGame.save_game()
	elif instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P310_ESTABLISHED_CONTACT)
		instance.finish(next_quest)
		GlobalSaveGame.save_game()

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# Ensure there's always at least one cliff/canyon.
	config = config.duplicate(true)
	for stamp in config.stamp_configs:
		if stamp.comment in ['cliff', 'canyon']:
			stamp.stamp_count_range.x = 1
	return config
