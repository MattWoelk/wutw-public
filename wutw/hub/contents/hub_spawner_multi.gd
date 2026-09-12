@tool
class_name HubSpawner_Multi
extends HubSpawner

@export_group('DEBUG')
@export_tool_button('Randomize') @warning_ignore('unused_private_class_variable')
var _debug_randomize_tool := spawn_random

func _ready() -> void:
	y_sort_enabled = true

func try_spawn(available: Dictionary[HubCharacterSpec, bool], rng: RandomState, male_surplus: int) -> Array[HubCharacter]:
	var spawners := _get_children()
	rng.shuffle(spawners)
	var spawned: Array[HubCharacter]
	for spawner in spawners:
		if spawner.try_spawn(available, rng, male_surplus):
			for hub_char in spawner.get_spawned_characters():
				available.erase(hub_char.character)
				spawned.append(hub_char)
				if hub_char.character.gender == HubCharacterSpec.Gender.MALE:
					male_surplus += 1
				else:
					male_surplus -= 1
		else:
			for spawner2 in _get_children():
				spawner2.clear()
			for hub_char in spawned:
				available[hub_char.character] = true
			return []
	return spawned

func clear() -> void:
	for spawner in _get_children():
		spawner.clear()

func get_spawned_characters() -> Array[HubCharacter]:
	var result: Array[HubCharacter]
	for spawner in _get_children():
		result.append_array(spawner.get_spawned_characters())
	return result

func get_num_to_spawn() -> int:
	return get_child_count()

func _get_children() -> Array[HubSpawner]:
	var result: Array[HubSpawner]
	for child in get_children():
		if Utils.ensure(child is HubSpawner):
			result.append(child as HubSpawner)
	return result

func spawn_random() -> void:
	var mq_state := GlobalSaveGame.get_main_quest_progress()
	var options: Dictionary[HubCharacterSpec, bool]
	for character in Character.get_all_characters():
		for spec in character.hub_specs:
			if spec.main_character:
				continue
			if mq_state < spec.min_main_quest_state:
				continue
			if mq_state > spec.max_main_quest_state:
				continue
			options[spec] = true
	try_spawn(options, RandomState.new(), 0)
