class_name ShardTypeHistory
extends Resource

@export_multiline var text: String
@export var min_main_quest: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var time_taken: int = 1
@export var overrides: Array[ShardTypeHistoryOverride]
