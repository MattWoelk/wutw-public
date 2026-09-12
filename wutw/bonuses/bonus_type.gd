@tool
class_name BonusType
extends Term

@export var bonus_type_id: String
@export var name: String
@export_multiline var description: String
@export_multiline var flavor: String
@export_multiline var shop_hint: String
@export var icon: Texture2D
@export var glow_icon: Texture2D
@export var is_advanced: bool
@export var sort_order: int
@export var focus_var: RunVars.Var

static func get_all_types() -> Array[BonusType]:
	# Hacky, but convenient. This is really a fancy enum.
	return [
		load('res://bonuses/types/bonus_food.tres'),
		load('res://bonuses/types/bonus_safety.tres'),
		load('res://bonuses/types/bonus_beauty.tres'),
		load('res://bonuses/types/bonus_harmony.tres'),
		load('res://bonuses/types/bonus_knowledge.tres'),
		load('res://bonuses/types/bonus_adventure.tres'),
		load('res://bonuses/types/bonus_productivity.tres'),
	]

static func get_bonus_type_by_id(target_bonus_type_id: String) -> BonusType:
	for bonus_type in get_all_types():
		if bonus_type.bonus_type_id == target_bonus_type_id:
			return bonus_type
	return null

func _init() -> void:
	term_categories.append(load('res://glossary/categories/termcategory_bonus.tres'))

func get_term_id() -> String:
	return 'bonus.' + name.to_lower()

func get_term_name(long: bool) -> String:
	var img := '[img width=1.5em height=1.5em]%s[/img]' % icon.resource_path
	if long:
		return img + ' ' + tr('%s Yield') % tr(name)
	else:
		return img + ' ' + tr(name)

func get_markedup_description() -> String:
	var text := '<related_term:bonus>' + tr(description)
	if not Utils.is_in_editor() and GlobalSaveGame.get_main_quest_progress() >= SaveGame.MainQuestProgress.P200_STARTED_MAGIC:
		text += '\n\n' + tr(shop_hint)
	text += '\n\n' + tr('“%s”') % tr(flavor)
	return text

func get_term_priority() -> int:
	return -1  # Pretty generic, so probably more important stuff.
