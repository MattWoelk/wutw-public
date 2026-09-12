@tool @abstract
class_name HubSpawner
extends Node2D

@export var force_spawn: bool = false
@export var min_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var max_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED

@abstract func try_spawn(available: Dictionary[HubCharacterSpec, bool], rng: RandomState, male_surplus: int) -> Array[HubCharacter]
@abstract func clear() -> void
@abstract func get_spawned_characters() -> Array[HubCharacter]
@abstract func get_num_to_spawn() -> int
