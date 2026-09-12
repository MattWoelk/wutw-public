class_name SettlerQuestChallenge_ForayGoals
extends SettlerQuestChallenge

@export var percentage_increase: int = 10

func apply_starting_modifiers(quest: Quest_Settler, run: Run) -> void:
	Utils.ensure(percentage_increase > 0)
	run.get_vars().add_modifier(RunVars.Var.STAGE_REQUIREMENTS_PERCENTAGE, percentage_increase, _get_mod_tag(quest))

func describe() -> String:
	return tr('Increase all <term_lower:stage_goal>s by %d%%.') % percentage_increase
