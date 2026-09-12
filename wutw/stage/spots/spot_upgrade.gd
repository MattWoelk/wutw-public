@tool
class_name SpotUpgrade
extends Resource

static var _group_loader := AsyncLoadedGroup.new('res://stage/spots/resourcegroup_spot_upgrades.tres')

enum Tag { NATURAL, AGRICULTURAL, INDUSTRIAL, SPIRITUAL }

@export var spot_upgrade_id: String
@export var name: String
@export_multiline var description: String
@export var required_aspects: Array[AspectType]
@export var granted_bonuses: Dictionary[BonusType, int]
@export var child_upgrades: Array[SpotUpgrade]
@export var spot: SpotType
@export var visuals: Array[SpotUpgradeVisual]
@export var tags: Array[Tag]

var parent_upgrade: SpotUpgrade:
	get():
		return _parent_upgrade

@export var unique_per_run: bool = false
@export var required_event_state: EventRequirement_EventState = null
@export var min_main_quest_progress: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.P000_INTRO
@export var max_main_quest_progress: SaveGame.MainQuestProgress = SaveGame.MainQuestProgress.NEVER_REACHED

static var _all_spot_upgrades: Array[SpotUpgrade] = []

var _parent_upgrade: SpotUpgrade

static func get_all_spot_upgrades() -> Array[SpotUpgrade]:
	if not _all_spot_upgrades:
		_group_loader.fetch_loaded(_all_spot_upgrades)
		for upgrade in _all_spot_upgrades:
			assert(upgrade.spot)
			for child in upgrade.child_upgrades:
				assert(not child._parent_upgrade)
				child._parent_upgrade = upgrade
	return _all_spot_upgrades

static func get_spot_upgrade_by_id(target_spot_upgrade_id: String) -> SpotUpgrade:
	for spot_upgrade in get_all_spot_upgrades():
		if spot_upgrade.spot_upgrade_id == target_spot_upgrade_id:
			return spot_upgrade
	return null

func is_allowed(run: Run, is_first_spot_copy: bool) -> bool:
	if not run:
		return true
	var main_quest_progress := GlobalSaveGame.get_main_quest_progress()
	if main_quest_progress < min_main_quest_progress:
		return false
	if main_quest_progress > max_main_quest_progress:
		return false
	if required_event_state and not required_event_state.is_satisfied(run, null):
		return false
	if unique_per_run and not Skill.get_skill_var(Skill.Var.IGNORE_UNIQUES):
		if not is_first_spot_copy:
			return false
		for settlement_state in run.get_settlement_states():
			for spot_activated_upgrades in settlement_state.activated_upgrades:
				if self in spot_activated_upgrades:
					return false
	return true
