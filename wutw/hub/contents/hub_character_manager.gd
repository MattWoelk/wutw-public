@tool
class_name HubCharacterManager
extends Node2D

@export_group('DEBUG')
@export var debug_mq_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED
@export_tool_button('Randomize') @warning_ignore('unused_private_class_variable')
var _debug_randomize_tool := _debug_randomize
@export_tool_button('Clear') @warning_ignore('unused_private_class_variable')
var _debug_clear_tool := _debug_clear

func _ready() -> void:
	y_sort_enabled = true

func spawn(rng: RandomState) -> void:
	# This takes ~20ms in the worst case on my machine.
	# If it needs to run faster, sort by most constrained first.

	# Get available specs.
	var main_quest_state := (debug_mq_state if Utils.is_in_editor()
							 else GlobalSaveGame.get_main_quest_progress())
	var available_specs: Dictionary[HubCharacterSpec, bool]
	for spec in HubCharacterSpec.get_all_specs():
		if main_quest_state < spec.min_main_quest_state:
			continue
		if main_quest_state > spec.max_main_quest_state:
			continue
		available_specs[spec] = true

	# Get available spawners, shuffled.
	var spawners: Array[HubSpawner]
	for spawner in _get_spawners():
		spawner.clear()
		if spawner.force_spawn:
			# Force spawn special NPCs.
			spawner.try_spawn(available_specs, rng, 0)
		else:
			spawners.append(spawner)
	rng.shuffle(spawners)

	# Keep spawning greedily.
	var limits := _choose_count_limits(main_quest_state)
	var min_count := limits.x
	var max_count := limits.y
	var goal_count := rng.rand_int(min_count, max_count)
	var num_spawned := 0
	var male_surplus := 0
	for spawner in spawners:
		if spawner.get_num_to_spawn() > goal_count - num_spawned:
			continue
		for hub_char in spawner.try_spawn(available_specs, rng, male_surplus):
			num_spawned += 1
			if hub_char.character.gender == HubCharacterSpec.Gender.MALE:
				male_surplus += 1
			else:
				male_surplus -= 1
		if num_spawned >= goal_count or not available_specs:
			break

	if num_spawned < min_count or num_spawned > max_count:
		push_warning('Tried to spawn %d-%d NPCs. Spawned %d.' % [min_count, max_count, num_spawned])

func spawn_specific(character: HubCharacter) -> bool:
	var spawners := _get_spawners()
	GlobalSaveGame.get_hub_random().snapshot().shuffle(spawners)
	for spawner in spawners:
		var spawner_single := spawner as HubSpawner_Single
		if spawner_single and spawner_single.try_spawn_manual(character):
			return true
	return false

func get_spawned_characters() -> Array[HubCharacter]:
	var result: Array[HubCharacter]
	for spawner in _get_spawners():
		result.append_array(spawner.get_spawned_characters())
	return result

func _get_spawners() -> Array[HubSpawner]:
	var main_quest_state := (debug_mq_state if Utils.is_in_editor()
							 else GlobalSaveGame.get_main_quest_progress())
	var spawners: Array[HubSpawner]
	for child in get_children():
		var spawner := child as HubSpawner
		if Utils.ensure(spawner != null):
			if main_quest_state < spawner.min_main_quest_state:
				continue
			if main_quest_state > spawner.max_main_quest_state:
				continue
			spawners.append(spawner)
	return spawners

func _debug_randomize() -> void:
	spawn(RandomState.new())

func _debug_clear() -> void:
	for spawner in _get_spawners():
		spawner.clear()
		if spawner is HubSpawner_Single:
			(spawner as HubSpawner_Single).debug_spawned_character = null

func _choose_count_limits(main_quest_state: SaveGame.MainQuestProgress) -> Vector2i:
	if main_quest_state <= GlobalSaveGame.MainQuestProgress.P110_COMPLETED_TUTORIAL:
		return Vector2i(2, 4)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P115_GATHERED_RELICS:
		return Vector2i(5, 8)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P120_ESTABLISHED_CAPITAL:
		return Vector2i(8, 11)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P130_ESTABLISHED_SHRINES:
		return Vector2i(12, 15)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P140_DEDICATED_STATUE:
		return Vector2i(16, 20)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P210_FOUND_PLACES_OF_POWER:
		return Vector2i(20, 25)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P230_PREPARED_RITUAL:
		return Vector2i(25, 32)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P350_SIGNED_ACCORD:
		return Vector2i(30, 40)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P400_STARTED_DEPRESSION:
		return Vector2i(2, 5)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P410_FOUND_KID:
		return Vector2i(5, 10)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P420_SENT_OFF_KID:
		return Vector2i(13, 20)
	elif main_quest_state <= GlobalSaveGame.MainQuestProgress.P430_STARTED_DEBATE:
		return Vector2i(30, 40)
	elif main_quest_state < GlobalSaveGame.MainQuestProgress.NEVER_REACHED:
		return Vector2i(35, 60)
	else:
		if Utils.ensure(Utils.is_in_editor()):
			return Vector2i(500, 500)  # For testing in editor.
		else:
			return Vector2i(20, 20)
