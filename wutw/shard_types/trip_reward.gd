class_name TripReward
extends Resource

@export_multiline var text: String
@export var unlocked_relic: Relic
@export var revealed_skill: Skill
@export var gained_argument: DebateArgument
@export var min_main_quest_progress: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
