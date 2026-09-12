@tool
class_name Companion
extends Term

static var _companion_group_loader := AsyncLoadedGroup.new('res://companions/resourcegroup_companions.tres', true, AsyncLoadedResource.LoadPhase.SPECULATIVE)

@export var companion_id: String
@export var companion_name: String
@export var description: String
@export var image: Texture2D
var ability_description: String:
	get:
		var result := markedup_ability_description
		if GameSettings.Interface.aspect_icons.value() != GameSettings.AspectIconStyle.CLASSIC:
			# HACK: Pretty awful, but saves custom parser support.
			var regex := RegEx.create_from_string(r'(\[img[^\]]*\]res://aspects/types/[^/]*/[^\[]*)\.png(\[/img\])')
			if GameSettings.Interface.aspect_icons.value() == GameSettings.AspectIconStyle.SUPER_ACCESSIBLE:
				result = regex.sub(result, '$1_accessible_slot_filled.png$2', true)
			else:
				result = regex.sub(result, '$1_accessible.png$2', true)
		return result
@export_multiline var markedup_ability_description: String
@export var scene: PackedScene

static var _all_companions: Array[Companion] = []

static func get_all_companions() -> Array[Companion]:
	if not _all_companions:
		_companion_group_loader.fetch_loaded(_all_companions)
	return _all_companions

static func get_companion_by_id(target_companion_id: String) -> Companion:
	for companion in get_all_companions():
		if companion.companion_id == target_companion_id:  # Not a base class.
			return companion
	return null

func get_term_id() -> String:
	return 'companion.' + companion_id

func get_term_name(long: bool) -> String:
	if long:
		return tr('%s Companion') % tr(companion_name)
	else:
		return tr(companion_name)

func get_markedup_description() -> String:
	return '<related_term:companion>' + tr(description)

func get_term_priority() -> int:
	return 10  # Very specific, so probably important.
