@tool
class_name AspectType
extends Term

@export var aspect_type_id: String
@export var name: String
@export_multiline var description: String
@export var color: Color
@export var icon: Texture2D
@export var slot_icon: Texture2D:
	get():
		if Utils.is_in_editor():
			return slot_icon
		if GameSettings.Interface.aspect_icons.value() == GameSettings.AspectIconStyle.CLASSIC:
			return slot_icon
		else:
			return accessible_icon_slot_filled
@export var is_advanced: bool
@export var sort_order: int
@export var audio_switch: WwiseSwitch

@export_group('Accessible Alternatives')
@export var accessible_icon: Texture2D
@export var accessible_icon_slot_empty: Texture2D
@export var accessible_icon_slot_filled: Texture2D
@export var accessible_icon_slot_highlighted: Texture2D

static func compare(a: AspectType, b: AspectType) -> bool:
	if a == null or b == null:
		return b == null
	return a.sort_order < b.sort_order

static func get_all_types() -> Array[AspectType]:
	# Hacky, but convenient. This is really a fancy enum.
	# In sort_order.
	return [
		load('res://aspects/types/stability/aspect_stability.tres'),
		load('res://aspects/types/change/aspect_change.tres'),
		load('res://aspects/types/life/aspect_life.tres'),
		load('res://aspects/types/craft/aspect_craft.tres'),
		load('res://aspects/types/spirit/aspect_spirit.tres'),
		load('res://aspects/types/illumination/aspect_illumination.tres'),
		load('res://aspects/types/connection/aspect_connection.tres'),
	]

static func get_aspect_type_by_id(target_aspect_type_id: String) -> AspectType:
	for aspect_type in get_all_types():
		if aspect_type.aspect_type_id == target_aspect_type_id:
			return aspect_type
	return null

func _init() -> void:
	term_categories.append(load('res://glossary/categories/termcategory_aspect.tres'))

func get_term_id() -> String:
	return 'aspect.' + aspect_type_id

func get_term_name(long: bool) -> String:
	var img := '[img width=1.5em height=1.5em]%s[/img]' % get_used_icon().resource_path
	if long:
		return img + ' ' + tr('%s Essence') % tr(name)
	else:
		return img + ' ' + tr(name)

func get_used_icon() -> Texture2D:
	match GameSettings.Interface.aspect_icons.value():
		GameSettings.AspectIconStyle.CLASSIC: return icon
		GameSettings.AspectIconStyle.ACCESSIBLE: return accessible_icon
		GameSettings.AspectIconStyle.SUPER_ACCESSIBLE: return accessible_icon_slot_filled
	Utils.ensure(false)
	return icon

func get_markedup_description() -> String:
	return ('%s<related_term:aspect>' % tr(description))

func get_term_priority() -> int:
	return -2  # Pretty generic, and mostly flavor anyway.
