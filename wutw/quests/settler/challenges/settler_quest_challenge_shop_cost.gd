class_name SettlerQuestChallenge_ShopCost
extends SettlerQuestChallenge

@export var percentage_increase: int = 25

func apply_starting_modifiers(quest: Quest_Settler, run: Run) -> void:
	Utils.ensure(percentage_increase > 0)
	run.get_vars().add_modifier(RunVars.Var.SHOP_PRICE_PERCENTAGE, percentage_increase, _get_mod_tag(quest))

func describe() -> String:
	return tr('Increase all <term_lower:shop> transaction costs by %d%%.') % percentage_increase
