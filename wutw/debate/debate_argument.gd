class_name DebateArgument
extends Resource

enum Faction { SCRIBE, HISTORIAN }

@export var argument_id: String
@export var name: String
@export var impact: int = 1
@export var faction: Faction = Faction.HISTORIAN
@export var dialogue: Dialogue

static var _argument_group_loader := AsyncLoadedGroup.new('res://debate/resourcegroup_debate_arguments.tres', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)
static var _all_arguments: Dictionary[String, DebateArgument] = {}

static func get_all_arguments() -> Dictionary[String, DebateArgument]:
	if not _all_arguments:
		for argument: DebateArgument in _argument_group_loader.get_loaded():
			_all_arguments[argument.argument_id] = argument
	return _all_arguments

static func get_argument_by_id(in_argument_id: String) -> DebateArgument:
	return get_all_arguments().get(in_argument_id, null)
