@tool
class_name HubCharacterSpec
extends Resource

enum Gender { MALE, FEMALE, OTHER }
enum Age { CHILD, ADULT, ELDER }

enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST,
}

# IMPORTANT: Keep in sync with the export_flags annotations below and in Bark.
# WARNING: These are stored as ints in resources, so the values must never change.
enum Socket {
	STUDIO_PRIMARY,
	STUDIO_SECONDARY,
	MUSEUM_PRIMARY,
	MUSEUM_SECONDARY,
	SHRINE_PRIMARY,
	SHRINE_SECONDARY,
	PORTAL_NETWORK,
	TOWER,
	GENERIC,
	EMBARKING,
	CONVERSATION,
	PEERING,
	VENDOR_BOOKS,
	PICNIC,
	CHILD,
	POOL_EDGE,
	LEANING_ON_WALL,
	BROWSING_MUSEUM,
	PLAYING_MUSIC,
	DANCING,
	PARENT,
	PRAYING,
	VENDOR_CONFINED,
	SPECIAL_AVATAR_CHILD,
	SPECIAL_AVATAR_ADULT,
	# 24/32 total
}

@export var scene: PackedScene
@export var gender: Gender
@export var age: Age = Age.ADULT
@export var flippable: bool = true
@export var main_character: bool = false
@export var must_be_refugee: bool = false
@export var direction: Direction = Direction.WEST
@export var facing_direction: Direction = Direction.WEST
# IMPORTANT: Keep in sync with the Socket enum above.
@export_flags('STUDIO_PRIMARY', 'STUDIO_SECONDARY', 'MUSEUM_PRIMARY', 'MUSEUM_SECONDARY',
			  'SHRINE_PRIMARY', 'SHRINE_SECONDARY', 'PORTAL_NETWORK', 'TOWER',
			  'GENERIC', 'EMBARKING', 'CONVERSATION', 'PEERING', 'VENDOR', 'PICNIC', 'CHILD',
			  'POOL_EDGE', 'LEANING_ON_WALL', 'BROWSING_MUSEUM', 'PLAYING_MUSIC', 'DANCING',
			  'PARENT', 'PRAYING', 'VENDOR_CONFINED', 'SPECIAL_AVATAR_CHILD', 'SPECIAL_AVATAR_ADULT',
) var allowed_sockets_mask: int
# IMPORTANT: Keep in sync with the Socket enum above.
@export_flags('STUDIO_PRIMARY', 'STUDIO_SECONDARY', 'MUSEUM_PRIMARY', 'MUSEUM_SECONDARY',
			  'SHRINE_PRIMARY', 'SHRINE_SECONDARY', 'PORTAL_NETWORK', 'TOWER',
			  'GENERIC', 'EMBARKING', 'CONVERSATION', 'PEERING', 'VENDOR', 'PICNIC', 'CHILD',
			  'POOL_EDGE', 'LEANING_ON_WALL', 'BROWSING_MUSEUM', 'PLAYING_MUSIC', 'DANCING',
			  'PARENT', 'PRAYING', 'VENDOR_CONFINED', 'SPECIAL_AVATAR_CHILD', 'SPECIAL_AVATAR_ADULT',
) var preferred_sockets_mask: int
@export var allowed_jobs: Array[Job]
@export var preferred_jobs: Array[Job]
@export var min_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var max_main_quest_state: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED

static var _all_specs: Array[HubCharacterSpec]
static var _preferred_by_socket: Dictionary[Socket, Array]  # Array[HubCharacterSpec]
static var _allowed_by_socket: Dictionary[Socket, Array]  # Array[HubCharacterSpec]

func is_allowed_socket(socket: Socket) -> bool:
	var mask := 1 << (socket as int)
	return (mask & allowed_sockets_mask) > 0

func is_preferred_socket(socket: Socket) -> bool:
	var mask := 1 << (socket as int)
	return (mask & preferred_sockets_mask) > 0

func get_allowed_sockets() -> Array[Socket]:
	var result: Array[Socket]
	for socket: Socket in Socket.values():
		if is_allowed_socket(socket):
			result.append(socket)
	return result

func get_preferred_sockets() -> Array[Socket]:
	var result: Array[Socket]
	for socket: Socket in Socket.values():
		if is_preferred_socket(socket):
			result.append(socket)
	return result

func get_character() -> Character:
	for character in Character.get_all_characters():
		if self in character.hub_specs:
			return character
	if Utils.is_in_editor():
		push_warning('Could not find character for hub character spec.')
	else:
		assert(false, 'Could not find character for hub character spec.')
	return null

static func get_flipped_direction(input_direction: Direction) -> Direction:
	match input_direction:
		Direction.NORTH: return Direction.EAST
		Direction.EAST: return Direction.NORTH
		Direction.SOUTH: return Direction.WEST
		Direction.WEST: return Direction.SOUTH
		_: return Direction.NORTH

static func get_all_specs() -> Array[HubCharacterSpec]:
	if not _all_specs or Utils.is_in_editor():
		_initialize_lists()
	return _all_specs

static func get_allowed_specs_by_socket(socket: Socket) -> Array:  # Array[HubCharacterSpec]
	if not _all_specs or Utils.is_in_editor():
		_initialize_lists()
	return _allowed_by_socket.get(socket, [])

static func get_preferred_specs_by_socket(socket: Socket) -> Array:  # Array[HubCharacterSpec]
	if not _all_specs or Utils.is_in_editor():
		_initialize_lists()
	return _preferred_by_socket.get(socket, [])

static func _initialize_lists() -> void:
	_all_specs = []
	_preferred_by_socket = {}
	_allowed_by_socket = {}
	for character in Character.get_all_characters():
		for spec in character.hub_specs:
			_all_specs.append(spec)
			for socket in spec.get_preferred_sockets():
				if socket not in _preferred_by_socket:
					_preferred_by_socket[socket] = []
				_preferred_by_socket[socket].append(spec)
			for socket in spec.get_allowed_sockets():
				if socket not in _allowed_by_socket:
					_allowed_by_socket[socket] = []
				_allowed_by_socket[socket].append(spec)
	_all_specs.make_read_only()
	_preferred_by_socket.make_read_only()
	_allowed_by_socket.make_read_only()
