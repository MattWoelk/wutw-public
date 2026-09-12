@tool
class_name Quest_Main130_Shrines
extends Quest

@export var forest_event: Event
@export var lake_event: Event
@export var end_dialogue: Dialogue
@export var next_quest: Quest

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.connect(_on_event_finished.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.disconnect(_on_event_finished.bind(instance, run))

func _on_event_finished(event: Event, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if event == forest_event:
		instance.set_goal_finished(0)
	if event == lake_event:
		instance.set_goal_finished(1)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		instance.finish(next_quest)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P130_ESTABLISHED_SHRINES)
		GlobalSaveGame.save_game()

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	config = config.duplicate(true)
	# Increase chance of forest (should virtually guarantee it).
	config.biome_config.min_moisture_for_forest = 0.5
	# Ensure there's always at least a couple of lakes.
	for stamp in config.stamp_configs:
		if stamp.comment == 'lake':
			stamp.stamp_count_range = Vector2(2, 5)
	return config
