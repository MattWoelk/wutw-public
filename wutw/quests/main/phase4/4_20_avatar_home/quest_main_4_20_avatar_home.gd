@tool
class_name Quest_Main420_AvatarHome
extends Quest

@export var begin_dialogue: Dialogue
@export var avatar_home_shard_type: ShardType
@export var next_quest: Quest
@export var ensured_upgrades: Array[SpotUpgrade]

func on_hub_entered(instance: QuestInstance, _hub: Hub) -> void:
	if instance.get_state() == QuestInstance.STATE_INACTIVE:
		await GlobalUI.show_dialogue(begin_dialogue)
		instance.start()
		GlobalSaveGame.save_game()

	if GlobalSaveGame.get_past_run_by_shard_type(avatar_home_shard_type):
		instance.set_goal_finished(0)
		GlobalSaveGame.set_main_quest_progress(SaveGame.MainQuestProgress.P420_SENT_OFF_KID)
		instance.finish(next_quest, false)
		GlobalSaveGame.save_game()

func apply_map_generation_override(config: MapGenerationConfig) -> MapGenerationConfig:
	# Ensure there are ruins in brushlands/forest with no small buildings.
	var stamp_config := MapStampConfig.new()
	stamp_config.comment = 'avatar_home_spot'
	stamp_config.stamp_count_range = Vector2i(1, 2)
	stamp_config.radius = 10
	stamp_config.allowed_biomes.append(MapBiomes.BRUSHLAND)
	stamp_config.allowed_biomes.append(MapBiomes.FOREST)
	stamp_config.sprite_types.append(load('res://map/sprites/buildings/ruin_large/mst_ruin_large_1.tres'))
	stamp_config.sprite_types.append(load('res://map/sprites/buildings/ruin_large/mst_ruin_large_2.tres'))
	stamp_config.sprite_types.append(load('res://map/sprites/buildings/ruin_large/mst_ruin_large_3.tres'))
	stamp_config.sprite_types.append(load('res://map/sprites/buildings/ruin_large/mst_ruin_large_4.tres'))
	stamp_config.seed_sprite_type = load('res://map/sprites/buildings/ruined_square/mst_town_square_1.tres') as MapSpriteType
	stamp_config.sprite_count_range = Vector2i(2, 3)
	config = config.duplicate(true)
	config.stamp_configs.append(stamp_config)
	return config

func get_ensured_upgrades() -> Array[SpotUpgrade]:
	return ensured_upgrades
