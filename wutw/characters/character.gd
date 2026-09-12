@tool
class_name Character
extends Resource

static var _group_loader := AsyncLoadedGroup.new('res://characters/resourcegroup_characters.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var character_id: String
@export var character_name: String
@export var dialogue_scene: PackedScene
@export var dialogue_portrait: Texture2D
@export var hub_specs: Array[HubCharacterSpec]

static var _all_characters: Array[Character] = []

static func get_all_characters() -> Array[Character]:
	if not _all_characters:
		_group_loader.fetch_loaded(_all_characters)
	return _all_characters

static func get_character_by_id(target_character_id: String) -> Character:
	for character in get_all_characters():
		if character.character_id == target_character_id:
			return character
	return null
