@tool
class_name Skill
extends Term

@export var skill_id: String
@export var skill_name: String
@export var skill_name_realistic: String
@export_multiline var description: String
@export_multiline var description_realistic: String
@export var icon: Texture2D
@export var unlock_cost: int
@export var var_type: Var = Var.NONE
@export var var_amount: int = 0
@export var requirement: Skill
@export var min_main_quest_progress: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var revealed_manually: bool = false

# WARNING: Enums are stored as ints in Skill resources,
#          so we can't remove deprecated values without explicit renumbering.
enum Var {
	NONE,

	# Inspiration tree
	MAX_INSPIRATION,
	HEAL_PER_STAGE,

	# Glyph tree
	START_HAND_SIZE,
	REDRAW_HAND_SIZE,
	CARD_TIER_BONUS_PERCENT,
	CARD_REWARD_REROLLS,
	RESERVE_CARD_UNLOCKED,  # bool
	MIN_DECK_SIZE_REDUCTION,

	# Inscription tree
	SIGNATURE_CARDS,
	REPLACE_STARTER_CARDS,  # bool
	INHERIT_CARD,  # bool
	INSCRIBE_COMMON,  # bool
	INSCRIBE_UNCOMMON,  # bool
	INSCRIBE_RARE,  # bool
	INSCRIBE_EPIC,  # bool
	EXTRA_SALVAGE_CARDS,
	DOUBLE_SALVAGE_STROKES,  # bool

	# Relics tree
	RANDOM_STARTING_RELIC,  # bool
	SELECTED_STARTING_RELIC,  # bool
	UNCOMMON_STARTING_RELIC,  # bool
	RELIC_REWARD_REROLLS,

	# Event tree
	EVENTS_PER_STAGE,
	SHOP_CARDS,  # bool
	SHOP_RELICS,  # bool
	SHOP_INNATE,  # bool
	SHOP_REMOVE,  # bool
	SHOP_RECALL,  # bool
	SHOP_CONNECT,  # bool
	SHOP_HEAL,  # bool

	# Capital tree
	CAPITAL_UNLOCKED,  # bool
	CAPITAL_CONNECTION,  # bool
	CAPITAL_INITIAL_PROVISION,  # bool
	CAPITAL_ACTIVATE_PROVISIONS,  # bool
	CAPITAL_CRAFT_CONNECTION,  # bool
	TRADE_DISCOUNT_PERCENTAGE,

	# Settlement tree
	PREVIEW_BONUSES,  # bool
	_DEPRECATED_PREVIEW_TREE,  # bool
	NONGOAL,  # bool
	SPOTS_PER_SEASON,
	EXTRA_SPOTS,
	_DEPRECATED_DEACTIVATIONS,
	GOAL_REROLLS,
	CREATE_SMALL_BUILDING,  # bool
	CREATE_LARGE_BUILDING,  # bool
	CREATE_SQUARE,  # bool
	_DEPRECATED_CREATE_FOREST,  # bool
	CREATE_LAKE,  # bool

	# Hauntings/Challenges tree
	HAUNTING_PACIFIES,
	HAUNTING_BANS,

	# Added later
	PREVIEW_EVENTS,  # Events tree, bool
	PINNED_EVENTS,  # Events tree
	SHOP_TRADE,  # Capital tree, bool
	HAUNTING_UNLOCKED,  # Hauntings/Challenges tree
	PREVIEW_HAUNTING,  # Hauntings/Challenges tree
	INSIGHTS_FROM_EXCESS,  # Settlement tree
	MULLIGANS,  # Cards tree

	SURVEYS,  # Survey tree root, bool
	SURVEY_PREPS,  # Survey tree
	SURVEY_EXTRA_EPISODES,  # Survey tree
	REVEAL_SIZE_BONUS,  # Survey tree

	INSIGHTS_FROM_DISCOVERY,  # Settlement tree
	CARD_REWARD_REROLL_QUALITY,  # Cards tree
	BUY_STROKES,  # Craft tree
	BUY_CARDS,  # Craft tree
	IGNORE_UNIQUES,  # Settlement tree
	MAX_SETTLER_QUESTS,  # Settlement tree
	SETTLEMENT_OVERLAP_PERCENT,  # Settlement tree

	PREVIEW_MAP,  # Survey tree
	REROLL_MAP,  # Survey tree

	REMOVE_RELIC,  # Relics tree
}

static var _skill_group_loader := AsyncLoadedGroup.new('res://skills/resourcegroup_skills.tres')
static var _all_skills: Dictionary[String, Skill] = {}

func _init() -> void:
	term_categories.append(load('res://glossary/categories/termcategory_skill.tres'))

static func get_all_skills() -> Dictionary[String, Skill]:
	if not _all_skills:
		for skill: Skill in _skill_group_loader.get_loaded():
			_all_skills[skill.skill_id] = skill
	return _all_skills

static func get_skill_by_id(target_skill_id: String) -> Skill:
	return get_all_skills().get(target_skill_id, null)

static func get_skill_var(queried_var_type: Var) -> int:
	if Utils.is_in_editor():
		return 1
	var total := 0
	for skill in GlobalSaveGame.get_unlocked_skills():
		if skill.var_type == queried_var_type:
			total += skill.var_amount
	return total

func is_revealed() -> bool:
	if Utils.is_in_editor():
		return true
	elif revealed_manually:
		return GlobalSaveGame.has_revealed_skill(self)
	else:
		return GlobalSaveGame.get_main_quest_progress() >= min_main_quest_progress

func get_effective_skill_name() -> String:
	if Utils.is_realistic_era() and skill_name_realistic:
		return tr(skill_name_realistic)
	else:
		return tr(skill_name)

func get_effective_description() -> String:
	if Utils.is_realistic_era() and description_realistic:
		return tr(description_realistic)
	else:
		return tr(description)

func get_term_id() -> String:
	return 'skill.' + skill_id

func get_term_name(long: bool) -> String:
	if long:
		return tr('Skill: ') + get_effective_skill_name()
	else:
		return get_effective_skill_name()

func get_markedup_description() -> String:
	return '<related_term:skill>' + get_effective_description()

func get_term_priority() -> int:
	return 10  # Very specific, so probably important.
