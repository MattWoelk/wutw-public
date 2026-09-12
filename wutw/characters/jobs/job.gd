class_name Job
extends Resource

@export var job_name: String
@export var female_job_name_override: String
@export var can_be_hub_native: bool = false
@export var min_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var max_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED
@export var origin_spot_upgrades: Array[SpotUpgrade]
