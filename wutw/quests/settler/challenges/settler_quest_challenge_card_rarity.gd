class_name SettlerQuestChallenge_CardRarity
extends SettlerQuestChallenge

@export var percentage_decrease: int = 10

func apply_starting_modifiers(quest: Quest_Settler, run: Run) -> void:
	Utils.ensure(percentage_decrease > 0)
	run.get_vars().add_modifier(RunVars.Var.CARD_TIER_BONUS_PERCENT, -percentage_decrease, _get_mod_tag(quest))

func describe() -> String:
	return tr('Reduce <term_lower:card_rarity_tier> of <term_lower:glyph> rewards by %d%%.') % percentage_decrease
