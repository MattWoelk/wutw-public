@tool
class_name Quest_Main230_Consecration
extends Quest

@export var num_seasons_required: int = 3
@export var end_dialogue: Dialogue
@export var field_event: Event
@export var lanterns_event: Event
@export var glade_event: Event
@export var no_sea_texture: Texture2D

func on_run_entered(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.connect(_on_event_finished.bind(instance, run))
	run.state_changed.connect(_on_state_changed.bind(instance, run))

func on_run_exited(instance: QuestInstance, run: Run) -> void:
	run.signals.event_finished.disconnect(_on_event_finished.bind(instance, run))
	run.state_changed.disconnect(_on_state_changed.bind(instance, run))

func _on_event_finished(event: Event, instance: QuestInstance, _run: Run) -> void:
	assert(instance)
	if instance.is_finished():
		return

	if event == field_event:
		instance.set_goal_finished(1)
	elif event == lanterns_event:
		instance.set_goal_finished(2)
	elif event == glade_event:
		instance.set_goal_finished(3)

	if instance.is_goal_completed(1) and instance.is_goal_completed(2) and instance.is_goal_completed(3):
		instance.set_goal_finished(0)
		_check_finished(instance)

func _on_state_changed(instance: QuestInstance, run: Run) -> void:
	assert(instance)
	if instance.is_finished():
		return
	if (instance.get_state() == QuestInstance.STATE_ACTIVE
			and run.get_state() == RunData.State.STAGE_SELECTOR
			and run.get_current_season_index() >= num_seasons_required):
		instance.set_goal_finished(4)
		_check_finished(instance)

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	_reset_if_unfinished(instance)

func _reset_if_unfinished(instance: QuestInstance) -> void:
	# Must be finished in one run.
	if not instance.is_ready_to_finish():
		for i in goals.size():
			instance.set_goal_unfinished(i)

func _check_finished(instance: QuestInstance) -> void:
	if instance.is_ready_to_finish():
		await GlobalUI.show_dialogue(end_dialogue)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P230_PREPARED_RITUAL)
		instance.finish(null)
		GlobalSaveGame.save_game()

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	config = config.duplicate(true)
	# Ensure there's always a sea.
	config.input_textures = config.input_textures.duplicate()
	if Utils.ensure(config.input_textures.basemap_configs.size() > 1):
		for basemap_config in config.input_textures.basemap_configs:
			Utils.ensure(basemap_config.texture_altitude.erase(no_sea_texture))
	# Increase chance of forest (should virtually guarantee it).
	config.biome_config.min_moisture_for_forest = 0.5
	# Reset relevant factors to defaults to override pinned shard.
	config.biome_config.max_moisture_for_brushland = 0.45
	config.biome_config.max_temperature_for_brushland = 0.6
	config.biome_config.max_moisture_for_dry_biome = 0.32
	config.biome_config.min_temperature_for_desert = 0.5
	return config
