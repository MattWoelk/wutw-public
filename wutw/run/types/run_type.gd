class_name RunType
extends Resource

@export var display_name: String
@export var short_description: String
@export var icon: Texture2D
@export var scaling_override: RunScaling

static var _group_loader := AsyncLoadedGroup.new('res://run/types/resourcegroup_run_types.tres')
static var _all_run_types: Array[RunType] = []

static func get_all_run_types() -> Array[RunType]:
	if not _all_run_types:
		_group_loader.fetch_loaded(_all_run_types)
	return _all_run_types
