@tool
class_name HubSpawner_Single
extends HubSpawner

@export var socket: HubCharacterSpec.Socket
@export var directions: Array[HubCharacterSpec.Direction]
@export var use_facing_direction: bool = false

@export_group('DEBUG')
@export_custom(PROPERTY_HINT_NONE, '', PropertyUsageFlags.PROPERTY_USAGE_EDITOR)
var debug_allowed_index: int:
	set(value):
		if Utils.is_in_editor() and debug_allowed_index != value:
			var allowed_specs: Array[HubCharacterSpec]
			for spec: HubCharacterSpec in HubCharacterSpec.get_allowed_specs_by_socket(socket):
				if _matches_direction(spec):
					allowed_specs.append(spec)
			if allowed_specs:
				debug_allowed_index = (value + 100 * allowed_specs.size()) % allowed_specs.size()
				spawn(allowed_specs[debug_allowed_index] as HubCharacterSpec)
			else:
				debug_allowed_index = -1
				clear()
@export_custom(PROPERTY_HINT_NONE, '', PropertyUsageFlags.PROPERTY_USAGE_EDITOR)
var debug_spawned_character: HubCharacterSpec

var _spawned_character: HubCharacter

func _ready() -> void:
	clear()

func try_spawn(available: Dictionary[HubCharacterSpec, bool], rng: RandomState, male_surplus: int) -> Array[HubCharacter]:
	var valid: Array[HubCharacterSpec]
	var has_nonmale := false

	# Maybe try preferred first.
	if rng.rand_float() > 0.5:  # If not, same chance of preferred and not preferred.
		for spec: HubCharacterSpec in HubCharacterSpec.get_preferred_specs_by_socket(socket):
			if available.get(spec, false) and _matches_direction(spec):
				valid.append(spec)
				if spec.gender != HubCharacterSpec.Gender.MALE:
					has_nonmale = true

	# If didn't choose a preferred pool, try any allowed.
	if not valid:
		for spec: HubCharacterSpec in HubCharacterSpec.get_allowed_specs_by_socket(socket):
			if available.get(spec, false) and _matches_direction(spec):
				valid.append(spec)
				if spec.gender != HubCharacterSpec.Gender.MALE:
					has_nonmale = true

	if not valid:
		return []

	# Spawn the chosen spec.
	rng.shuffle(valid)
	for spec in valid:
		if male_surplus > 0 and has_nonmale and spec.gender == HubCharacterSpec.Gender.MALE:
			continue
		spawn(spec)
		available[spec] = false
		return [_spawned_character]

	Utils.ensure(false)
	return []

func spawn(spec: HubCharacterSpec) -> void:
	assert(spec)
	clear()
	_spawned_character = spec.scene.instantiate() as HubCharacter
	_spawned_character.character = spec
	var used_direction := spec.facing_direction if use_facing_direction else spec.direction
	if used_direction not in directions:
		_spawned_character.is_flipped = true
	add_child(_spawned_character)
	if Utils.is_in_editor():
		debug_spawned_character = spec
		(_spawned_character.get_node('%Area2D').get_node('CollisionPolygon2D') as Node2D).visible = false

func try_spawn_manual(character: HubCharacter) -> bool:
	var spec := character.character
	if spec.is_allowed_socket(socket) and _matches_direction(spec):
		clear()
		_spawned_character = character
		var used_direction := spec.facing_direction if use_facing_direction else spec.direction
		if used_direction not in directions:
			_spawned_character.is_flipped = true
		add_child(_spawned_character)
		return true
	else:
		return false

func clear() -> void:
	if _spawned_character:
		_spawned_character.queue_free()
		_spawned_character = null

func get_spawned_characters() -> Array[HubCharacter]:
	var result: Array[HubCharacter]
	if _spawned_character:
		result.append(_spawned_character)
	return result

func get_num_to_spawn() -> int:
	return 1

func _matches_direction(spec: HubCharacterSpec) -> bool:
	var used_direction := spec.facing_direction if use_facing_direction else spec.direction
	if used_direction in directions:
		return true
	elif spec.flippable and HubCharacterSpec.get_flipped_direction(used_direction) in directions:
		return true
	else:
		return false
