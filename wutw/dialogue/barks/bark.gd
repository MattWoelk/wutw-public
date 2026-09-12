class_name Bark
extends Resource

static var BARK_DB := AsyncLoadedResource.new('res://dialogue/barks/bark_db.tres', false, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var _recent_barks: Array[Bark] = []  # Used to avoid repetition.
const MAX_RECENT_BARKS: int = 30

@export_multiline var text: String
@export var specific_character: Character = null
@export var min_main_quest: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var max_main_quest: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED  # Exclusive
@export var limit_to_jobs: Array[Job]
@export var limit_to_shard_type: ShardType = null
@export_flags('HUB', 'REFUGEE', 'PAST_SHARD')
var limit_to_origins: int = 0
@export_flags('CHILD', 'ADULT', 'ELDER')
var limit_to_ages: int = (1 << HubCharacterSpec.Age.ADULT) | (1 << HubCharacterSpec.Age.ELDER)
@export_flags('STUDIO_PRIMARY', 'STUDIO_SECONDARY', 'MUSEUM_PRIMARY', 'MUSEUM_SECONDARY',
			  'SHRINE_PRIMARY', 'SHRINE_SECONDARY', 'PORTAL_NETWORK', 'TOWER',
			  'GENERIC', 'EMBARKING', 'CONVERSATION', 'PEERING', 'VENDOR', 'PICNIC', 'CHILD',
			  'POOL_EDGE', 'LEANING_ON_WALL', 'BROWSING_MUSEUM', 'PLAYING_MUSIC', 'DANCING',
			  'PARENT', 'PRAYING', 'VENDOR_CONFINED',
) var limit_to_sockets: int = 0
@export var custom_requirement: EventRequirement = null

var priority: float:
	get():
		if _cached_priority == -1:
			_cached_priority = _calculate_priority()
		return _cached_priority
var _cached_priority: float = -1

static func choose_bark(character: HubCharacter) -> Bark:
	# TODO: Set up indices for faster matching.
	assert(character)
	var pool: Array[Bark]
	var all_barks := (BARK_DB.get_loaded() as BarkDB).barks
	for bark in all_barks:
		if bark.matches(character):
			pool.append(bark)

	if pool:
		pool.sort_custom(func(a: Bark, b: Bark) -> bool:
			return a.priority > b.priority  # Already includes a small randomization factor.
		)
		for bark in pool:
			if bark not in _recent_barks:
				if _recent_barks.size() >= MAX_RECENT_BARKS:
					_recent_barks.remove_at(0)
				_recent_barks.append(bark)
				return bark
		# Repeats are fine as a fallback.
		return pool[0]
	else:
		# None found.
		push_warning('No matching bark found for character: ', character)
		var bark := Bark.new()
		bark.text = '...'
		return bark

func matches(character: HubCharacter) -> bool:
	# Ordered by most to least restrictive.
	if limit_to_shard_type:
		if not character.home_shard or character.home_shard.shard_type != limit_to_shard_type:
			return false
	if limit_to_jobs and character.job not in limit_to_jobs:
		return false

	if specific_character:
		if character.character.get_character() != specific_character:
			return false
	else:
		if character.character.main_character:
			return false

	if limit_to_sockets:
		var spawner := character.get_parent() as HubSpawner_Single
		if spawner:
			var socket := spawner.socket
			var mask := 1 << (socket as int)
			if (mask & limit_to_sockets) == 0:
				return false
	if limit_to_origins:
		var mask := 1 << (character.origin as int)
		if (mask & limit_to_origins) == 0:
			return false
	if limit_to_ages:
		var mask := 1 << (character.character.age as int)
		if (mask & limit_to_ages) == 0:
			return false
	if custom_requirement and not custom_requirement.is_satisfied(null, null):
		return false
	var mq_state := GlobalSaveGame.get_main_quest_progress()
	if not Utils.ensure(min_main_quest != max_main_quest):
		return mq_state == min_main_quest
	return mq_state >= min_main_quest and mq_state < max_main_quest  # Maximum is exclusive

func _calculate_priority() -> float:
	var restrictions := 0
	if specific_character:
		restrictions += 10
	if min_main_quest != SaveGame.MainQuestProgress.P000_INTRO:
		restrictions += 1
	if max_main_quest != SaveGame.MainQuestProgress.NEVER_REACHED:
		restrictions += 1
	if limit_to_jobs:
		restrictions += 5 if limit_to_jobs.size() == 1 else 3
	if limit_to_shard_type:
		restrictions += 8
	if limit_to_origins != 0:
		restrictions += 2
	if limit_to_ages == 1 << HubCharacterSpec.Age.CHILD:
		restrictions += 2
	if limit_to_sockets != 0:
		restrictions += 3
	if custom_requirement:
		restrictions += 4
	var random_factor := absf(get_instance_id() % 100) / 100.0
	return restrictions + random_factor
