class_name BonusGain
extends RefCounted

enum Reason {
	ERROR_UNKNOWN,
	SPOT_RECIPE,
	ABILITY,
	SHOP,
	RELIC,
	EVENT,
	COMPANION,
	HAUNTING,
	DEBUG,
	SURVEY_COST,
	SURVEY_CHOICE,
	SETTLER_QUEST,
}

var bonus_type: BonusType
var amount: int
var original_amount: int
var source: Object  # Various valid types - see get_reason().

func _init(in_bonus_type: BonusType, in_amount: int, in_source: Object) -> void:
	bonus_type = in_bonus_type
	amount = in_amount
	original_amount = amount
	source = in_source
	Utils.ensure(get_reason() != Reason.ERROR_UNKNOWN)

func get_reason() -> Reason:
	if source is SpotRecipe:
		return Reason.SPOT_RECIPE
	elif source is CompanionRecipe:
		return Reason.COMPANION
	elif source is Relic:
		return Reason.RELIC
	elif source is HauntingEffect:
		return Reason.HAUNTING
	elif source is Event:
		return Reason.EVENT
	elif source is ShopBase:
		return Reason.SHOP
	elif source is Card:
		return Reason.ABILITY
	elif source is SurveyPrepButton:
		return Reason.SURVEY_COST
	elif source is Survey:
		return Reason.SURVEY_CHOICE
	elif source is SettlerQuestChallenge:
		return Reason.SETTLER_QUEST
	elif source is DebugConsoleCommands:
		return Reason.DEBUG
	else:
		return Reason.ERROR_UNKNOWN
