class_name RunConfig
extends Resource

@export var run_type: RunType
@export var run_seed: int = 0
@export var starting_cards: Array[CardType] = []
@export var companion: Companion
@export var map_generation_config: MapGenerationConfig
@export var force_legacy_random: bool = false  # For map generation

@export var debug_map_seed: int = 0  # If non-zero, used instead of run_seed for map generation.
