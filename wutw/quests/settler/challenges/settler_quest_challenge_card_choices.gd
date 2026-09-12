class_name SettlerQuestChallenge_CardChoices
extends SettlerQuestChallenge

@export var decrease: int = 1

func apply_starting_modifiers(quest: Quest_Settler, run: Run) -> void:
	Utils.ensure(decrease > 0)
	run.get_vars().add_modifier(RunVars.Var.CARD_REWARD_CHOICES, -decrease, _get_mod_tag(quest))

func describe() -> String:
	return tr('Reduce the number of <term:glyph>s you can choose among when selecting a reward by %d.') % decrease
